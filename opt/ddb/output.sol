pragma ton-solidity >= 0.64.0;

import "dcn.sol";
import "input.sol";

library lub {
    function st(uint u, byte c) internal {
        uint n;
        uint m;
        while ((u >> m & 0xFF) > 0) {
            n++;
            m += 8;
        }
        u |= uint(uint8(c)) << m;
    }
}
contract output is input {
    // Character output - tracks position in line.	To do this correctly, we should know how wide the output device is - then we could zero
    // the line position when the output device wraps around to the start of the next line.
    // Instead, we count the number of spaces printed since the last printing character so that we don't print trailing spaces. This avoids most the wraparounds.
    uint8 db_output_position = 0;	// output column
    uint8 db_last_non_space = 0;	// last non-space character
    uint8 db_tab_stop_width = 8;	// how wide are tab stops?
    //#define	NEXT_TAB(i) rounddown((i) + db_tab_stop_width, db_tab_stop_width)
    uint8 db_max_width = 79;		// output line width
    uint8 db_lines_per_page = 20;	// lines per page
    uint8 db_newlines;			    // # lines this page
    uint8 db_maxlines;			    // max lines/page when paging

    uint32 db_dot;      	// current location
    uint32 db_last_addr;	// last explicit address typed
    uint32 db_prev;	        // last address examined or written
    uint32 db_next;	        // next address to be examined or written

    uint constant NULL = 0;
    bool db_ed_style = true;

//    TvmBuilder bout;

    function buf_dump() external view returns (bytes, uint8, bytes, bytes, uint8, uint8, uint8, byte, uint8, uint8, uint8, uint8, bytes, uint8, uint8) {
        return (db_tok_string, db_tok_number, out, db_line, db_linep, db_lp, db_endlp, db_look_token, db_lbuf_start, db_lbuf_end, db_lc, db_le, db_raw, db_raw_pos, db_raw_cnt);
    }
    // Force pending whitespace.
    function db_force_whitespace() internal {
    	uint8 last_print;
        uint8 next_tab;
    	last_print = db_last_non_space;
    	while (last_print < db_output_position) {
    	    //next_tab = NEXT_TAB(last_print);
    	    if (next_tab <= db_output_position) {
    		    while (last_print < next_tab) { // DON'T send a tab!!!
    		    	cnputc(' ');
    		    	db_capture_writech(' ');
    		    	last_print++;
    		    }
    	    }
    	    else {
    		    cnputc(' ');
    		    db_capture_writech(' ');
    		    last_print++;
    	    }
    	}
    	db_last_non_space = db_output_position;
    }


    using lub for uint;
    // Output character.  Buffer whitespace.
    function db_putchar(byte c, dbputchar_arg arg) internal {
    	dbputchar_arg dap = arg;
    	if (dap.da_nbufr == 0) {
    		// No bufferized output is provided.
    		db_putc(c);
    	} else {
    		dap.da_pnext = c;
            //dap.da_pbufr.store(c);
            dap.da_pbufr.st(c);
    		dap.da_remain--;
    		// Leave always the buffer 0 terminated.
    		dap.da_pnext = '\x00';
    		// Check if the buffer needs to be flushed.
    		if (dap.da_remain < 2 || c == '\n') {
                db_puts(dap.da_pbufr);
//    			db_puts(dap.da_pbufr.toSlice());
//    			dap.da_pnext = dap.da_pbufr;
    			dap.da_remain = dap.da_nbufr;
    			dap.da_pnext = '\x00';
    		}
    	}
    }

    function db_putc(byte c) internal {
    	// If not in the debugger or the user requests it, output data to both the console and the message buffer.
    	if (!kdb_active || ddb_use_printf) {
    		printf("%c", c);
    		if (!kdb_active)
    			return;
    		if (c == '\r' || c == '\n')
    			db_check_interrupt();
    		if (c == '\n' && db_maxlines > 0) {
    			db_newlines++;
    			if (db_newlines >= db_maxlines)
    				db_pager();
    		}
    		return;
    	}
    	// Otherwise, output data directly to the console.
    	if (c > ' ' && c <= '~') {
    	    // Printing character. If we have spaces to print, print them first. Use tabs if possible.
    	    db_force_whitespace();
    	    cnputc(c);
    	    db_capture_writech(c);
    	    db_output_position++;
    	    db_last_non_space = db_output_position;
    	}
    	else if (c == '\n') {
    	    // Newline
    	    cnputc(c);
    	    db_capture_writech(c);
    	    db_output_position = 0;
    	    db_last_non_space = 0;
    	    db_check_interrupt();
    	    if (db_maxlines > 0) {
    		    db_newlines++;
    		    if (db_newlines >= db_maxlines)
    			    db_pager();
    	    }
    	}
    	else if (c == '\r') {
    	    // Return
    	    cnputc(c);
    	    db_capture_writech(c);
    	    db_output_position = 0;
    	    db_last_non_space = 0;
    	    db_check_interrupt();
    	}
    	else if (c == '\t') {
    	    // assume tabs every 8 positions
    	    //db_output_position = NEXT_TAB(db_output_position);
    	}
    	else if (c == ' ') {
    	    // space
    	    db_output_position++;
    	}
    	else if (c == 0x07) {
    	    // bell
    	    cnputc(c);
    	    // No need to beep in a log: db_capture_writech(c); */
    	}
    	// other characters are assumed non-printing
    }

    function db_puts(uint u) internal {
        uint n;
        uint m;
        uint8 t;
        while ((t = uint8(u >> m & 0xFF)) > 0) {
            n++;
            m += 8;
            db_putc(byte(t));
        }
    }

    function db_puts(TvmSlice s) internal {
        while (s.hasNBits(8)) {
            byte c = s.decode(byte);
            if (c == t0)
                break;
            else
                db_putc(c);
        }
    }

    function db_puts(bytes str) internal {
    	for (uint i = 0; str[i] != '\x00'; i++)
    		db_putc(str[i]);
    }

    function db_enable_pager() internal {
    	if (db_maxlines == 0) {
    		db_maxlines = db_lines_per_page;
    		db_newlines = 0;
    		db_pager_quit = 0;
    	}
    }

    function db_disable_pager() internal {
    	db_maxlines = 0;
    }

    // A simple paging callout function.  It supports several simple more(1)-like commands as well as a quit command
    // that sets db_pager_quit which db commands can poll to see if they should terminate early.
    function db_pager() internal {
    	byte c;
    	db_capture_enterpager();
    	db_printf("--More--\r");
    	uint8 done = 0;
    	while (done == 0) {
    		c = db_getc();
    		if (c == 'e' || c == 'j' || c == '\n') {
    			// Just one more line
    			db_maxlines = 1;
    			done++;
    			break;
            } else if (c == 'd') {
    			// Half a page
    			db_maxlines = db_lines_per_page / 2;
    			done++;
    			break;
    		} else if (c == 'f' || c == ' ') {
    			// Another page
    			db_maxlines = db_lines_per_page;
    			done++;
    			break;
    		} else if (c == 'q' || c == 'Q' || c == 'x' || c == 'X') {
    			// Quit
    			db_maxlines = 0;
    			db_pager_quit = 1;
    			done++;
    			break;
    		}
    	}
    	db_printf("        ");
    	db_force_whitespace();
    	db_printf("\r");
    	db_newlines = 0;
    	db_capture_exitpager();
    }

    function db_print_position() internal view returns (uint8) {
    	return db_output_position;
    }

    // End line if too long.
    function db_end_line(uint8 field_width) internal {
    	if (db_output_position + field_width > db_max_width)
    	    db_printf("\n");
    }


}