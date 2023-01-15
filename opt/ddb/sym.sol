pragma ton-solidity >= 0.64.0;

import "output.sol";
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
struct db_variable {
	string name;    // Name of variable
	uint8 valuep;	// value of variable
	uint32 fcn;   // db_varfcn_t function to call when reading/writing
}
contract sym is output {
// Multiple symbol tables
    //#define	MAXNOSYMTABS	3	/* mach, ux, emulator */

    db_symtab[1]	db_symtabs;//[MAXNOSYMTABS] = {{0,},};
    uint8 db_nsymtab = 0;
    db_symtab	db_last_symtab; /* where last symbol was found */

    uint8 db_cpu = 0;

    // Validate the CPU number used to interpret per-CPU variables so we can avoid later confusion if an invalid CPU is requested.
    function db_var_db_cpu(db_variable vp, uint8 valuep, uint8 op) internal returns (bool, uint8) {
    	if (op == DB_VAR_GET)
    		return (true, db_cpu);
    	else if (op == DB_VAR_SET) {
    		if (valuep < 0 || valuep > mp_maxid) {
    			db_printf("Invalid value: %d\n", valuep);
    			return (false, 0);
    		}
    		db_cpu = valuep;
    		return (true, db_cpu);
        } else {
    		db_printf("db_var_db_cpu: unknown operation\n");
    		return (false, 0);
    	}
    }

    // Read-only variable reporting the current CPU, which is what we use when db_cpu is set to -1.
    function db_var_curcpu(db_variable vp, uint8 valuep, uint8 op) internal returns (bool, uint8)  {
    	if (op == DB_VAR_GET)
    		return (true, curcpu);
    	else if (op == DB_VAR_SET) {
    		db_printf("Read-only variable.\n");
    		return (false, 0);
        } else {
    		db_printf("db_var_curcpu: unknown operation\n");
    		return (false, 0);
    	}
    }

//    function  db_add_symbol_table(char *start, char *end, char *name, char *ref) {
    function db_add_symbol_table(uint32 start, uint32 end, string name, db_private _private ) internal {
    	if (db_nsymtab >= MAXNOSYMTABS) {
    		printf ("No slots left for %s symbol table", name);
    		panic ("db_sym.c: db_add_symbol_table");
    	}
    	db_symtabs[db_nsymtab].start = start;
    	db_symtabs[db_nsymtab].end = end;
    	db_symtabs[db_nsymtab].name = name;
    	db_symtabs[db_nsymtab]._private = ref;
    	db_nsymtab++;
    }

    //  db_qualify("vm_map", "ux") returns "unix:vm_map".
    //  Note: return value points to static data whose content is overwritten by each call... but in practice this seems okay.
    function db_qualify(uint8 ssym, string symtabname) internal returns (string) {
    	string symname;
    	bytes     tmp;//[256];
    	db_symbol_values(ssym, symname, 0);
    	snprintf(tmp, uint8(tmp.length), "%s:%s", symtabname, symname);
    	return tmp;
    }

    function db_eqname(string src, string dst, int c) internal returns (bool) {
    	if (!strcmp(src, dst))
    	    return true;
    	if (src[0] == c)
    	    return !strcmp(src+1,dst);
    	return false;
    }

    function db_value_of_name(string name, uint8 valuep) internal returns (bool, uint8 val) {
    	uint8 ssym = db_lookup(name);
    	if (ssym == C_DB_SYM_NULL)
    	    return false;
    	db_symbol_values(ssym, name, valuep);
    	return true;
    }

    function db_value_of_name_pcpu(string name, uint8 valuep) internal returns (bool, uint8) {
    	bytes tmp;//[256];
    	uint8	value;
    	uint8		cpu;
    	if (db_cpu != -1)
    		cpu = db_cpu;
    	else
    		cpu = curcpu;
    	snprintf(tmp, tmp.length, "pcpu_entry_%s", name);
    	uint8 ssym = db_lookup(tmp);
    	if (ssym == C_DB_SYM_NULL)
    		return (false, 0);
    	db_symbol_values(ssym, name, value);
    	if (value < DPCPU_START || value >= DPCPU_STOP)
    		return (false, 0);
    	valuep = (value + dpcpu_off[cpu]);
    	return (true, valuep);
    }

    function db_value_of_name_vnet(string, uint8) internal returns (bool) {
    	return false;
    }

    // Lookup a symbol. If the symbol has a qualifier (e.g., ux:vm_map), then only the specified symbol table will be searched;
    // otherwise, all symbol tables will be searched.
    function  db_lookup(string symstr) internal returns (uint8) {
    	uint8 sp;
    	uint8 i;
    	uint8 symtab_start = 0;
    	uint8 symtab_end = db_nsymtab;
    	string cp;
    	// Look for, remove, and remember any symbol table specifier.
       	for (cp = symstr; cp; cp++) {
    		if (cp == ':') {
    			for (i = 0; i < db_nsymtab; i++) {
    				uint8 n = strlen(db_symtabs[i].name);
    				if (n == (cp - symstr) && strncmp(symstr, db_symtabs[i].name, n) == 0) {
    					symtab_start = i;
    					symtab_end = i + 1;
    					break;
    				}
    			}
    			if (i == db_nsymtab)
    				db_error("invalid symbol table name");
    			symstr = cp+1;
    		}
    	}
    	// Look in the specified set of symbol tables. Return on first match.
    	for (i = symtab_start; i < symtab_end; i++) {
    		sp = X_db_lookup(db_symtabs[i], symstr);
    		if (sp) {
    			db_last_symtab = db_symtabs[i];
    			return sp;
    		}
    	}
    	return 0;
    }

    // If true, check across symbol tables for multiple occurrences of a name.  Might slow things down quite a bit.
    bool db_qualify_ambiguous_names = false;

    // Does this symbol name appear in more than one symbol table? Used by db_symbol_values to decide whether to qualify a symbol.
    function db_symbol_is_ambiguous(uint8 ssym) internal returns (bool) {
    	string sym_name;
    	bool	found_once = false;
    	if (!db_qualify_ambiguous_names)
    		return false;
    	db_symbol_values(ssym, sym_name, 0);
    	for (uint i = 0; i < db_nsymtab; i++) {
    		if (X_db_lookup(db_symtabs[i], sym_name)) {
    			if (found_once)
    				return true;
    			found_once = true;
    		}
    	}
    	return false;
    }

    // Find the closest symbol to val, and return its name and the difference between val and the symbol found.
    function db_search_symbol(uint8 val, uint8 strategy) internal returns (uint8 ret, uint8 offp) {
    	uint8 diff;
    	uint8		newdiff;
    	// The kernel will never map the first page, so any symbols in that range cannot refer to addresses.  Some third-party assembly files
    	// define internal constants which appear in their symbol table. Avoiding the lookup for those symbols avoids replacing small offsets
    	// with those symbols during disassembly.
    	if (val < PAGE_SIZE) {
    		return (C_DB_SYM_NULL, 0);
    	}
    	ret = C_DB_SYM_NULL;
    	newdiff = diff = val;
    	for (uint i = 0; i < db_nsymtab; i++) {
    	    uint8 ssym = X_db_search_symbol(db_symtabs[i], val, strategy, newdiff);
    	    if (newdiff < diff) {
    		    db_last_symtab = db_symtabs[i];
    		    diff = newdiff;
    		    ret = ssym;
    	    }
    	}
    	return (ret, diff);
    }

    // Return name and value of a symbol
    function db_symbol_values(uint8 ssym, string namep, uint8 valuep) internal  {
    	uint8	value;
    	if (ssym == DB_SYM_NULL) {
    		namep = NULL;
    		return;
    	}
    	X_db_symbol_values(db_last_symtab, ssym, namep, value);
    	if (db_symbol_is_ambiguous(ssym))
    		namep = db_qualify(ssym, db_last_symtab.name);
    	if (valuep)
    		valuep = value;
    }

    // Print a the closest symbol to value. After matching the symbol according to the given strategy we print it in the name+offset format,
    // provided the symbol's value is close enough (eg smaller than db_maxoff). We also attempt to print [filename:linenum] when applicable
    // (eg for procedure names). If we could not find a reasonable name+offset representation,  then we just print the value in hex.
    // Small values might get  bogus symbol associations, e.g. 3 might get some absolute value like _INCLUDE_VERSION or something, therefore we do
    // not accept symbols whose value is "small" (and use plain hex).
    uint16	db_maxoff = 0x10000;
    function db_printsym(uint8 off, uint8 strategy) internal {
    	uint8	d;
    	string filename;
    	string name;
    	uint8 linenum;

    	if (off < 0 && off >= -db_maxoff) {
    		db_printf("%+#lr", off);
    		return;
    	}
    	uint8 cursym = db_search_symbol(off, strategy, d);
    	db_symbol_values(cursym, name, NULL);
    	if (name == NULL || d >= db_maxoff) {
    		db_printf("%#lr", off);
    		return;
    	}
    	db_printf("%s", name);
    	if (d)
    		db_printf("+%+#lr", d);
    	if (strategy == DB_STGY_PROC) {
    		if (db_line_at_pc(cursym, filename, linenum, off))
    			db_printf(" [%s:%d]", filename, linenum);
    	}
    }

    function db_line_at_pc(uint8 ssym, string filename, uint8 linenum, uint8 pc) internal returns (bool) {
    	return X_db_line_at_pc(db_last_symtab, ssym, filename, linenum, pc);
    }

    function db_sym_numargs(uint8 ssym, uint8 nargp, string[] argnames) internal returns (bool) {
    	return X_db_sym_numargs(db_last_symtab, ssym, nargp, argnames);
    }
}