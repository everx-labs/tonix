
contract expr {
    function db_term() internal returns (bool f, uint8 valuep) {
    	byte t = db_read_token();
    	if (t == tIDENT) {
            (f, valuep) = db_value_of_name(db_tok_string);
            if (!f)
                (f, valuep) = db_value_of_name_pcpu(db_tok_string);
            if (!f)
                (f, valuep) = db_value_of_name_vnet(db_tok_string);
            if (!f) {
    		    db_printf("Symbol '%s' not found\n", db_tok_string);
    		    db_error(NULL);
    		    /*NOTREACHED*/
    	    }
    	    return (true, valuep);
    	}
    	if (t == tNUMBER)
    	    return (true, db_tok_number);
    	if (t == tDOT)
    	    return (true, db_dot);
    	if (t == tDOTDOT)
    	    return (true, db_prev);
    	if (t == tPLUS)
    	    return (true, db_next);
    	if (t == tDITTO)
    	    return (true, db_last_addr);
    	if (t == tDOLLAR)
            return db_get_variable();
    	if (t == tLPAREN) {
            (f, valuep) = db_expression();
    	    if (!f) {
        		db_printf("Expression syntax error after '%c'\n", '(');
        		db_error(NULL);
        		/*NOTREACHED*/
    	    }
    	    t = db_read_token();
    	    if (t != tRPAREN) {
    		    db_printf("Expression syntax error -- expected '%c'\n", ')');
    		    db_error(NULL);
    		    /*NOTREACHED*/
    	    }
    	    return (true, valuep);
    	}
    	db_unread_token(t);
    	return (false, 0);
    }

    function db_unary() internal returns (bool f, uint8 valuep) {
    	byte t = db_read_token();
    	if (t == tMINUS) {
            (f, valuep) = db_unary();
    	    if (!f) {
    		    db_printf("Expression syntax error after '%c'\n", '-');
    		    db_error(NULL);
    		    /*NOTREACHED*/
    	    }
//    	    *valuep = -*valuep;
    	    return (true, valuep);
    	}
    	if (t == tEXCL) {
            (f, valuep) = db_unary();
    	    if (!f) {
    		    db_printf("Expression syntax error after '%c'\n", '!');
    		    db_error(NULL);
    		    /* NOTREACHED  */
    	    }
//    	    *valuep = (!(*valuep));
    	    return (true, !valuep);
    	}
    	if (t == tBIT_NOT) {
            (f, valuep) = db_unary();
    	    if (!f) {
    		    db_printf("Expression syntax error after '%c'\n", '~');
    		    db_error(NULL);
    		    /* NOTREACHED */
    	    }
    	    return (true, ~valuep);
    	}
    	if (t == tSTAR) {
    	    /* indirection */
            (f, valuep) = db_unary();
    	    if (!f) {
    		    db_printf("Expression syntax error after '%c'\n", '*');
    		    db_error(NULL);
    		    /*NOTREACHED*/
    	    }
    	    return (true, db_get_value(valuep, 4, false);
    	}
    	db_unread_token(t);
    	return db_term();
    }

    function db_mult_expr() internal returns (bool f, uint8 lhs) {
        (f, lhs) = db_unary();
    	if (!f)
    	    return (false, valuep);
    	byte t = db_read_token();
    	while (t == tSTAR || t == tSLASH || t == tPCT || t == tHASH || t == tBIT_AND) {
            uint8 rhs;
            (f, rhs) = db_term();
    	    if (!f) {
    		    db_printf("Expression syntax error after '%c'\n",
    		        t == tSTAR ? '*' : t == tSLASH ? '/' : t == tPCT ? '%' :
    		        t == tHASH ? '#' : '&');
    		    db_error(NULL);
    		    /*NOTREACHED*/
    	    }
    		if (t == tSTAR)
    		    lhs *= rhs;
    		else if (t == tBIT_AND)
    		    lhs &= rhs;
            else {
    		    if (rhs == 0) {
        			db_error("Division by 0\n");
        			/*NOTREACHED*/
    		    }
    		    if (t == tSLASH)
        			lhs /= rhs;
    		    else if (t == tPCT)
    	    		lhs %= rhs;
    		    else
        			lhs = roundup(lhs, rhs);
    	    }
    	    t = db_read_token();
    	}
    	db_unread_token(t);
    	return (true, lhs);
    }

    function  db_add_expr() internal returns (bool f, uint8 lhs) {
    	uint8 rhs;
        (f, lhs) = db_mult_expr();
    	if (!f)
    	    return (false, 0);
    	byte t = db_read_token();
    	while (t == tPLUS || t == tMINUS || t == tBIT_OR) {
            (f, rhs) = db_mult_expr();
    	    if (!f) {
    		    db_printf("Expression syntax error after '%c'\n", t == tPLUS ? '+' : t == tMINUS ? '-' : '|');
    		    db_error(NULL);
    		    /*NOTREACHED*/
    	    }
    	    if (t == tPLUS)
    		    lhs += rhs;
            else if (t == tMINUS)
    		    lhs -= rhs;
            else if (t == tBIT_OR)
    		    lhs |= rhs;
            else {
//        		__assert_unreachable();
    	    }
    	    t = db_read_token();
    	}
    	db_unread_token(t);
    }

    function db_shift_expr() internal returns (bool, uint8) {
    	uint8 rhs;
        (bool f, uint8 lhs) = db_add_expr();
    	if (!f)
    	    return (false, 0);
    	byte t = db_read_token();
    	while (t == tSHIFT_L || t == tSHIFT_R) {
            (f, rhs) = db_add_expr();
    	    if (!f) {
    		    db_printf("Expression syntax error after '%s'\n", t == tSHIFT_L ? "<<" : ">>");
    		    db_error(NULL);
    		    /*NOTREACHED*/
    	    }
    	    if (rhs < 0) {
    		    db_printf("Negative shift amount %jd\n", rhs);
    		    db_error(NULL);
    		    /*NOTREACHED*/
    	    }
    	    if (t == tSHIFT_L)
    		    lhs <<= rhs;
    	    else {
    		    /* Shift right is unsigned */
    		    lhs = lhs >> rhs;
    	    }
    	    t = db_read_token();
    	}
    	db_unread_token(t);
    	return (true, lhs);
    }

    function db_logical_relation_expr() internal returns (bool, uint8) {
    	uint8 rhs;
        (bool f, uint8 lhs) = db_shift_expr();
    	if (!f)
    	    return (false, 0);
    	byte t = db_read_token();
    	while (t == tLOG_EQ || t == tLOG_NOT_EQ || t == tGREATER || t == tGREATER_EQ || t == tLESS || t == tLESS_EQ) {
            (f, rhs) = db_shift_expr();
    	    if (!f) {
    		    db_printf("Expression syntax error after '%s'\n",
    		        t == tLOG_EQ ? "==" : t == tLOG_NOT_EQ ? "!=" :
    		        t == tGREATER ? ">" : t == tGREATER_EQ ? ">=" :
    		        t == tLESS ? "<" : "<=");
    		    db_error(NULL);
    		    /*NOTREACHED*/
    	    }
    		if (t == tLOG_EQ)
    		    lhs = (lhs == rhs);
    		else if (t == tLOG_NOT_EQ)
    		    lhs = (lhs != rhs);
    		else if (t ==  tGREATER)
    		    lhs = (lhs > rhs);
    		else if (t == tGREATER_EQ)
    		    lhs = (lhs >= rhs);
    		else if (t == tLESS)
    		    lhs = (lhs < rhs);
    		else if (t == tLESS_EQ)
    		    lhs = (lhs <= rhs);
    		else
    		    __assert_unreachable();
    	    t = db_read_token();
    	}
    	db_unread_token(t);
    	return (true, lhs);
    }

    function db_logical_and_expr() internal returns (bool, uint8) {
    	uint8 rhs;
        (bool f, uint8 lhs) = db_logical_relation_expr();
    	if (!f)
    	    return (false, 0);
    	byte t = db_read_token();
    	while (t == tLOG_AND) {
            (f, rhs) = db_logical_relation_expr();
    	    if (!f) {
        		db_printf("Expression syntax error after '%s'\n", "&&");
        		db_error(NULL);
        		/*NOTREACHED*/
    	    }
    	    lhs = (lhs && rhs);
    	    t = db_read_token();
    	}
    	db_unread_token(t);
    	return (true, lhs);
    }

    function db_logical_or_expr() internal returns (bool, uint8) {
    	uint8 rhs;
        (bool f, uint8 lhs) = db_logical_and_expr();
    	if (!f)
    	    return (false, 0);
    	byte t = db_read_token();
    	while (t == tLOG_OR) {
            (f, rhs) = db_logical_and_expr();
    	    if (!f) {
    			db_printf("Expression syntax error after '%s'\n", "||");
    			db_error(NULL);
    			/*NOTREACHED*/
    		}
    		lhs = (lhs || rhs);
    		t = db_read_token();
    	}
    	db_unread_token(t);
    	return (true, lhs);
    }

    function db_expression() internal returns (bool, uint8) {
    	return db_logical_or_expr();
    }
}