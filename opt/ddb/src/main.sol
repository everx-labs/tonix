pragma ton-solidity >= 0.64.0;

import "command.sol";
struct db_symtab {
	string name;		// symtab name
	uint32 start;		// symtab location
	uint32 end;
    db_private _private;// optional machdep pointer
}

struct db_private {
	uint32 strtab;
	uint32 relbase;
}

struct ddb_script {
	string ds_scriptname; //[DB_MAXSCRIPTNAME];
	string ds_script; //[DB_MAXSCRIPTLEN];
}

struct db_watchpoint {
	uint32 map;			// in this map
	uint32 loaddr;		// from this address
	uint32 hiaddr;		// to this address
	uint32 link;	    // db_watchpoint; link in in-use or free chain
}

struct db_breakpoint {
	uint32 map;			// vm_map_t in this map
	uint32 addr;		    // set here
	uint8 init_count;		// number of times to skip bkpt
	uint8 count;			// current count
	uint8 flags;			// flags:
	uint8 bkpt_inst;        // BKPT_INST_TYPE' saved instruction at bkpt
	uint32 link;        	// link in in-use or free chain
}
	// Infer or use db_radix using the old logic. The following set an explicit base for tNUMBER lex.

// interactive	kernel debugger
contract main is command {
    uint8 constant DB_MAXSCRIPTS	= 8;
    uint8 constant DB_MAXSCRIPTNAME	= 32;
    uint8 constant DB_MAXSCRIPTLEN	= 128;
    uint8 constant DB_MAXSCRIPTRECURSION	= 3;

    uint8 constant BKPT_SINGLE_STEP	= 0x2;	    // to simulate single step
    uint8 constant BKPT_TEMP		= 0x4;	    // temporary

    uint8 constant MAXNOSYMTABS = 1;
//    uint32 _db_dot;		    // current location
//    uint32 _db_last_addr;	// last explicit address typed
//    uint32 _db_prev;	    // last address examined or written
//    uint32 _db_next;	    // next address to be examined

    uint8 db_maxoff;
    uint16 db_inst_count;
    uint16 db_load_count;
    uint16 db_store_count;

    db_symtab ksymtab;
    db_symtab kstrtab;
    uint32 ksymtab_size;
    uint32 ksymtab_relbase;
    db_private ksymtab_private;
    uint8 db_nsymtab;
    db_symtab[MAXNOSYMTABS] db_symtabs;

    function db_stop_at_pc(uint8 ttype, uint8 code) internal returns (bool, bool) {}
    function db_restart_at_pc(bool watchpt) internal {}
    function db_trap(uint8 ttype, uint8 code) external accept returns (uint8) {
//    	jmp_buf jb;
//    	uint32 prev_jb;
//    	string why;
    	// Don't handle the trap if the console is unavailable (i.e. it is in graphics mode).
    	if (cnunavailable())
    		return 0;
        (bool bkpt, bool watchpt) = db_stop_at_pc(ttype, code);
    		if (db_inst_count > 0) {
    			db_printf("After %d instructions (%d loads, %d stores),\n", db_inst_count, db_load_count, db_store_count);
    		}
//    		prev_jb = kdb_jmpbuf(jb);
//    		if (setjmp(jb) == 0) {
//    			db_dot = PC_REGS();
//    			db_print_thread();
    			if (bkpt)
    				db_printf("Breakpoint at\t");
    			else if (watchpt)
    				db_printf("Watchpoint at\t");
    			else
    				db_printf("Stopped at\t");
//    			db_print_loc_and_inst(db_dot);
//    		}
//    		why = kdb_why;
//    		db_script_kdbenter(why != KDB_WHY_UNSET ? why : "unknown");
    		db_command_loop();
//    		kdb_jmpbuf(prev_jb);

    	db_restart_at_pc(watchpt);
    	return 1;
    }

    function db_init() external accept returns (uint8) {
    	db_command_init();
    	if (ksymtab.start != 0 && kstrtab.start != 0 && ksymtab_size != 0) {
    		ksymtab_private.strtab = kstrtab.start;
    		ksymtab_private.relbase = ksymtab_relbase;
    		db_add_symbol_table(ksymtab.start, ksymtab.start + ksymtab_size, "elf", ksymtab_private);
    	}
    	db_add_symbol_table(0, 0, "kld", ksymtab_private);
        s_consdev cn;
        dcn_init(cn);
    	return 1;	// We're the default debugger.
    }

    function rl(bytes cmd, uint8 n, uint8 k) external accept returns (byte t, byte c, uint8 result, uint8 l, bytes, bytes, bytes, bytes, bytes, bytes, uint8 bst, uint8 bend, uint8 lc, uint8 le, uint8 tok_no, uint8 linep, uint8 lp, uint8 endlp, byte) {
        if (n > 0) db_inject_line(cmd);
        if (k == 22) db_command_loop();
        if (n > 1) t = db_read_token();
        if (k > 1) c = db_read_char();
        if (n > 2) t = db_read_token();
        if (k > 2) c = db_read_char();
        if (n > 3) t = db_read_token();
        if (k > 3) c = db_read_char();
        if (n > 4) db_unread_token(t);
        if (k > 4) db_unread_char(c);
        if (k > 5) l = db_read_line();
        if (n > 5) t = db_read_token();
        if (k > 6) c = db_read_char();
        if (n > 6) t = db_read_token();
        return (t, c, result, l,  db_tok_string, db_line, db_capture_buf, _flush(0), _flush(1), out, db_lbuf_start, db_lbuf_end, db_lc, db_le, db_tok_number, db_linep, db_lp, db_endlp, db_look_token);
    }
    function dc(bytes cmd, uint8 n) external accept returns (byte t, byte c, uint8 result, uint8 l, bytes, bytes, bytes, bytes, bytes, bytes, db_command cmdp, db_command_table, db_command[] cmds) {
        if (n > 0) db_inject_line(cmd);
//        if (n > 1) l = db_read_line();
        if (n > 3) t = db_read_token();
        if (n > 4) (result, cmdp) = db_cmd_search(db_tok_string, db_cmd_table);
        if (n > 5) cmds = LIST_FOREACH(db_cmd_table);
        if (n > 6)
        if (n > 7) t = db_read_token();
        if (n == 11) {
            for (db_command dcc: cmds) {
                l = 0;
                while ((c = cmd[l]) == dcc.name[l]) {
                    out.append(bytes(c));
                    l++;
                }
                out.append(bytes(dcc.name[l]));
            }
        }
        return (t, c, result, l,  db_tok_string, db_line, db_capture_buf, _flush(0), _flush(1), out, cmdp, db_cmd_table, cmds);
    }
    function d(bytes cmd, uint8 n) external accept returns (byte t, byte c, uint8 result, uint8 l, bytes, bytes, bytes, bytes, bytes, bytes, db_command cmdp) {
//        if (n > 0) db_raw = cmd;
        if (n > 2) db_inject_line(cmd);
        t = db_read_token();
//        if (n > 8) l = db_read_line();
        if (n > 4) (result, cmdp) = db_cmd_search(db_tok_string, db_cmd_table);
        return (t, c, result, l,  db_tok_string, db_line, db_capture_buf, _flush(0), _flush(1), out, cmdp);
    }

    function db(bytes cmd) external accept returns (bytes) {
        db_inject_line(cmd);
        db_raw = cmd;
        db_command_loop();
        return out;
    }

    function db_cmd_list() external accept returns (bytes) {
        db_cmd_list(db_cmd_table);
        return out;
    }

    function upgrade(TvmCell c) external {
        tvm.accept();
        tvm.commit();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
        onCodeUpgrade();
    }
    function onCodeUpgrade() internal {

    }
    function reset_storage() external {
        tvm.accept();
        tvm.resetStorage();
    }

    function db_fetch_ksymtab(uint32 ksym_start, uint32 ksym_end, uint32 relbase) external accept returns (uint8) {
    	uint32 strsz;
    	if (ksym_end > ksym_start && ksym_start != 0) {
    		ksymtab.start = ksym_start;
    		ksymtab_size = ksymtab.start;
    //		ksymtab += sizeof(Elf_Size);
    		kstrtab.start = ksymtab.start + ksymtab_size;
    		strsz = kstrtab.start;
//    		kstrtab += sizeof(Elf_Size);
    		ksymtab_relbase = relbase;
    		if (kstrtab.start + strsz > ksym_end) {
    			// Sizes doesn't match, unset everything.
    			ksymtab.start = ksymtab_size = kstrtab.start = ksymtab_relbase = 0;
    		}
    	}
    	if (ksymtab.start == 0 || ksymtab_size == 0 || kstrtab.start == 0)
    		return 0xFF;
    	return 0;
    }

    // Add symbol table, with given name, to list of symbol tables.
    function db_add_symbol_table(uint32 start, uint32 end, string name, db_private ) internal {
	    if (db_nsymtab >= MAXNOSYMTABS) {
	    	printf ("No slots left for %s symbol table", name);
//	    	panic ("db_sym.c: db_add_symbol_table");
	    } else {
            //db_symtabs[db_nsymtab] = db_symtab(name, start, end, ksymtab_private);
            db_symtabs.push(db_symtab(name, start, end, ksymtab_private));
	        db_nsymtab++;
        }
    }
}


