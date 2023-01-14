pragma ton-solidity >= 0.64.0;

struct db_variable {
	string name;    // Name of variable
	uint8 valuep;	// value of variable
	uint32 fcn;   // db_varfcn_t function to call when reading/writing
}

contract variables {

    uint8 constant DB_VAR_GET =	0;
    uint8 constant DB_VAR_SET =	1;

    //#define	FCN_NULL	((db_varfcn_t *)0)

    db_variable[] db_vars;
    db_variable db_evars = db_vars + nitems(db_vars);

    function init_db_vars() internal {
    	db_vars = [
        db_variable("radix",	db_radix, FCN_NULL),
    	db_variable("maxoff",	db_maxoff, FCN_NULL),
    	db_variable("maxwidth",	db_max_width, FCN_NULL),
    	db_variable("tabstops",	db_tab_stop_width, FCN_NULL),
    	db_variable("lines",	db_lines_per_page, FCN_NULL),
    	db_variable("curcpu",	NULL, db_var_curcpu),
    	db_variable("db_cpu",	NULL, db_var_db_cpu)];
        db_evars = db_vars + nitems(db_vars);
    }
    function db_find_variable() internal returns (bool, db_variable) {
    	uint8 t = db_read_token();
    	if (t == tIDENT) {
    		for (db_variable vp = db_vars; vp < db_evars; vp++) {
    			if (!strcmp(db_tok_string, vp.name))
    				return (true, vp);
    		}
    		for (db_variable vp = db_regs; vp < db_eregs; vp++) {
    			if (!strcmp(db_tok_string, vp.name))
    				return (true, vp);
    		}
    	}
    	db_error("Unknown variable\n");
    }

    function db_get_variable() internal returns (bool, uint8) {
    	(bool success, db_variable vp) = db_find_variable();
        if (!success)
            return (false, 0);
    	return db_read_variable(vp);
    }

    function db_set_variable(uint8 value) internal returns (bool) {
    	(bool success, db_variable vp) = db_find_variable();
        if (!success)
            return false;
    	return db_write_variable(vp, value);
    }
    function db_read_variable(db_variable vp) internal returns (bool, uint8) {
    	db_varfcn_t func = vp.fcn;
    	if (func == FCN_NULL) {
    		return (true, vp.valuep);
    	}
    	return ((func)(vp, DB_VAR_GET));
    }

    function db_write_variable(db_variable vp, db_expr_t value) internal returns (bool) {
    	uint32 func = vp.fcn;
    	if (func == FCN_NULL) {
    		vp.valuep = value;
    		return true;
    	}
    	return func(vp, value, DB_VAR_SET);
    }

    function db_set_cmd(uint8, bool, uint8, bytes) internal {
    	db_variable vp;
    	db_expr_t value;
    	byte t = db_read_token();
    	if (t == tEOL) {
    		for (vp = db_vars; vp < db_evars; vp++) {
    			if (!db_read_variable(vp, value)) {
    				db_printf("$%s\n", vp.name);
    				continue;
    			}
    			db_printf("$%-8s = %ld\n", vp.name, value);
    		}
    		return;
    	}
    	if (t != tDOLLAR) {
    		db_error("Unknown variable\n");
    		return;
    	}
    	if (!db_find_variable(vp)) {
    		db_error("Unknown variable\n");
    		return;
    	}
    	t = db_read_token();
    	if (t != tEQ)
    		db_unread_token(t);
    	if (!db_expression(value)) {
    		db_error("No value\n");
    		return;
    	}
    	if (db_read_token() != tEOL)
    		db_error("?\n");
    	db_write_variable(vp, value);
    }

}