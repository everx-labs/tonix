
contract watch {
    bool		db_watchpoints_inserted = true;
    //#define	NWATCHPOINTS	100
    db_watchpoint	db_watch_table[NWATCHPOINTS];
    db_watchpoint_t	db_next_free_watchpoint = &db_watch_table[0];
    db_watchpoint_t	db_free_watchpoints = 0;
    db_watchpoint_t	db_watchpoint_list = 0;

    function db_watchpoint_alloc() internal returns (db_watchpoint) {
    	db_watchpoint_t	watch;
    	if ((watch = db_free_watchpoints) != 0) {
    	    db_free_watchpoints = watch.link;
    	    return (watch);
    	}
    	if (db_next_free_watchpoint == &db_watch_table[NWATCHPOINTS]) {
    	    db_printf("All watchpoints used.\n");
    	    return (0);
    	}
    	watch = db_next_free_watchpoint;
    	db_next_free_watchpoint++;
    	return (watch);
    }

    function db_watchpoint_free(db_watchpoint_t watch) internal {
    	watch.link = db_free_watchpoints;
    	db_free_watchpoints = watch;
    }

    function db_set_watchpoint(vm_map_t map, db_addr_t addr, vm_size_t size) internal {
    	db_watchpoint_t	watch;
    	if (map == NULL) {
    	    db_printf("No map.\n");
    	    return;
    	}
    	//	Should we do anything fancy with overlapping regions?
    	for (watch = db_watchpoint_list; watch != 0; watch = watch.link)
    	    if (db_map_equal(watch.map, map) && (watch.loaddr == addr) && (watch.hiaddr == addr + size)) {
        		db_printf("Already set.\n");
        		return;
    	    }
    	watch = db_watchpoint_alloc();
    	if (watch == 0) {
    	    db_printf("Too many watchpoints.\n");
    	    return;
    	}
    	watch.map = map;
    	watch.loaddr = addr;
    	watch.hiaddr = addr+size;
    	watch.link = db_watchpoint_list;
    	db_watchpoint_list = watch;
    	db_watchpoints_inserted = false;
    }

    function db_delete_watchpoint(vm_map_t map, db_addr_t addr) internal {
    	db_watchpoint_t	watch;
    	db_watchpoint_t	*prev;
    	for (prev = &db_watchpoint_list; (watch = *prev) != 0; prev = watch.link)
            if (db_map_equal(watch.map, map) && (watch.loaddr <= addr) && (addr < watch.hiaddr)) {
        		*prev = watch.link;
        		db_watchpoint_free(watch);
    		    return;
    	    }
    	db_printf("Not set.\n");
    }

    function db_list_watchpoints(void) internal {
    	db_watchpoint_t	watch;
    	if (db_watchpoint_list == 0) {
    	    db_printf("No watchpoints set\n");
    	    return;
    	}
    	db_printf(" Map        Address  Size\n");
    	for (watch = db_watchpoint_list; watch != 0; watch = watch.link)
    	    db_printf("%s%8p  %8lx  %lx\n", db_map_current(watch.map) ? "*" : " ", watch.map,
                watch.loaddr, watch.hiaddr - watch.loaddr);
    }

    /* Delete watchpoint */
    /*ARGSUSED*/
    function db_deletewatch_cmd(db_expr_t addr, bool have_addr, db_expr_t count, char *modif) internal {
    	db_delete_watchpoint(db_map_addr(addr), addr);
    }

    /* Set watchpoint */
    /*ARGSUSED*/
    function db_watchpoint_cmd(db_expr_t addr, bool have_addr, db_expr_t count, char *modif) internal {
    	vm_size_t	size;
    	db_expr_t	value;
    	if (db_expression(&value))
    	    size = (vm_size_t) value;
    	else
    	    size = 4;
    	db_skip_to_eol();
    	db_set_watchpoint(db_map_addr(addr), addr, size);
    }

    // At least one non-optional show-command must be implemented using DB_SHOW_COMMAND() so that db_show_cmd_set gets created.  Here is one.
    function DB_SHOW_COMMAND_FLAGS(watches, db_listwatch_cmd, DB_CMD_MEMSAFE) internal {
    	db_list_watchpoints();
    	db_md_list_watchpoints();
    }

    function db_set_watchpoints() internal {
    	db_watchpoint_t	watch;
    	if (!db_watchpoints_inserted) {
    	    for (watch = db_watchpoint_list; watch != 0; watch = watch.link)
    		pmap_protect(watch.map.pmap, trunc_page(watch.loaddr), round_page(watch.hiaddr), VM_PROT_READ);
    	    db_watchpoints_inserted = true;
    	}
    }

    function db_clear_watchpoints(void) internal {
    	db_watchpoints_inserted = false;
    }

    #ifdef notused
    function db_find_watchpoint(vm_map_t map, db_addr_t addr, db_regs_t regs) internal returns (bool) {
    	db_watchpoint_t found = 0;
    	for (db_watchpoint_t watch = db_watchpoint_list; watch != 0; watch = watch.link)
    	    if (db_map_equal(watch.map, map)) {
    		if ((watch.loaddr <= addr) &&
    		    (addr < watch.hiaddr))
    		    return (true);
    		else if ((trunc_page(watch.loaddr) <= addr) &&
    			 (addr < round_page(watch.hiaddr)))
    		    found = watch;
    	    }
   	    // We didn't hit exactly on a watchpoint, but we are	in a protected region.  We want to single-step	and then re-protect.
    	if (found) {
    	    db_watchpoints_inserted = false;
    	    db_single_step(regs);
    	}
    	return (false);
    }
    #endif

    /* Delete hardware watchpoint */
    function db_deletehwatch_cmd(db_expr_t addr, bool have_addr, db_expr_t size, char *modif) internal {
    	if (size < 0)
    		size = 4;
    	uint8 rc = kdb_cpu_clr_watchpoint((vm_offset_t)addr, (vm_size_t)size);
    	if (rc == ENXIO) {
    		/* Not supported, ignored. */
        } else if (rc == EINVAL)
    		db_printf("Invalid watchpoint address or size.\n");
        else {
    		if (rc != 0)
    			db_printf("Hardware watchpoint could not be deleted, status=%d\n", rc);
    	}
    }

    /* Set hardware watchpoint */
    function db_hwatchpoint_cmd(db_expr_t addr, bool have_addr, db_expr_t size, char *modif) internal {
    	if (size < 0)
    		size = 4;
    	uint8 rc = kdb_cpu_set_watchpoint(addr, size, KDB_DBG_ACCESS_W);
    	if (rc == EINVAL)
    		db_printf("Invalid watchpoint size or address.\n");
    	else if (rc == EBUSY)
    		db_printf("No hardware watchpoints available.\n");
    	else if (rc == ENXIO)
    		db_printf("Hardware watchpoints are not supported on this platform.\n");
    		break;
        else {
    		if (rc != 0)
    			db_printf("Could not set hardware watchpoint, status=%d\n", rc);
    	}
    }
}