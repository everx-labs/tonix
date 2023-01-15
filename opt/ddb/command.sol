pragma ton-solidity >= 0.64.0;
import "output.sol";
import "examine.sol";
struct db_command {
	bytes8 name;		// command name
	uint32 fcn;	        // function to call
	uint16 flag;
	uint8 more; // another level of command
//	uint32 next;             // LIST_ENTRY(db_command) next entry in the command table
//	uint32 mac_priv;		 // For MAC policy use
}

struct db_command_table {
    //db_command[] cmds;
    TvmCell[] cmds;
}

contract command is output, examine {

    uint8 constant ENXIO    = 6; // Device not configured
    uint8 constant EBUSY    = 16; // Device busy

    // Results of command search.
    uint8 constant CMD_UNIQUE =	0;
    uint8 constant CMD_FOUND =	1;
    uint8 constant CMD_NONE =	2;
    uint8 constant CMD_AMBIGUOUS =	3;
    uint8 constant CMD_HELP =	4;

    uint8 constant CS_OWN	= 0x1; // non-standard syntax
    uint8 constant CS_MORE	= 0x2; // standard syntax, but may have other words at end
    uint16 constant CS_SET_DOT =	0x100;	// set dot after command
    uint16 constant DB_CMD_MEMSAFE=0x1000;	// Command does not allow reads or writes to arbitrary memory.

    db_command db_last_command;
    bool db_cmd_loop_done;
    //uint32 db_dot;      	// current location
    //uint32 db_last_addr;	// last explicit address typed
    //uint32 db_prev;	        // last address examined or written
    //uint32 db_next;	        // next address to be examined or written

    //db_command[] db_cmd_table;
    db_command_table db_cmd_table;
    bool textdump_pending;
    uint32 db_stack_trace_active; // db_cmdfcn_t
    uint32 db_stack_trace_all; // db_cmdfcn_t

    TvmCell[] db_cmds;
//    db_command[] db_cmds;
//    db_command[] db_show_table;
//    db_command[] db_show_active_cmds = [DB_CMD("trace",		db_stack_trace_active,	DB_CMD_MEMSAFE)];
//    db_command[] db_show_active_table;// = LIST_HEAD_INITIALIZER(db_show_active_table);
//    db_command[] db_show_all_cmds = [DB_CMD("trace",		db_stack_trace_all,	DB_CMD_MEMSAFE)];
//    db_command[] db_show_all_table;// = LIST_HEAD_INITIALIZER(db_show_all_table);
//    db_command[] db_show_cmds;

    uint32 db_breakpoint_cmd;
    uint32 db_continue_cmd;
    uint32 db_delete_cmd;
    uint32 db_deletehwatch_cmd;
    uint32 db_deletewatch_cmd;
    uint32 db_examine_cmd;
    uint32 db_findstack_cmd;
    uint32 db_hwatchpoint_cmd;
    uint32 db_listbreak_cmd;
    uint32 db_scripts_cmd;
    uint32 db_print_cmd;
    uint32 db_ps;
    uint32 db_run_cmd;
    uint32 db_script_cmd;
    uint32 db_search_cmd;
    uint32 db_set_cmd;
    uint32 db_set_thread;
    uint32 db_show_regs;
    uint32 db_show_threads;
    uint32 db_single_step_cmd;
    uint32 db_textdump_cmd;
    uint32 db_trace_until_call_cmd;
    uint32 db_trace_until_matching_cmd;
    uint32 db_unscript_cmd;
    uint32 db_watchpoint_cmd;
    uint32 db_write_cmd;
    uint32 db_fncall;
    uint32 db_gdb;
    uint32 db_halt;
    uint32 db_kill;
    uint32 db_reset;
    uint32 db_stack_trace;
    uint32 db_watchdog;

    function db_skip_to_eol() internal {
    	byte t;
    	do {
    		t = db_read_token();
    	} while (t != tEOL);
    }

    function nitems(db_command_table t) internal pure returns (uint8) {
        return uint8(t.cmds.length);
    }
    function DB_CALL(uint32, uint32, uint32, uint32[]) internal {

    }

    function _DB_SET(string suffix, string name, uint32 func, uint32 , uint16 flag, uint8 more) internal pure returns (db_command) {
        return db_command(bytes8(name + suffix), func, flag, more);
    }
    function DB_CMD(string name, uint32 func, uint16 flags) internal pure returns (db_command) {
        return db_command(bytes8(name), func, flags, 0);
    }

    function DB_TABLE(string name, uint8 more) internal pure returns (db_command) {
        return db_command(bytes8(name), 0, 0, more);
    }
//typedef void db_cmdfcn_t(db_expr_t addr, bool have_addr, db_expr_t count, char *modif);

   function db_command_loop() internal {
    	// Initialize 'prev' and 'next' to dot.
    	db_prev = db_dot;
    	db_next = db_dot;

    	db_cmd_loop_done = false;
    	while (!db_cmd_loop_done) {
    		if (db_print_position() != 0)
    			db_printf("\n");
    		db_printf("db> ");
//    		if (db_read_line() > 0)
    		    _db_command(db_last_command, db_cmd_table, /* dopager */ true);
//            else
                break;
    	}
    }

    // Execute a command on behalf of a script.  The caller is responsible for making sure that the command string is < DB_MAXLINE or it will be truncated.
    // XXXRW: Runs by injecting faked input into DDB input stream; it would be nicer to use an alternative approach that didn't mess with the previous command buffer.
    function db_command_script(bytes cmd) internal {
    	db_prev = db_next = db_dot;
    	db_inject_line(cmd);
    	_db_command(db_last_command, db_cmd_table, /* dopager */ false);
    }

    function db_dump(uint8, bool, uint8, bytes) external accept {
    	uint8 error;
    	if (textdump_pending) {
    		db_printf("textdump_pending set.\nrun \"textdump unset\" first or \"textdump dump\" for a textdump.\n");
    		return;
    	}
//    	error = doadump(false);
    	if (error > 0) {
    		db_printf("Cannot dump: ");
    		if (error == EBUSY)
    			db_printf("debugger got invoked while dumping.\n");
    		else if (error == ENXIO)
    			db_printf("no dump device specified.\n");
            else
    			db_printf("unknown error (error=%d).\n", error);
    	}
    }

    using libcommand for db_command[];
    function init_cmds() internal view returns (db_command[][]) {
	    return [[
        DB_CMD("print",	    db_print_cmd,		    0),
	    DB_CMD("p",		    db_print_cmd,		    0),
	    DB_CMD("examine",	db_examine_cmd,		    CS_SET_DOT),
	    DB_CMD("x",		    db_examine_cmd,		    CS_SET_DOT),
	    DB_CMD("search",    db_search_cmd,		    CS_OWN|CS_SET_DOT),
	    DB_CMD("set",	    db_set_cmd,		        CS_OWN|DB_CMD_MEMSAFE),
	    DB_CMD("write",	    db_write_cmd,		    CS_MORE|CS_SET_DOT),
	    DB_CMD("w",		    db_write_cmd,		    CS_MORE|CS_SET_DOT)],
	    [DB_CMD("delete",    db_delete_cmd,		    DB_CMD_MEMSAFE),
	    DB_CMD("d",		    db_delete_cmd,		    DB_CMD_MEMSAFE),
	    DB_CMD("dump",	    tvm.functionId(command.db_dump),		DB_CMD_MEMSAFE),
	    DB_CMD("break",	    db_breakpoint_cmd,	    DB_CMD_MEMSAFE),
	    DB_CMD("b",		    db_breakpoint_cmd,	    DB_CMD_MEMSAFE),
	    DB_CMD("dwatch",    db_deletewatch_cmd,	    DB_CMD_MEMSAFE),
	    DB_CMD("watch",	    db_watchpoint_cmd,	    CS_MORE|DB_CMD_MEMSAFE),
	    DB_CMD("dhwatch",   db_deletehwatch_cmd,	DB_CMD_MEMSAFE)],

        [DB_CMD("hwatch",    db_hwatchpoint_cmd,	    DB_CMD_MEMSAFE),
	    DB_CMD("step",	    db_single_step_cmd,	    DB_CMD_MEMSAFE),
	    DB_CMD("s",		    db_single_step_cmd,	    DB_CMD_MEMSAFE),
	    DB_CMD("continue",	db_continue_cmd,	    DB_CMD_MEMSAFE),
	    DB_CMD("c",		    db_continue_cmd,	    DB_CMD_MEMSAFE),
	    DB_CMD("until",	    db_trace_until_call_cmd, DB_CMD_MEMSAFE),
	    DB_CMD("next",	    db_trace_until_matching_cmd, DB_CMD_MEMSAFE),
	    DB_CMD("match",	    db_trace_until_matching_cmd, 0)],

	    [DB_CMD("trace",	    db_stack_trace,		    CS_OWN|DB_CMD_MEMSAFE),
	    DB_CMD("t",		    db_stack_trace,		    CS_OWN|DB_CMD_MEMSAFE),
	    DB_CMD("acttrace",	db_stack_trace_active,	DB_CMD_MEMSAFE), // alias for active trace
	    DB_CMD("alltrace",	db_stack_trace_all,	    DB_CMD_MEMSAFE), // alias for all trace
	    DB_CMD("where",	    db_stack_trace,		    CS_OWN|DB_CMD_MEMSAFE),
	    DB_CMD("bt",	    db_stack_trace,		    CS_OWN|DB_CMD_MEMSAFE),
	    DB_CMD("call",	    db_fncall,		        CS_OWN),
	    DB_CMD("ps",	    db_ps,			        DB_CMD_MEMSAFE)],

	    [DB_CMD("gdb",	    db_gdb,			        0),
	    DB_CMD("halt",	    db_halt,		        DB_CMD_MEMSAFE),
	    DB_CMD("reboot",    db_reset,		        DB_CMD_MEMSAFE),
	    DB_CMD("reset",	    db_reset,		        DB_CMD_MEMSAFE),
	    DB_CMD("kill",	    db_kill,		        CS_OWN|DB_CMD_MEMSAFE),
	    DB_CMD("watchdog",	db_watchdog,		    CS_OWN|DB_CMD_MEMSAFE),
	    DB_CMD("thread",	db_set_thread,		    0),
	    DB_CMD("run",		db_run_cmd,		        CS_OWN|DB_CMD_MEMSAFE)],

        [DB_CMD("script",	db_script_cmd,		    CS_OWN|DB_CMD_MEMSAFE),
	    DB_CMD("scripts",	db_scripts_cmd,		    DB_CMD_MEMSAFE),
	    DB_CMD("unscript",	db_unscript_cmd,	    CS_OWN|DB_CMD_MEMSAFE),
	    DB_CMD("capture",	tvm.functionId(capture.db_capture_cmd),		CS_OWN|DB_CMD_MEMSAFE),
	    DB_CMD("textdump",	db_textdump_cmd,	CS_OWN|DB_CMD_MEMSAFE),
	    DB_CMD("findstack",	db_findstack_cmd,	0)]];
    }
//    function init_show_cmds() internal {
//        db_show_table = [
////    	    DB_TABLE("active",	db_show_active_table),
////    	    DB_TABLE("all",		db_show_all_table),
//    	    DB_CMD("registers",	db_show_regs,		DB_CMD_MEMSAFE),
//    	    DB_CMD("breaks",	db_listbreak_cmd,	DB_CMD_MEMSAFE),
//    	    DB_CMD("threads",	db_show_threads,	DB_CMD_MEMSAFE)];
//    }
//    function init_show_active_cmds() internal {}
//    function init_show_all_cmds() internal {}

//    function db_command_register(db_command_table list, db_command cmd) internal {
//        list.
//    }

    function db_command_init() internal {
//        db_command[] db_cmds = init_cmds();
        db_command[] cmds = [
            DB_CMD("print",	    db_print_cmd,		    0),
	        DB_CMD("p",		    db_print_cmd,		    0),
	        DB_CMD("examine",	db_examine_cmd,		    CS_SET_DOT),
	        DB_CMD("x",		    db_examine_cmd,		    CS_SET_DOT),
	        DB_CMD("search",    db_search_cmd,		    CS_OWN|CS_SET_DOT),
	        DB_CMD("set",	    db_set_cmd,		        CS_OWN|DB_CMD_MEMSAFE),
	        DB_CMD("write",	    db_write_cmd,		    CS_MORE|CS_SET_DOT),
	        DB_CMD("w",		    db_write_cmd,		    CS_MORE|CS_SET_DOT)];
        TvmBuilder b;
    	for (uint8 i = 0; i < cmds.length; i++) {
            if (b.remBits() > 120)
                b.store(cmds[i]);
            else
                break;
        }
        TvmCell c = b.toCell();
        db_cmds.push(c);
        db_cmd_table.cmds.push(c);
//        db_cmd_table.cmds.push(i);

            //db_command_register(db_cmds[i]);
//            cmds.push(i);
//        db_cmd_table.cmds = cmds;
//        init_show_cmds();
//    	for (uint i = 0; i < nitems(db_show_cmds); i++)
//            db_show_table.db_command_register(db_show_cmds[i]);
//        init_show_active_cmds();
//    	for (uint i = 0; i < nitems(db_show_active_cmds); i++)
//            db_show_active_table.db_command_register(db_show_active_cmds[i]);
//        init_show_all_cmds();
//    	for (uint i = 0; i < nitems(db_show_all_cmds); i++)
//            db_show_all_table.db_command_register(db_show_all_cmds[i]);
    }


    // Helper function to match a single command.
    function db_cmd_match(bytes name, db_command cmd) internal pure returns (db_command cmdp, uint8 resultp) {
    	uint8 lp;
        uint8 rp;
    	byte c;
    	while ((c = name[lp]) == cmd.name[rp]) {
    		if (c == 0) {
    			// complete match
    			return (cmd, CMD_UNIQUE);
    		}
    		lp++;
    		rp++;
    	}
    	if (c == 0) {
    		// end of name, not end of command - partial match
    		if (resultp == CMD_FOUND) {
    			resultp = CMD_AMBIGUOUS;
    			// but keep looking for a full match - this lets us match single letters
    		} else if (resultp == CMD_NONE) {
    			cmdp = cmd;
    			resultp = CMD_FOUND;
    		}
    	}
    }

    function LIST_FOREACH(db_command_table table) internal pure returns (db_command[] cmds) {
        for (TvmCell c: table.cmds) {
            TvmSlice s = c.toSlice();
            while (s.hasNBits(120))
                cmds.push(s.decode(db_command));
        }
    }
    // Search for command prefix.
    function db_cmd_search(string name, db_command_table table) internal pure returns (uint8 result, db_command cmdp) {
    	result = CMD_NONE;
//        for (db_command cmd: table) {
//    	LIST_FOREACH(cmd, table, next) {
        db_command[] cmds = LIST_FOREACH(table);
        for (db_command cmd: cmds) {
    		(cmdp, result) = db_cmd_match(name, cmd);
    		if (result == CMD_UNIQUE)
    			break;
    	}
    	if (result == CMD_NONE) {
    		// check for 'help'
            if (name.substr(0, 4) == "help")
    			result = CMD_HELP;
    	}
    }

    function db_cmd_list(db_command_table table) internal {
    	uint8 have_subcommands;
//        for (uint8 i: table.cmds) {
//    	LIST_FOREACH(cmd, table, next) {
        db_command[] cmds = LIST_FOREACH(table);
        for (db_command cmd: cmds) {
    		if (cmd.more != NULL)
    			have_subcommands++;
    		//db_printf("%-16s", cmd.name);
            db_printf("%s\n", cmd.name);
    		db_end_line(16);
    	}
    	if (have_subcommands > 0) {
    		db_printf("\nThe following have subcommands; append \"help\" to list (e.g. \"show help\"):\n");
//    		LIST_FOREACH(cmd, table, next) {
            //for (db_command cmd: table) {
            //for (uint8 i: table.cmds) {
//                cmd = db_cmds[i].toSlice().decode(db_command);
            for (db_command cmd: cmds) {
    			if (cmd.more == NULL)
    				continue;
    			//db_printf("%-16s", cmd.name);
                db_printf("%s\n", cmd.name);
    			db_end_line(16);
    		}
    	}
    }
    function _db_command(db_command last_cmdp, db_command_table cmd_table, bool dopager) internal {
    	//char modif[TOK_STRING_SIZE];
        bytes modif;
    	db_command cmd;
    	uint32 addr;
        uint32 count;
        uint8 result;
    	bool have_addr = false;
    	byte t = db_read_token();
    	if (t == tEOL) {
    		// empty line repeats last command, at 'next'
    		cmd = last_cmdp;
    		addr = db_next;
    		have_addr = false;
    		count = 1;
    		modif = bytes(t0);
    	} else if (t == tEXCL) {
//    		db_fncall(0, false, 0, NULL);
    		return;
    	} else if (t != tIDENT) {
    		db_printf("Unrecognized input; use \"help\" to list available commands\n");
    		db_flush_lex();
    		return;
    	} else {
    		// Search for command
    		//while (!cmd_table.cmds.empty()) {
    			(result, cmd) = db_cmd_search(db_tok_string, cmd_table);
    			if (result == CMD_NONE) {
    				db_printf("No such command; use \"help\" to list available commands\n");
    				db_flush_lex();
    				return;
                } else if (result == CMD_AMBIGUOUS) {
    				db_printf("Ambiguous\n");
    				db_flush_lex();
    				return;
    			} else if (result == CMD_HELP) {
//    				if (cmd_table == db_cmd_table) {
    					db_printf("This is ddb(4), the kernel debugger; see https://man.FreeBSD.org/ddb/4 for help.\n");
    					db_printf("Use \"bt\" for backtrace, \"dump\" for kernel core dump, \"reset\" to reboot.\n");
    					db_printf("Available commands:\n");
//    				}
    				db_cmd_list(db_cmd_table);
    				db_flush_lex();
    				return;
    			} else if (result == CMD_UNIQUE || result == CMD_FOUND) {}
//    				break;
    			/*if ((cmd_table = cmd.more) != NULL) {
    				t = db_read_token();
    				if (t != tIDENT) {
    					db_printf("Subcommand required; available subcommands:\n");
    					db_cmd_list(cmd_table);
    					db_flush_lex();
    					return;
    				}
    			}*/
//    		}
    		if ((cmd.flag & CS_OWN) == 0) {
    			// Standard syntax: command [/modifier] [addr] [,count]
    			t = db_read_token();
    			if (t == tSLASH) {
    				t = db_read_token();
    				if (t != tIDENT) {
    					db_printf("Bad modifier\n");
    					db_flush_lex();
    					return;
    				}
//    				db_strcpy(modif, db_tok_string);
                    modif = db_tok_string;
    			} else {
    				db_unread_token(t);
    				modif = bytes(t0);
    			}
//    			if (db_expression(addr)) {
//    				db_dot = addr;
//    				db_last_addr = db_dot;
//    				have_addr = true;
//    			} else {
    				addr = db_dot;
    				have_addr = false;
//    			}
    			t = db_read_token();
    			if (t == tCOMMA) {
//    				if (!db_expression(count)) {
//    					db_printf("Count missing\n");
//    					db_flush_lex();
//    					return;
//    				}
    			} else {
    				db_unread_token(t);
    				count = 0;
    			}
    			if ((cmd.flag & CS_MORE) == 0)
    				db_skip_to_eol();
    		}
    	}
    	last_cmdp = cmd;
    	if (cmd.fcn != NULL) {
    		// Execute the command.
    		if (dopager)
    			db_enable_pager();
    		else
    			db_disable_pager();
//    		(cmd.fcn)(addr, have_addr, count, modif);
    		if (dopager)
    			db_disable_pager();
        	if ((cmd.flag & CS_SET_DOT) > 0) {
    			// If command changes dot, set dot to previous address displayed (if 'ed' style).
    			db_dot = db_ed_style ? db_prev : db_next;
    		} else {
    			// If command does not change dot, set 'next' location to be the same.
    			db_next = db_dot;
    		}
    	}
    }

}

library libcommand {

    function db_command_register(db_command[] list, db_command cmd) internal {
        db_command last;
        for (db_command c: list) {
//    		uint8 n = strcmp(cmd.name, c.name);
    		uint8 n = cmd.name == c.name ? 0 : 1;
    		// Check that the command is not already present
    		if (n == 0) {
    //			printf("%s: Warning, the command \"%s\" already exists; ignoring request\n", __func__, cmd.name);
    			return;
    		}
    		if (n < 0) {
    			// NB: keep list sorted lexicographically
                list.push(cmd);
    //			LIST_INSERT_BEFORE(c, cmd, next);
    			return;
    		}
    		last = c;
    	}
        list.push(cmd);
    }

    // Remove a command previously registered with db_command_register.
    function db_command_unregister(db_command[] list, db_command cmd) internal {
        for (db_command c: list) {
//    	LIST_FOREACH(c, list, next) {
    		if (cmd.name == c.name) {
                delete cmd;
//    			LIST_REMOVE(cmd, next);
    			return;
    		}
    	}
    	/* NB: intentionally quiet */
    }

}