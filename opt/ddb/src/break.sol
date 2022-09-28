
contract breakpoint {
    //#define	NBREAKPOINTS	100
    db_breakpoint[NBREAKPOINTS]	db_break_table;
    db_breakpoint_t		db_next_free_breakpoint = &db_break_table[0];
    db_breakpoint_t		db_free_breakpoints = 0;
    db_breakpoint_t		db_breakpoint_list = 0;

    function db_breakpoint_alloc() internal returns (db_breakpoint_t) {
    	db_breakpoint_t	bkpt;
    	if ((bkpt = db_free_breakpoints) != 0) {
    	    db_free_breakpoints = bkpt.link;
    	    return (bkpt);
    	}
    	if (db_next_free_breakpoint == &db_break_table[NBREAKPOINTS]) {
    	    db_printf("All breakpoints used.\n");
    	    return 0;
    	}
    	bkpt = db_next_free_breakpoint;
    	db_next_free_breakpoint++;
    	return bkpt;
    }

    function db_breakpoint_free(db_breakpoint_t bkpt) internal {
    	bkpt.link = db_free_breakpoints;
    	db_free_breakpoints = bkpt;
    }

    function db_set_breakpoint(vm_map_t map, db_addr_t addr, int count) internal {
    	db_breakpoint_t	bkpt;
    	if (db_find_breakpoint(map, addr)) {
    	    db_printf("Already set.\n");
    	    return;
    	}
    	bkpt = db_breakpoint_alloc();
    	if (bkpt == 0) {
    	    db_printf("Too many breakpoints.\n");
    	    return;
    	}
    	bkpt.map = map;
    	bkpt.address = addr;
    	bkpt.flags = 0;
    	bkpt.init_count = count;
    	bkpt.count = count;

    	bkpt.link = db_breakpoint_list;
    	db_breakpoint_list = bkpt;
    }

    function db_delete_breakpoint(vm_map_t map, db_addr_t addr) internal {
    	db_breakpoint_t	bkpt;
    	db_breakpoint_t	prev;
    	for (prev = &db_breakpoint_list; (bkpt = *prev) != 0; prev = &bkpt.link) {
    	    if (db_map_equal(bkpt.map, map) && (bkpt.address == addr)) {
        		*prev = bkpt.link;
        		break;
    	    }
    	}
    	if (bkpt == 0) {
    	    db_printf("Not set.\n");
    	    return;
    	}
    	db_breakpoint_free(bkpt);
    }

    function db_find_breakpoint(vm_map_t map, db_addr_t addr) internal returns (db_breakpoint_t) {
    	for (db_breakpoint_t bkpt = db_breakpoint_list; bkpt != 0; bkpt = bkpt.link) {
    	    if (db_map_equal(bkpt.map, map) && (bkpt.address == addr))
    		    return bkpt;
    	}
    }

    function db_find_breakpoint_here(db_addr_t addr) internal returns (db_breakpoint_t) {
    	return db_find_breakpoint(db_map_addr(addr), addr);
    }

    bool	db_breakpoints_inserted = true;

    BKPT_WRITE(addr, storage)
    	*storage = db_get_value(addr, BKPT_SIZE, false);
    	db_put_value(addr, BKPT_SIZE, BKPT_SET(*storage));

    BKPT_CLEAR(addr, storage)
    	db_put_value(addr, BKPT_SIZE, *storage)

    function db_set_breakpoints() internal {
    	if (!db_breakpoints_inserted) {
    		for (db_breakpoint_t bkpt = db_breakpoint_list; bkpt != 0; bkpt = bkpt.link)
    			if (db_map_current(bkpt.map)) {
    				BKPT_WRITE(bkpt.address, &bkpt.bkpt_inst);
    			}
    		db_breakpoints_inserted = true;
    	}
    }

    function db_clear_breakpoints() internal {
    	if (db_breakpoints_inserted) {
    		for (db_breakpoint_t bkpt = db_breakpoint_list; bkpt != 0; bkpt = bkpt.link)
    			if (db_map_current(bkpt.map)) {
    				BKPT_CLEAR(bkpt.address, &bkpt.bkpt_inst);
    			}
    		db_breakpoints_inserted = false;
    	}
    }

    // List breakpoints.
    function db_list_breakpoints() internal {
    	if (db_breakpoint_list == 0) {
    	    db_printf("No breakpoints set\n");
    	    return;
    	}
    	db_printf(" Map      Count    Address\n");
    	for (db_breakpoint_t bkpt = db_breakpoint_list; bkpt != 0; bkpt = bkpt.link) {
    	    db_printf("%s%8p %5d    ", db_map_current(bkpt.map) ? "*" : " ", (void *)bkpt.map, bkpt.init_count);
    	    db_printsym(bkpt.address, DB_STGY_PROC);
    	    db_printf("\n");
    	}
    }

    // Delete breakpoint
    function db_delete_cmd(db_expr_t addr, bool have_addr, db_expr_t count, char *modif) internal {
    	db_delete_breakpoint(db_map_addr(addr), (db_addr_t)addr);
    }

    // Set breakpoint with skip count
    function db_breakpoint_cmd(db_expr_t addr, bool have_addr, db_expr_t count, char *modif) internal {
    	if (count == -1)
    	    count = 1;
    	db_set_breakpoint(db_map_addr(addr), (db_addr_t)addr, count);
    }

    // list breakpoints
    function db_listbreak_cmd(uint8, bool, uint8, byte) internal {
    	db_list_breakpoints();
    }

    //	We want ddb to be usable before most of the kernel has been	initialized.  In particular, current_thread() or kernel_map	(or both) may be null.
    function db_map_equal(vm_map_t map1, vm_map_t map2) internal returns (bool) {
    	return ((map1 == map2) || ((map1 == NULL) && (map2 == kernel_map)) || ((map1 == kernel_map) && (map2 == NULL)));
    }

    function db_map_current(vm_map_t map) internal returns (bool) {
    	return true;
    }

    function db_map_addr(vm_offset_t addr) internal returns () {
    	    return kernel_map;
    }
}