pragma ton-solidity >= 0.64.0;

import "print.sol";
enum drt_radix { DRT_DEFAULT_RADIX, DRT_OCTAL, DRT_DECIMAL, DRT_HEXADECIMAL }
enum drt_flags { DRT_WSPACE, DRT_HEX }
contract lex is print {

    uint8 constant DRT_RADIX_MASK	= 0x3;

    bytes db_tok_string;
    uint8 db_tok_number;

    bytes db_line; //[DB_MAXLINE];
    uint8 db_linep;
    uint8 db_lp;
    uint8 db_endlp;
    byte db_look_token = 0;


    function db_error(string s) internal {
    	if (!s.empty())
    	    db_printf("%s", s);
    	db_flush_lex();
//    	kdb_reenter_silent();
    }

    // Simulate a line of input into DDB.
    function db_inject_line(bytes cmd) internal {
    	//strlcpy(db_line, command, sizeofdb_line));
        db_line = cmd;
        //db_line.append(bytes(t0));
    	db_lp = db_linep;
    	db_endlp = db_lp + uint8(cmd.length);
    }

    function db_flush_lex() internal {
    	db_flush_line();
    	db_look_token = 0;
    }

    function db_flush_line() internal {
    	db_lp = db_linep;
    	db_endlp = db_linep;
    }

    function db_read_token() internal returns (byte) {
    	return db_read_token_flags(0);
    }
    function db_unread_token(byte t) internal {
    	db_look_token = t;
    }
    function db_read_token_flags(uint8 flags) internal returns (byte) {
    	byte t;
//    	MPASS((flags & ~(DRT_VALID_FLAGS_MASK)) == 0);
    	if (db_look_token > 0) {
    	    t = db_look_token;
    	    db_look_token = 0;
    	}
    	else
    	    t = db_lex(flags);
    	return t;
    }

    function db_read_char() internal returns (byte c) {
    	if (db_lp >= db_endlp)
    	    c = tEOF;
    	else
    	    c = db_line[db_lp++];
    }
    function db_unread_char(byte c) internal {
    	if (c == tEOF) {
    		// Unread EOL at EOL is okay
    		if (db_lp < db_endlp)
    			db_error("db_unread_char(-1) before end of line\n");
    	} else {
    		if (db_lp > db_linep) {
    			db_lp--;
    			if (db_line[db_lp] != c)
    				db_error("db_unread_char() wrong char\n");
    		} else
    			db_error("db_unread_char() at beginning of line\n");
    	}
    }
    function db_lex(uint8 flags) internal returns (byte) {
    	byte c;
        uint8 n;
        uint8 radix_mode;
    	bool lex_wspace;
        bool lex_hex_numbers;
        uint8 rm = flags & DRT_RADIX_MASK;
    	if (rm == uint8(drt_radix.DRT_DEFAULT_RADIX))
    		radix_mode = 0xFF;
    	else if (rm == uint8(drt_radix.DRT_OCTAL))
    		radix_mode = 8;
    	else if (rm == uint8(drt_radix.DRT_DECIMAL))
    		radix_mode = 10;
    	else if (rm == uint8(drt_radix.DRT_HEXADECIMAL))
    		radix_mode = 16;
    	lex_wspace = ((flags & uint8(drt_flags.DRT_WSPACE)) != 0);
    	lex_hex_numbers = ((flags & uint8(drt_flags.DRT_HEX)) != 0);
    	c = db_read_char();
    	for (n = 0; c <= ' ' || c > '~'; n++) {
    	    if (c == '\n' || c == 0xFF)
    		    return tEOL;
    	    c = db_read_char();
    	}
    	if (lex_wspace && n != 0) {
    	    db_unread_char(c);
    	    return tWSPACE;
    	}
    	if ((c >= '0' && c <= '9') || (lex_hex_numbers && ((c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')))) {
    	    /* number */
    	    uint8 r;
            uint8 digit = 0;
    	    if (radix_mode > 0)
    		    r = radix_mode;
    	    else if (c != '0')
    		    r = db_radix;
    	    else {
    		    c = db_read_char();
    		    if (c == 'O' || c == 'o')
    		        r = 8;
    		    else if (c == 'T' || c == 't')
    		        r = 10;
    		    else if (c == 'X' || c == 'x')
    		        r = 16;
    		    else {
    		        r = db_radix;
    		        db_unread_char(c);
    		    }
    		    c = db_read_char();
    	    }
    	    db_tok_number = 0;
    	    for (;;) {
    		    //if (c >= '0' && c <= ((r == 8) ? '7' : '9'))
                if (c >= '0' && c <= '9')
    		        digit = uint8(c) - 0x30; // '0'
    		    else if (r == 16 && ((c >= 'A' && c <= 'F') || (c >= 'a' && c <= 'f'))) {
    		        if (c >= 'a')
    		    	    digit = uint8(c) - 0x61 + 10; // 'a'
    		        else if (c >= 'A')
    		    	    digit = uint8(c) - 0x41 + 10; // 'A'
    		    } else
    		        break;
    		    db_tok_number = db_tok_number * r + digit;
    		    c = db_read_char();
    	    }
    	    if ((c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c == '_')) {
    		    db_error("Bad character in number\n");
    		    db_flush_lex();
    		    return tEOF;
    	    }
    	    db_unread_char(c);
    	    return tNUMBER;
    	}
    	if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '_' || c == '\\') {
    	    /* string */
    	    bytes cp;
    	    cp = db_tok_string;
    	    if (c == '\\') {
    		c = db_read_char();
    		if (c == '\n' || c == tEOF)
    		    db_error("Bad escape\n");
    	    }
    	    //cp++ = c;
            //cp.append(bytes(c));
            db_tok_string.append(bytes(c));
    	    while (true) {
    		    c = db_read_char();
    		    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_' || c == '\\' || c == ':' || c == '.') {
    		        if (c == '\\') {
    		    	    c = db_read_char();
    		    	    if (c == '\n' || c == 0xFF)
    		    	        db_error("Bad escape\n");
    		        }
    		        //*cp++ = c;
                    //cp.append(bytes(c));
                    db_tok_string.append(bytes(c));
//    		        if (cp.length == db_tok_string + uint8(db_tok_string.length)) {
//    		    	    db_error("String too long\n");
//    		    	    db_flush_lex();
//    		    	    return (tEOF);
//    		        }
    		        continue;
    		    } else {
    		        //*cp = '\0';
                    //delete cp;
                    //db_tok_string = bytes(t0);
                    db_tok_string.append(bytes(t0));
    		        break;
    		    }
    	    }
    	    db_unread_char(c);
    	    return tIDENT;
    	}
    	if (c == '+') return tPLUS;
    	if (c == '-') return tMINUS;
        if (c == '.') {
    		c = db_read_char();
    		if (c == '.')
    		    return tDOTDOT;
    		db_unread_char(c);
    		return tDOT;
        }
    	if (c == '*') return tSTAR;
    	if (c == '/') return tSLASH;
        if (c == '=') {
    		c = db_read_char();
    		if (c == '=')
    		    return tLOG_EQ;
    		db_unread_char(c);
    		return tEQ;
        }
        if (c == '%') return tPCT;
    	if (c == '#') return tHASH;
    	if (c == '(') return tLPAREN;
    	if (c == ')') return tRPAREN;
    	if (c == ',') return tCOMMA;
    	if (c == '"') return tDITTO;
    	if (c == '$') return tDOLLAR;
    	if (c == '!') {
    		c = db_read_char();
    		if (c == '=')
    			return tLOG_NOT_EQ;
    		db_unread_char(c);
    		return tEXCL;
        }
        if (c == ':') {
    		c = db_read_char();
    		if (c == ':')
    			return tCOLONCOLON;
    		db_unread_char(c);
    		return tCOLON;
        }
    	if (c == ';') return tSEMI;
    	if (c == '&') {
    		c = db_read_char();
    		if (c == '&')
    		    return tLOG_AND;
    		db_unread_char(c);
    		return tBIT_AND;
        }
    	if (c == '|') {
    		c = db_read_char();
    		if (c == '|')
    		    return tLOG_OR;
    		db_unread_char(c);
    		return tBIT_OR;
        }
    	if (c == '<') {
    		c = db_read_char();
    		if (c == '<')
    		    return tSHIFT_L;
    		if (c == '=')
    		    return tLESS_EQ;
    		db_unread_char(c);
    		return tLESS;
        }
    	if (c == '>') {
    		c = db_read_char();
    		if (c == '>')
    		    return tSHIFT_R;
    		if (c == '=')
    		    return tGREATER_EQ;
    		db_unread_char(c);
    		return tGREATER;
        }
    	if (c == '?') return tQUESTION;
    	if (c == '~') return tBIT_NOT;
    	if (c == 0xFF) return tEOF;
    	db_printf("Bad character\n");
    	db_flush_lex();
    	return tEOF;
    }
}