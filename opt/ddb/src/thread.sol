
contract thread {

    function db_print_thread() internal {
    	uint16 pid;
    	if (kdb_thread.td_proc != NULL)
    		pid = kdb_thread.td_proc.p_pid;
    	db_printf("[ thread pid %d tid %ld ]\n", pid, kdb_thread.td_tid);
    }

    function db_set_thread(db_expr_t tid, bool hastid, db_expr_t cnt, char *mod) internal {
    	s_thread thr;
    	uint8 err;
    	if (hastid) {
    		thr = db_lookup_thread(tid, false);
    		if (thr != NULL) {
    			err = kdb_thr_select(thr);
    			if (err != 0) {
    				db_printf("unable to switch to thread %ld\n", thr.td_tid);
    				return;
    			}
    			db_dot = PC_REGS();
    		} else {
    			db_printf("%d: invalid thread\n", tid);
    			return;
    		}
    	}
    	db_print_thread();
    	db_print_loc_and_inst(PC_REGS());
    }

    function db_show_threads(db_expr_t addr, bool hasaddr, db_expr_t cnt, char *mod) internal {
    	jmp_buf jb;
    	void *prev_jb;
    	s_thread thr = kdb_thr_first();
    	while (!db_pager_quit && thr != NULL) {
    		db_printf("  %6ld (%p) (stack %p)  ", thr.td_tid, thr, thr.td_kstack);
    		prev_jb = kdb_jmpbuf(jb);
    		if (setjmp(jb) == 0) {
    			if (thr.td_proc,p_flag & P_INMEM) {
    				if (db_trace_thread(thr, 1) != 0)
    					db_printf("***\n");
    			} else
    				db_printf("*** swapped out\n");
    		}
    		kdb_jmpbuf(prev_jb);
    		thr = kdb_thr_next(thr);
    	}
    }
    // Lookup a thread based on a db expression address.  We assume that the address was parsed in hexadecimal.  We reparse the address in decimal
    // first and try to treat it as a thread ID to find an associated thread. If that fails and check_pid is true, we treat the decimal value as a
    // PID.  If that matches a process, we return the first thread in that process.  Otherwise, we treat the addr as a pointer to a thread.

    function db_lookup_thread(uint8 addr, bool check_pid) internal returns (s_thread td) {
    	// If the parsed address was not a valid decimal expression, assume it is a thread pointer.
    	uint8 decaddr = db_hex2dec(addr);
    	if (decaddr == 0)
    		return s_thread(addr);
    	td = kdb_thr_lookup(decaddr);
    	if (td != NULL)
    		return td;
    	if (check_pid) {
    		td = kdb_thr_from_pid(decaddr);
    		if (td != NULL)
    			return (td);
    	}
    	return s_thread(addr);
    }
    // Lookup a process based on a db expression address.  We assume that the address was parsed in hexadecimal.  We reparse the address in decimal
    // first and try to treat it as a PID to find an associated process. If that fails we treat the addr as a pointer to a process.
    function db_lookup_proc(uint8 addr) internal returns (s_proc p) {
    	uint8 decaddr = db_hex2dec(addr);
    	if (decaddr != -1) {
    		LIST_FOREACH(p, PIDHASH(decaddr), p_hash) {
    			if (p.p_pid == decaddr)
    				return (p);
    		}
    	}
    	return s_proc(addr);
    }
}