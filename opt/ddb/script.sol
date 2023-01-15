// struct ddb_script describes an individual script.
struct ddb_script {
	char	ds_scriptname[DB_MAXSCRIPTNAME];
	char	ds_script[DB_MAXSCRIPTLEN];
}

contract script {

    /*
    // Global list of scripts -- defined scripts have non-empty name fields.
     */
    ddb_script[DB_MAXSCRIPTS] db_script_table;
    // While executing a script, we parse it using strsep(), so require a temporary buffer that may be used destructively.  Since we support weak
    // recursion of scripts (one may reference another), we need one buffer for each concurrently executing script.
    //static struct db_recursion_data {
    //	char	drd_buffer[DB_MAXSCRIPTLEN];
    //} db_recursion_data[DB_MAXSCRIPTRECURSION];
    uint8	db_recursion = 0;

    // We use a separate static buffer for script validation so that it is safe to validate scripts from within a script.  This is used only in
    // db_script_valid(), which should never be called reentrantly.
    byte[DB_MAXSCRIPTLEN]	db_static_buffer;

    // Some script names have special meaning, such as those executed automatically when KDB is entered.
    string constant DB_SCRIPT_KDBENTER_PREFIX	= "kdb.enter"; // KDB has entered
    string constant DB_SCRIPT_KDBENTER_DEFAULT	= "kdb.enter.default";

    // Find the existing script slot for a named script, if any.
    function ddb_script db_script_lookup(string scriptname) internal returns (ddb_script) {
    	for (uint i = 0; i < DB_MAXSCRIPTS; i++) {
    		if (strcmp(db_script_table[i].ds_scriptname, scriptname) == 0)
    			return (db_script_table[i]);
    	}
    	return NULL;
    }

    // Find a new slot for a script, if available.  Does not mark as allocated in any way--this must be done by the caller.
    function db_script_new() internal returns (ddb_script) {
    	for (uint i = 0; i < DB_MAXSCRIPTS; i++) {
    		if (strlen(db_script_table[i].ds_scriptname) == 0)
    			return (db_script_table[i]);
    	}
    	return NULL;
    }

    // Perform very rudimentary validation of a proposed script.  It would be easy to imagine something more comprehensive.  The script string is
    // validated in a static buffer.
    function db_script_valid(string scriptname, string script) internal returns (uint8) {
    	if (strlen(scriptname) == 0)
    		return EINVAL;
    	if (strlen(scriptname) >= DB_MAXSCRIPTNAME)
    		return EINVAL;
    	if (strlen(script) >= DB_MAXSCRIPTLEN)
    		return EINVAL;
    	string buffer = db_static_buffer;
    	strcpy(buffer, script);
    	while ((string command = strsep(buffer, ";")) != NULL) {
    		if (strlen(command) >= DB_MAXLINE)
    			return EINVAL;
    	}
    	return 0;
    }

    //  Modify an existing script or add a new script with the specified script name and contents.  If there are no script slots available, an error will
    //  be returned.
    function db_script_set(string scriptname, string script) internal returns (uint8 error) {
    	error = db_script_valid(scriptname, script);
    	if (error > 0)
    		return error;
    	ddb_script dsp = db_script_lookup(scriptname);
    	if (dsp == NULL) {
    		dsp = db_script_new();
    		if (dsp == NULL)
    			return ENOSPC;
    		strlcpy(dsp.ds_scriptname, scriptname, sizeof(dsp.ds_scriptname));
    	}
    	strlcpy(dsp.ds_script, script, sizeof(dsp.ds_script));
    	return 0;
    }

    // Delete an existing script by name, if found.
    function db_script_unset(string scriptname) internal returns (uint8) {
    	ddb_script dsp = db_script_lookup(scriptname);
    	if (dsp == NULL)
    		return ENOENT;
    	strcpy(dsp.ds_scriptname, "");
    	strcpy(dsp.ds_script, "");
    	return 0;
    }

    // Trim leading/trailing white space in a command so that we don't pass carriage returns, etc, into DDB command parser.
    function db_command_trimmable(byte ch) internal returns (uint8) {
    	if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r')
    		return 1;
    	else
            return 0;
    }

    function db_command_trim(bytes commandp) internal returns (bytes command) {
    	command = commandp;
    	while (db_command_trimmable(command))
    		command++;
    	while ((strlen(command) > 0) && db_command_trimmable(command[strlen(command) - 1]))
    		command[strlen(command) - 1] = 0;
    	//commandp = command;
    }

    // Execute a script, breaking it up into individual commands and passing them sequentially into DDB's input processing.  Use the KDB jump buffer to
    // restore control to the main script loop if things get too wonky when processing a command -- i.e., traps, etc.  Also, make sure we don't exceed
    // practical limits on recursion.
    function db_script_exec(string scriptname, bool warnifnotfound) internal returns (uint8) {
    	char *buffer, *command;
    	void *prev_jb;
    	jmp_buf jb;
    	ddb_script dsp = db_script_lookup(scriptname);
    	if (dsp == NULL) {
    		if (warnifnotfound)
    			db_printf("script '%s' not found\n", scriptname);
    		return ENOENT;
    	}
    	if (db_recursion >= DB_MAXSCRIPTRECURSION) {
    		db_printf("Script stack too deep\n");
    		return E2BIG;
    	}
    	db_recursion++;
    	db_recursion_data drd = db_recursion_data[db_recursion];
    	// Parse script in temporary buffer, since strsep() is destructive.
    	buffer = drd.drd_buffer;
    	strcpy(buffer, dsp.ds_script);
    	while ((command = strsep(&buffer, ";")) != NULL) {
    		db_printf("db:%d:%s> %s\n", db_recursion, dsp.ds_scriptname, command);
    		db_command_trim(command);
    		prev_jb = kdb_jmpbuf(jb);
    		if (setjmp(jb) == 0)
    			db_command_script(command);
    		else
    			db_printf("Script command '%s' returned error\n", command);
    		kdb_jmpbuf(prev_jb);
    	}
    	db_recursion--;
    	return 0;
    }

    // Wrapper for exec path that is called on KDB enter.  Map reason for KDB enter to a script name, and don't whine if the script doesn't exist.  If
    // there is no matching script, try the catch-all script.
    function db_script_kdbenter(string eventname) internal {
    	char scriptname[DB_MAXSCRIPTNAME];
    	snprintf(scriptname, sizeof(scriptname), "%s.%s", DB_SCRIPT_KDBENTER_PREFIX, eventname);
    	if (db_script_exec(scriptname, 0) == ENOENT)
    		db_script_exec(DB_SCRIPT_KDBENTER_DEFAULT, 0);
    }

    /*-
     * DDB commands for scripting, as reached via the DDB user interface:
     * scripts				- lists scripts
     * run <scriptname>			- run a script
     * script <scriptname>			- prints script
     * script <scriptname> <script>		- set a script
     * unscript <scriptname>		- remove a script
     */

    // List scripts and their contents.
    function db_scripts_cmd(uint8, bool, uint8 count, byte) internal {
    	for (uint i = 0; i < DB_MAXSCRIPTS; i++) {
    		if (strlen(db_script_table[i].ds_scriptname) != 0) {
    			db_printf("%s=%s\n", db_script_table[i].ds_scriptname, db_script_table[i].ds_script);
    		}
    	}
    }

    // Execute a script.
    function db_run_cmd(uint8 addr, bool, uint8, byte) internal {
    	// Right now, we accept exactly one argument.  In the future, we might want to accept flags and arguments to the script itself.
    	byte t = db_read_token();
    	if (t != tIDENT)
    		db_error("?\n");
    	if (db_read_token() != tEOL)
    		db_error("?\n");
    	db_script_exec(db_tok_string, 1);
    }

    // Print or set a named script, with the set portion broken out into its own function.  We must directly access the remainder of the DDB line input as
    // we do not wish to use db_lex's token processing.
    function db_script_cmd(uint8, bool, uint8, byte) internal {
    	char *buf, scriptname[DB_MAXSCRIPTNAME];
    	ddb_script dsp;
    	byte t = db_read_token();
    	if (t != tIDENT) {
    		db_printf("usage: script scriptname=script\n");
    		db_skip_to_eol();
    		return;
    	}
    	if (strlcpy(scriptname, db_tok_string, sizeof(scriptname)) >=
    	    sizeof(scriptname)) {
    		db_printf("scriptname too long\n");
    		db_skip_to_eol();
    		return;
    	}
    	t = db_read_token();
    	if (t == tEOL) {
    		dsp = db_script_lookup(scriptname);
    		if (dsp == NULL) {
    			db_printf("script '%s' not found\n", scriptname);
    			db_skip_to_eol();
    			return;
    		}
    		db_printf("%s=%s\n", scriptname, dsp.ds_script);
    	} else if (t == tEQ) {
    		buf = db_get_line();
    		if (buf[strlen(buf)-1] == '\n')
    			buf[strlen(buf)-1] = '\0';
    		uint8 error = db_script_set(scriptname, buf);
    		if (error > 0)
    			db_printf("Error: %d\n", error);
    	} else
    		db_printf("?\n");
    	db_skip_to_eol();
    }
    // Remove a named script.
    function db_unscript_cmd(uint8, bool, uint8, byte) internal {
    	byte t = db_read_token();
    	if (t != tIDENT) {
    		db_printf("?\n");
    		db_skip_to_eol();
    		return;
    	}
    	uint8 error = db_script_unset(db_tok_string);
    	if (error == ENOENT) {
    		db_printf("script '%s' not found\n", db_tok_string);
    		db_skip_to_eol();
    		return;
    	}
    	db_skip_to_eol();
    }

    /*
     * Sysctls for managing DDB scripting:
     *
     * debug.ddb.scripting.script      - Define a new script
     * debug.ddb.scripting.scripts     - List of names *and* scripts
     * debug.ddb.scripting.unscript    - Remove an existing script
     *
     * Since we don't want to try to manage arbitrary extensions to the sysctl
     * name space from the debugger, the script/unscript sysctls are a bit more
     * like RPCs and a bit less like normal get/set requests.  The ddb(8) command
     * line tool wraps them to make things a bit more user-friendly.
     */
    SYSCTL_NODE(_debug_ddb, OID_AUTO, scripting, CTLFLAG_RW | CTLFLAG_MPSAFE, 0, "DDB script settings");

    function sysctl_debug_ddb_scripting_scripts(SYSCTL_HANDLER_ARGS) internal returns (uint8 error) {
    	sbuf sb;
    	char *buffer;
    	// Make space to include a maximum-length name, = symbol, maximum-length script, and carriage return for every script that may be defined.
    	uint8 len = DB_MAXSCRIPTS * (DB_MAXSCRIPTNAME + 1 + DB_MAXSCRIPTLEN + 1);
    	buffer = malloc(len, M_TEMP, M_WAITOK);
    	sb.sbuf_new(buffer, len, SBUF_FIXEDLEN);
    	for (uint i = 0; i < DB_MAXSCRIPTS; i++) {
    		if (strlen(db_script_table[i].ds_scriptname) == 0)
    			continue;
    		sbuf_printf(&sb, "%s=%s\n", db_script_table[i].ds_scriptname, db_script_table[i].ds_script);
    	}
    	sb.sbuf_finish();
    	uint8 error = SYSCTL_OUT(req, sbuf_data(&sb), sbuf_len(&sb) + 1);
    	sb.sbuf_delete();
    	free(buffer, M_TEMP);
    	return error;
    }
    SYSCTL_PROC(_debug_ddb_scripting, OID_AUTO, scripts, CTLTYPE_STRING | CTLFLAG_RD | CTLFLAG_MPSAFE, 0, 0, sysctl_debug_ddb_scripting_scripts, "A", "List of defined scripts");

    function sysctl_debug_ddb_scripting_script(SYSCTL_HANDLER_ARGS) internal returns (uint8 error) {
    	char *buffer, *script, *scriptname;
    	// Maximum length for an input string is DB_MAXSCRIPTNAME + '=' symbol + DB_MAXSCRIPT.
    	uint8 len = DB_MAXSCRIPTNAME + DB_MAXSCRIPTLEN + 1;
    	buffer = malloc(len, M_TEMP, M_WAITOK | M_ZERO);
    	error = sysctl_handle_string(oidp, buffer, len, req);
    	if (error > 0) {
    	    free(buffer, M_TEMP);
    	    return error;
        }
    	// Argument will be in form scriptname=script, so split into the scriptname and script.
    	script = buffer;
    	scriptname = strsep(&script, "=");
    	if (script == NULL) {
    		error = EINVAL;
    	    free(buffer, M_TEMP);
    	    return error;
    	}
    	error = db_script_set(scriptname, script);
    	free(buffer, M_TEMP);
    	return error;
    }
    SYSCTL_PROC(_debug_ddb_scripting, OID_AUTO, script, CTLTYPE_STRING | CTLFLAG_RW | CTLFLAG_MPSAFE, 0, 0, sysctl_debug_ddb_scripting_script, "A", "Set a script");

    /*
     * debug.ddb.scripting.unscript has somewhat unusual sysctl semantics -- set
     * the name of the script that you want to delete.
     */
    function sysctl_debug_ddb_scripting_unscript(SYSCTL_HANDLER_ARGS) internal returns (uint8 error) {
    	char name[DB_MAXSCRIPTNAME];
    	bzero(name, sizeof(name));
    	error = sysctl_handle_string(oidp, name, sizeof(name), req);
    	if (error > 0)
    		return error;
    	if (req.newptr == NULL)
    		return 0;
    	error = db_script_unset(name);
    	if (error == ENOENT)
    		return EINVAL;	/* Don't confuse sysctl consumers. */
    	return 0;
    }
    SYSCTL_PROC(_debug_ddb_scripting, OID_AUTO, unscript, CTLTYPE_STRING | CTLFLAG_RW | CTLFLAG_MPSAFE, 0, 0, sysctl_debug_ddb_scripting_unscript, "A", "Unset a script");
}