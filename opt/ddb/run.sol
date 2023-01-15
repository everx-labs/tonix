pragma ton-solidity >= 0.64.0;

contract run {
    uint8 constant STEP_ONCE =	1;
    uint8 constant STEP_RETURN =	2;
    uint8 constant STEP_CALLT =	3;
    uint8 constant STEP_CONTINUE =	4;
    uint8 constant STEP_INVISIBLE =	5;
    uint8 constant STEP_COUNT =	6;

    uint8	db_run_mode = STEP_CONTINUE;

    bool	db_sstep_multiple;
    bool	db_sstep_print;
    uint8	db_loop_count;
    uint8	db_call_depth;

    uint16	db_inst_count;
    uint16	db_load_count;
    uint16	db_store_count;

    function db_stop_at_pc(uint8 ctype, uint8 code) internal returns (bool is_breakpoint, bool is_watchpoint) {
    	uint8 pc;
    	db_breakpoint_t bkpt;
    	is_breakpoint = IS_BREAKPOINT_TRAP(ctype, code);
    	is_watchpoint = IS_WATCHPOINT_TRAP(ctype, code);
    	//pc = PC_REGS();
    	db_clear_single_step();
    	db_clear_breakpoints();
    	db_clear_watchpoints();
    	// Now check for a breakpoint at this address.
    	bkpt = db_find_breakpoint_here(pc);
    	if (bkpt) {
    	    if (--bkpt.count == 0) {
    		    bkpt.count = bkpt.init_count;
    		    is_breakpoint = true;
    		    return true;	// stop here
    	    }
    	    return false;	// continue the countdown
    	} else if (is_breakpoint) {
    	}
    	is_breakpoint = false;	/* might be a breakpoint, but not ours */
    	// If not stepping, then silently ignore single-step traps (except for clearing the single-step-flag above).
    	// If stepping, then abort if the trap type is unexpected. Breakpoints owned by us are expected and were handled above.
    	// Single-steps are expected and are handled below.  All others are unexpected.
    	// Only do either of these if the MD layer claims to classify  single-step traps unambiguously (by defining IS_SSTEP_TRAP).
    	// Otherwise, fall through to the bad historical behaviour given by turning unexpected traps into expected traps: if not
    	// stepping, then expect only breakpoints and stop, and if stepping, then expect only single-steps and step.
    	if (db_run_mode == STEP_INVISIBLE) {
    	    db_run_mode = STEP_CONTINUE;
    	    return false;	// continue
    	}
    	if (db_run_mode == STEP_COUNT) {
    	    return false; // continue
    	}
    	if (db_run_mode == STEP_ONCE) {
    	    if (--db_loop_count > 0) {
    		    if (db_sstep_print) {
    		        db_printf("\t\t");
    		        db_print_loc_and_inst(pc);
    		    }
    		    return false;	// continue
    	    }
    	}
    	if (db_run_mode == STEP_RETURN) {
    	    // continue until matching return
    	    uint8 ins = db_get_value(pc, 4, false);
    	    if (!inst_trap_return(ins) && (!inst_return(ins) || --db_call_depth != 0)) {
    		if (db_sstep_print) {
    		    if (inst_call(ins) || inst_return(ins)) {
    			    int i;
    			    db_printf("[after %6d]     ", db_inst_count);
    			    for (i = db_call_depth; --i > 0; )
    			        db_printf("  ");
    			    db_print_loc_and_inst(pc);
    		    }
    		}
    		if (inst_call(ins))
    		    db_call_depth++;
    		return false;	// continue
    	    }
    	}
    	if (db_run_mode == STEP_CALLT) {
    	    // continue until call or return
    	    uint8 ins = db_get_value(pc, 4, false);
    	    if (!inst_call(ins) && !inst_return(ins) && !inst_trap_return(ins)) {
    		    return false;	// continue
    	    }
    	}
    	return true;
    }

    function db_restart_at_pc(bool watchpt) internal {
    	uint8 pc;// = PC_REGS();
    	if ((db_run_mode == STEP_COUNT) || ((db_run_mode == STEP_ONCE) && db_sstep_multiple) || (db_run_mode == STEP_RETURN) || (db_run_mode == STEP_CALLT)) {
    	    // We are about to execute this instruction, so count it now.
    	    db_get_value(pc, 4, false);
    	    db_inst_count++;
    	    db_load_count += inst_load(ins);
    	    db_store_count += inst_store(ins);
    	}
    	if (db_run_mode == STEP_CONTINUE) {
    	    if (watchpt || db_find_breakpoint_here(pc)) {
    		    // Step over breakpoint/watchpoint.
    		    db_run_mode = STEP_INVISIBLE;
    		    db_set_single_step();
    	    } else {
    		    db_set_breakpoints();
    		    db_set_watchpoints();
    	    }
    	} else {
    	    db_set_single_step();
    	}
    }

    function db_single_step_cmd(uint8 addr, bool have_addr, uint8 count, bytes modif) internal {
    	bool print = false;
    	if (count == -1)
    	    count = 1;
    	if (modif[0] == 'p')
    	    print = true;
    	db_run_mode = STEP_ONCE;
    	db_loop_count = count;
    	db_sstep_multiple = (count != 1);
    	db_sstep_print = print;
    	db_inst_count = 0;
    	db_load_count = 0;
    	db_store_count = 0;
    	db_cmd_loop_done = 1;
    }

    function db_trace_until_call_cmd(uint8 addr, bool have_addr, uint8 count, bytes modif) internal {
    	bool print = false;
    	if (modif[0] == 'p')
    	    print = true;
    	db_run_mode = STEP_CALLT;
    	db_sstep_print = print;
    	db_inst_count = 0;
    	db_load_count = 0;
    	db_store_count = 0;
    	db_cmd_loop_done = 1;
    }

    function db_trace_until_matching_cmd(uint8 addr, bool have_addr, uint8 count, bytes modif) internal {
    	bool print = false;
    	if (modif[0] == 'p')
    	    print = true;
    	db_run_mode = STEP_RETURN;
    	db_call_depth = 1;
    	db_sstep_print = print;
    	db_inst_count = 0;
    	db_load_count = 0;
    	db_store_count = 0;
    	db_cmd_loop_done = 1;
    }

    function db_continue_cmd(uint8 addr, bool have_addr, uint8 count, bytes modif) internal {
    	if (modif[0] == 'c')
    	    db_run_mode = STEP_COUNT;
    	else
    	    db_run_mode = STEP_CONTINUE;
    	db_inst_count = 0;
    	db_load_count = 0;
    	db_store_count = 0;
    	db_cmd_loop_done = 1;
    }
}