pragma ton-solidity >= 0.64.0;

import "lex.sol";
contract capture is lex {

    uint32 constant DDB_CAPTURE_DEFAULTBUFSIZE = 48 * 1024;
    uint32 constant DDB_CAPTURE_MAXBUFSIZE = 5 * 1024 * 1024;
    bytes db_capture_buf;
    uint32 db_capture_bufsize = DDB_CAPTURE_DEFAULTBUFSIZE;
//    uint32 db_capture_maxbufsize = DDB_CAPTURE_MAXBUFSIZE; // Read-only
    uint32 db_capture_bufoff;		// Next location to write in buffer
    uint32 db_capture_bufpadding;	// Amount of zero padding
    bool db_capture_inpager;		// Suspend capture in pager
    bool db_capture_inprogress;	    // DDB capture currently in progress

    // Routines for capturing DDB output into a fixed-size buffer.  These are invoked from DDB's input and output routines.
    // If we hit the limit on the buffer, we simply drop further data.
    function db_capture_write(bytes buffer, uint16 buflen) internal {
    	uint len;
    	if (!db_capture_inprogress || db_capture_inpager)
    		return;
    	len = math.min(buflen, db_capture_bufsize - db_capture_bufoff);
//    	bcopy(buffer, db_capture_buf + db_capture_bufoff, len);
        db_capture_buf.append(buffer);
    	db_capture_bufoff += uint32(len);
    //	KASSERT(db_capture_bufoff <= db_capture_bufsize, ("db_capture_write: bufoff > bufsize"));
    }
    function db_capture_writech(byte ch) internal {
    	db_capture_write(bytes(ch), 1);
    }
    function db_capture_enterpager() internal {
    	db_capture_inpager = true;
    }
    function db_capture_exitpager() internal {
    	db_capture_inpager = false;
    }
    // Zero out any bytes left in the last block of the DDB capture buffer.  This is run shortly before writing the blocks to disk,
    // rather than when output capture is stopped, in order to avoid injecting nul's into the middle of output.
    function db_capture_zeropad() internal {
//    	uint8 len = min(TEXTDUMP_BLOCKSIZE, (db_capture_bufsize - db_capture_bufoff) % TEXTDUMP_BLOCKSIZE);
//    	bzero(db_capture_buf + db_capture_bufoff, len);
//    	db_capture_bufpadding = len;
    }
    // Reset capture state, which flushes buffers.
    function db_capture_reset() internal {
    	db_capture_inprogress = false;
    	db_capture_bufoff = 0;
    	db_capture_bufpadding = 0;
    }
    // Start capture.  Only one session is allowed at any time, but we may continue a previous session, so the buffer isn't reset.
    function db_capture_start() internal {
    	if (db_capture_inprogress) {
    		db_printf("Capture already started\n");
    		return;
    	}
    	db_capture_inprogress = true;
    }
    // Terminate DDB output capture--real work is deferred to db_capture_dump, which executes outside of the DDB context.
    // We don't zero pad here because capture may be started again before the dump takes place.
    function db_capture_stop() internal {
    	if (db_capture_inprogress == false) {
    		db_printf("Capture not started\n");
    		return;
    	}
    	db_capture_inprogress = false;
    }
    struct s_dumperinfo {
        uint i;
    }
    // Dump DDB(4) captured output (and resets capture buffers).
    /*function db_capture_dump(s_dumperinfo di) internal {
    	uint8 offset;
    	if (db_capture_bufoff == 0)
    		return;
    	db_capture_zeropad();
    	textdump_mkustar(textdump_block_buffer, DDB_CAPTURE_FILENAME, db_capture_bufoff);
    	textdump_writenextblock(di, textdump_block_buffer);
    	for (offset = 0; offset < db_capture_bufoff + db_capture_bufpadding; offset += TEXTDUMP_BLOCKSIZE)
    		textdump_writenextblock(di, db_capture_buf + offset);
    	db_capture_bufoff = 0;
    	db_capture_bufpadding = 0;
    }*/
    /*-
     * DDB(4) command to manage capture:
     *
     * capture on          - start DDB output capture
     * capture off         - stop DDB output capture
     * capture reset       - reset DDB capture buffer (also stops capture)
     * capture status      - print DDB output capture status
     */
    function db_capture_usage() internal {
    	db_error("capture [on|off|reset|status]\n");
    }
    function db_capture_cmd(uint8, bool, uint8, bytes) external accept {
    	byte t = db_read_token();
    	if (t != tIDENT) {
    		db_capture_usage();
    		return;
    	}
    	if (db_read_token() != tEOL)
    		db_error("?\n");
    	if (strcmp(db_tok_string, "on") == 0)
    		db_capture_start();
    	else if (strcmp(db_tok_string, "off") == 0)
    		db_capture_stop();
    	else if (strcmp(db_tok_string, "reset") == 0)
    		db_capture_reset();
    	else if (strcmp(db_tok_string, "status") == 0) {
    		db_printf("%u/%u bytes used\n", db_capture_bufoff,db_capture_bufsize);
    		if (db_capture_inprogress)
    			db_printf("capture is on\n");
    		else
    			db_printf("capture is off\n");
    	} else
    		db_capture_usage();
    }

}