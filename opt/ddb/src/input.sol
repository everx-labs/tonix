pragma ton-solidity >= 0.64.0;

import "capture.sol";
import "dcn.sol";
contract input is capture, dcn {

    uint8 db_lhistlsize;
    uint8 db_lhistidx;
    uint8 db_lhistcur;
    uint8 db_lhist_nlines;
    uint8 constant DB_RAW_SIZE = 255;//	512
    bytes db_raw; //[DB_RAW_SIZE];
    uint8 db_raw_pos;
    uint8 db_raw_cnt;
    bool db_raw_warned;

    uint8 db_lbuf_start;// start of input line buffer
    uint8 db_lbuf_end;	// end of input line buffer
    uint8 db_lc;		// current character
    uint8 db_le;		// one past last character
//    string[] db_lhistory; //[2048];
    bool ddb_prioritize_control_input = true;

    uint8 db_pager_quit;			// user requested quit
    uint8 constant DEL_FWD = 0;
    uint8 constant DEL_BWD = 1;
    byte constant BLANK = ' ';
    byte constant BACKUP = '\b';
    uint8 constant DB_MAXLINE	= 120;
    function CTRL(byte c) internal pure returns (byte) {
        return c & 0x1f;
    }
    // Get a character from the console, first checking the raw input buffer.
    function db_getc() internal returns (byte c) {
    	if (db_raw_cnt == 0)
    		c = cngetc();
    	else {
    		c = db_raw_pop();
    		if (c == '\r')
    			c = '\n';
    	}
    }

    function db_putstring(bytes s, uint8 count) internal {
    	for (uint i = 0; i < count; i++)
    	    cnputc(s[i]);
    }
    function db_putnchars(byte c, uint8 count) internal {
        repeat (count)
    	    cnputc(c);
    }
    // Delete N characters, forward or backward
    function db_delete(uint8 n, uint8 bwd) internal {
    	if (bwd > 0) {
    	    db_lc -= n;
    	    db_putnchars(BACKUP, n);
    	}
    	for (uint8 p = db_lc; p < db_le - n; p++) {
    	    //db_line[p] = db_line[p + n];
    	    cnputc(db_line[p]);
    	}
    	db_putnchars(BLANK, n);
    	db_putnchars(BACKUP, db_le - db_lc);
    	db_le -= n;
    }
    function db_inputchar(byte c) internal returns (bool) {
    	uint8 escstate;
    	if (escstate == 1) {
    		// ESC seen, look for [ or O
    		if (c == '[' || c == 'O')
    			escstate++;
    		else
    			escstate = 0; // re-init state machine
    		return false;
    	} else if (escstate == 2) {
    		escstate = 0;
    		// If a valid cursor key has been found, translate into an emacs-style control key, and fall through. Otherwise, drop off.
    		if (c == 'A')	// up
    			c = CTRL('p');
            else if (c == 'B')	// down
    			c = CTRL('n');
    		else if (c == 'C')	// right
    			c = CTRL('f');
    		else if (c == 'D')	// left
    			c = CTRL('b');
    		else
    			return false;
    	}
    	if (c == CTRL('['))
    		escstate = 1;
    	else if (c == CTRL('b')) {
    		// back up one character
    		if (db_lc > db_lbuf_start) {
    		    cnputc(BACKUP);
    		    db_lc--;
    		}
        } else if (c == CTRL('f')) {
    		// forward one character
    		if (db_lc < db_le) {
    		    cnputc(db_line[db_lc]);
    		    db_lc++;
    		}
        } else if (c == CTRL('a')) {
    		// beginning of line
    		while (db_lc > db_lbuf_start) {
    		    cnputc(BACKUP);
    		    db_lc--;
    		}
        } else if (c == CTRL('e')) {
    		// end of line
    		while (db_lc < db_le) {
    		    cnputc(db_line[db_lc]);
    		    db_lc++;
    		}
        } else if (c == CTRL('h') || c == 0x7F) {
    		// erase previous character
    		if (db_lc > db_lbuf_start)
    		    db_delete(1, DEL_BWD);
    	} else if (c == CTRL('d')) {
    		// erase next character
    		if (db_lc < db_le)
    		    db_delete(1, DEL_FWD);
    	} else if (c == CTRL('u') || c == CTRL('c')) {
    		// kill entire line: at first, delete to beginning of line
    		if (db_lc > db_lbuf_start)
    		    db_delete(db_lc - db_lbuf_start, DEL_BWD);
    		if (db_lc < db_le)
    		    db_delete(db_le - db_lc, DEL_FWD);
    	} else if (c == CTRL('k')) {
    		// delete to end of line
    		if (db_lc < db_le)
    		    db_delete(db_le - db_lc, DEL_FWD);
    	} else if (c == CTRL('t')) {
    		// twiddle last 2 characters
    		if (db_lc >= db_lbuf_start + 2) {
    		    //c = db_line[db_lc - 2];
    		    //db_line[db_lc - 2] = db_line[db_lc - 1];
    		    //db_line[db_lc - 1] = c;
    		    cnputc(BACKUP);
    		    cnputc(BACKUP);
    		    cnputc(db_line[db_lc - 2]);
    		    cnputc(db_line[db_lc - 1]);
    		}
    	} else if (c == CTRL('w')) {
    		// erase previous word
    		for (; db_lc > db_lbuf_start;) {
    		    if (db_line[(db_lc - 1)] != ' ')
    			    break;
    		    db_delete(1, DEL_BWD);
    		}
    		for (; db_lc > db_lbuf_start;) {
    		    if (db_line[(db_lc - 1)] == ' ')
    			    break;
    		    db_delete(1, DEL_BWD);
    		}
    	} else if (c == CTRL('r')) {
    		db_putstring("^R\n", 3);
//    	    redraw:
    		if (db_le > db_lbuf_start) {
    		    db_putstring(db_line[db_lbuf_start : ], db_le - db_lbuf_start);
    		    db_putnchars(BACKUP, db_le - db_lc);
    		}
    	} else if (c == CTRL('p')) {
    		// Make previous history line the active one
    		if (db_lhistcur >= 0) {
//    		    bcopy(db_lhistory + db_lhistcur * db_lhistlsize, db_lbuf_start, db_lhistlsize);
    		    db_lhistcur--;
//    		    goto hist_redraw;
    		}
    	} else if (c == CTRL('n')) {
    		// Make next history line the active one.
    		if (db_lhistcur < db_lhistidx - 1) {
    		    db_lhistcur += 2;
//    		    bcopy(db_lhistory + db_lhistcur * db_lhistlsize, db_lbuf_start, db_lhistlsize);
    		} else {
    		    // ^N through tail of history, reset the buffer to zero length.
    		    db_lbuf_start = 0;
    		    db_lhistcur = db_lhistidx;
    		}
    		db_putnchars(BACKUP, db_lc - db_lbuf_start);
    		db_putnchars(BLANK, db_le - db_lbuf_start);
    		db_putnchars(BACKUP, db_le - db_lbuf_start);
    		db_le = uint8(strchr(db_line, 0));
    		if (db_line[db_le - 1] == '\r' || db_line[db_le - 1] == '\n')
    		    //db_line[--db_le] = 0;
                db_line = db_line[ : --db_le];
    		db_lc = db_le;
        } else if (c == tEOF || c == '\n' || c == '\r') {
            if (c == tEOF)
    		    // eek! the console returned eof. probably that means we HAVE no console.. we should try bail
    		    c = '\r';
    	    db_line.append(bytes(c));
            db_le++;
//    		db_line[db_le++] = c;
    		return true;
        } else {
    	    if (db_le == db_lbuf_end) {
        		cnputc(0x07);
    	    } else if (c >= ' ' && c <= '~') {
    		//for (uint p = db_le; p > db_lc; p--)
    		//    db_line[p] = db_line[p - 1];
    		//db_line[db_lc++] = c;
                bytes tail = db_line[db_lc : ];
                db_line = db_line[ : db_lc++];
                db_line.append(bytes(c));
                db_line.append(tail);
    		    db_le++;
    		    cnputc(c);
    		    db_putstring(db_line[db_lc : ], db_le - db_lc);
    		    db_putnchars(BACKUP, db_le - db_lc);
    	    }
        }
    	return false;
    }
    function db_read_line() internal returns (uint8) {
    	//uint8 i = db_readline(db_line, uint8(db_line.length));
        uint8 i;
        i = db_readline(db_linep, uint8(db_line.length));
    	if (i == 0)
    	    return 0;	// EOI
    	db_lp = db_linep;
    	db_endlp = uint8(db_lp + i);
    	return i;
    }
    function db_readline(uint8 lstart, uint8 lsize) internal returns (uint8) {
    	if (lsize < 2)
    		return 0;
    	if (lsize != db_lhistlsize) {
    		// (Re)initialize input line history.  Throw away any existing history.
    		//db_lhist_nlines = uint8(db_lhistory.length / lsize);
    		db_lhistlsize = uint8(lsize);
    		db_lhistidx = 0xFF;
    	}
    	db_lhistcur = db_lhistidx;
//    	db_force_whitespace();	// synch output position
    	db_lbuf_start = lstart;
    	db_lbuf_end   = lstart + uint8(lsize) - 2;	// Will append NL and NUL.
    	db_lc = lstart;
    	db_le = lstart;
    	while (!db_inputchar(db_getc()))
    	    continue;
    	db_capture_write(db_line[lstart : ], db_le - db_lbuf_start);
    	db_printf("\n");	// synch output position
//    	db_le = 0;
        db_line.append(bytes(t0));
    	if (db_le - db_lbuf_start > 1) {
    	    // Maintain input line history for non-empty lines
    	    if (++db_lhistidx == db_lhist_nlines) {
    		    // Rotate history
//    		    bcopy(db_lhistory + db_lhistlsize, db_lhistory, db_lhistlsize * (db_lhist_nlines - 1));
    		    db_lhistidx--;
    	    }
//    	    bcopy(lstart, db_lhistory + db_lhistidx * db_lhistlsize, db_lhistlsize);
    	}
    	return db_le - db_lbuf_start;
    }
    bool kdb_active;
    // Whether the raw input buffer has space to accept another character
    function db_raw_space() internal view returns (bool) {
    	return db_raw_cnt < DB_RAW_SIZE;
    }
    // Un-get a character from the console by buffering it
    function db_raw_push(byte c) internal {
    	if (!db_raw_space())
    		db_error("");
        db_raw_cnt++;
//    	db_raw[(db_raw_pos + db_raw_cnt) % DB_RAW_SIZE] = c;
        db_raw.append(bytes(c));
    }
    // Drain a character from the raw input buffer
    function db_raw_pop() internal returns (byte) {
    	if (db_raw_cnt == 0)
    		return tEOF;
    	db_raw_cnt--;
    	db_raw_warned = false;
    	return db_raw[db_raw_pos++ % DB_RAW_SIZE];
    }
    function db_do_interrupt(string reason) internal {
    	// Do a pager quit too because some commands have jmpbuf handling
//    	db_disable_pager();
    	db_pager_quit = 1;
    	db_error(reason);
    }
    function db_check_interrupt() internal {
    	byte c;
   	    // Check console input for control characters.  Non-control input is buffered.  When buffer space is exhausted,
        // either stop responding to control input or drop further non-control input on the floor.
    	for (;;) {
    		if (!ddb_prioritize_control_input && !db_raw_space())
    			return;
    		c = cncheckc();
    		if (c == tEOF) // no character
    			return;
    		else if (c == CTRL('c'))
    			db_do_interrupt("^C");
    			/*NOTREACHED*/
    		else if (c == CTRL('s')) {
    			do {
    				c = cncheckc();
    				if (c == CTRL('c'))
    					db_do_interrupt("^C");
    			} while (c != CTRL('q'));
    			break;
            } else {
    			if (db_raw_space()) {
    				db_raw_push(c);
    			} else if (!db_raw_warned) {
    				db_raw_warned = true;
    				db_printf("\n--Exceeded input buffer--\n");
    			}
    			break;
    		}
    	}
    }

}