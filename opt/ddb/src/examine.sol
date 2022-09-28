pragma ton-solidity >= 0.64.0;
import "output.sol";
import "access.sol";
import "sym.sol";
contract examine is output, access {
    uint32 db_dot;      	// current location
    uint32 db_last_addr;	// last explicit address typed
    uint32 db_prev;	        // last address examined or written
    uint32 db_next;	        // next address to be examined or written
    string	db_examine_format = "x"; // [TOK_STRING_SIZE]

    function db_examine_cmd(uint8 addr, bool have_addr, uint8 count, byte modif) internal {
    	if (modif != '\x00')
    	    db_strcpy(db_examine_format, modif);
    	if (count == -1)
    	    count = 1;
    	db_examine(addr, db_examine_format, count);
    }

    function db_examine(uint8 addr, bytes fmt, int count) internal {
    	uint8		c;
    	uint8	value;
    	uint8		size;
    	uint8		width;
    	uint8	fp;

    	while (--count >= 0 && !db_pager_quit) {
    	    //fp = fmt;
    	    size = 4;
    	    while ((c = fmt[fp++]) != 0) {
        		if (c == 'b') size = 1;
        		if (c == 'h') size = 2;
        		if (c == 'l') size = 4;
        		if (c == 'g') size = 8;
        		if (c == 'a') {
                    size = 4; //sizeof(void *);
        			// always forces a new line */
        			if (db_print_position() != 0) {
        			    db_printf("\n");
        			    db_prev = addr;
        			    db_printsym(addr, DB_STGY_ANY);
        			    db_printf(":\t");
    	            } else {
        			    if (db_print_position() == 0) {
        			        /* Print the address. */
        			        db_printsym(addr, DB_STGY_ANY);
        			        db_printf(":\t");
        			        db_prev = addr;
        			    }
    			        width = size * 4;
                    }
    			    if (c == 'r') {	// signed, current radix
    			    	value = db_get_value(addr, size, true);
    			    	addr += size;
    			    	db_printf("%+-*lr", width, value);
                    } else if (c == 'x') {	/* unsigned hex */
    			    	value = db_get_value(addr, size, false);
    			    	addr += size;
    			    	db_printf("%-*lx", width, value);
                    } else if (c == 'z') {	/* signed hex */
    			    	value = db_get_value(addr, size, true);
    			    	addr += size;
    			    	db_printf("%-*ly", width, value);
                    } else if (c == 'd') {	/* signed decimal */
    			    	value = db_get_value(addr, size, true);
    			    	addr += size;
    			    	db_printf("%-*ld", width, value);
                    } else if (c == 'u') {	/* unsigned decimal */
    			    	value = db_get_value(addr, size, false);
    			    	addr += size;
    			    	db_printf("%-*lu", width, value);
                    } else if (c == 'o') {	/* unsigned octal */
    			    	value = db_get_value(addr, size, false);
    			    	addr += size;
    			    	db_printf("%-*lo", width, value);
                    } else if (c == 'c') {	/* character */
    			    	value = db_get_value(addr, 1, false);
    			    	addr += 1;
    			    	if (value >= ' ' && value <= '~')
    			    	    db_printf("%c", value);
    			    	else
    			    	    db_printf("\\%03o", value);
                    } else if (c == 's') {	/* null-terminated string */
    			    	for (;;) {
    			    	    value = db_get_value(addr, 1, false);
    			    	    addr += 1;
    			    	    if (value == 0)
    			    		    break;
    			    	    if (value >= ' ' && value <= '~')
    			    		    db_printf("%c", value);
    			    	    else
    			    		    db_printf("\\%03o", value);
    			    	}
                    } else if (c =='S') {	// symbol
    			    	value = db_get_value(addr, 4, false);
    			    	addr += 4;
    			    	db_printsym(value, DB_STGY_ANY);
                    } else if (c =='i') {	// instruction
    			    	addr = db_disasm(addr, false);
                    } else if (c =='I') {	// instruction, alternate form
    			    	addr = db_disasm(addr, true);
    			    }
    			    if (db_print_position() != 0)
    			        db_end_line(1);
    			    break;
    		    }
    	    }
    	}
    	db_next = addr;
    }

    // Print value.
    byte	db_print_format = 'x';

    function db_print_cmd(uint8 addr, bool have_addr, uint8 count, byte modif) internal {
    	uint8	value;
    	if (modif != '\x00')
    	    db_print_format = modif;
        if (db_print_format == 'a')
    		db_printsym(addr, DB_STGY_ANY);
    	else if (db_print_format == 'r')
    		db_printf("%+11lr", addr);
        else if (db_print_format == 'x')
    		db_printf("%8lx", addr);
        else if (db_print_format == 'z')
    		db_printf("%8ly", addr);
        else if (db_print_format == 'd')
    		db_printf("%11ld", addr);
        else if (db_print_format == 'u')
    		db_printf("%11lu", addr);
        else if (db_print_format == 'o')
    		db_printf("%16lo", addr);
        else if (db_print_format == 'c') {
    		value = addr & 0xFF;
    		if (value >= ' ' && value <= '~')
    		    db_printf("%c", value);
    		else
    		    db_printf("\\%03o", value);
        } else {
    		db_print_format = 'x';
    		db_error("Syntax error: unsupported print modifier\n");
    		/*NOTREACHED*/
    	}
    	db_printf("\n");
    }

    function db_print_loc_and_inst(uint8 loc) internal {
    	uint8 off;
    	db_printsym(loc, DB_STGY_PROC);
    	if (db_search_symbol(loc, DB_STGY_PROC, off) != C_DB_SYM_NULL) {
    		db_printf(":\t");
    		db_disasm(loc, false);
    	}
    }

    // Search for a value in memory. Syntax: search [/bhl] addr value [mask] [,count]
    function db_search_cmd(uint8 dummy1, bool dummy2, uint8 dummy3, byte dummy4) internal {
    	uint8 size;
    	uint8 value;
    	uint8 mask;
    	uint8 count;

    	byte t = db_read_token();
    	if (t == tSLASH) {
    	    t = db_read_token();
    	    if (t != tIDENT) {
        		db_printf("Bad modifier\n");
        		db_flush_lex();
        		return;
    	    }
    	    if (!strcmp(db_tok_string, "b"))
        		size = 1;
    	    else if (!strcmp(db_tok_string, "h"))
        		size = 2;
    	    else if (!strcmp(db_tok_string, "l"))
        		size = 4;
    	    else {}
    	} else {
    	    db_unread_token(t);
    	    size = 4;
    	}
        (bool f, uint8 addr) = db_expression();
    	if (!f) {
    	    db_printf("Address missing\n");
    	    db_flush_lex();
    	    return;
    	}
        (f, value) = db_expression();
    	if (!f) {
    	    db_printf("Value missing\n");
    	    db_flush_lex();
    	    return;
    	}
        (f, mask) = db_expression();
    	if (!f)
    	    mask = 0xffffffff;
    	t = db_read_token();
    	if (t == tCOMMA) {
            (f, count) = db_expression();
    	    if (!f) {
        		db_printf("Count missing\n");
        		db_flush_lex();
        		return;
    	    }
    	} else {
    	    db_unread_token(t);
    	    count = -1;		/* effectively forever */
    	}
    	db_skip_to_eol();
    	db_search(addr, size, value, mask, count);
    }

    function db_search(uint8 addr, uint8 size, uint8 value, uint8 mask, uint8 count) internal {
    	while (count-- != 0) {
    		db_prev = addr;
    		if ((db_get_value(addr, size, false) & mask) == value)
    			break;
    		addr += size;
    	}
    	db_next = addr;
    }
}