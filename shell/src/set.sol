pragma ton-solidity >= 0.54.0;

import "Shell.sol";

contract set is Shell {

    function show(En e) external pure returns (string out) {
        for (Item i: e.aliases)
            out.append("alias " + i.name + "=" + _wrap(i.value, W_SQUOTE) + "\n");
    }

    function _item_attr_index(string s_attrs, string name, Item[] map) internal pure returns (uint) {
        for (uint i = 0; i < map.length; i++)
            if (map[i].name == name && _match_attr_set(s_attrs, _mask_str(map[i].attrs)))
                return i + 1;
    }

    /*function add(string kind, string content, Item[] pagr) external pure returns (En en) {
        en = e;
        Item[] page;
        if (kind == "alias")
            page = e.aliases;
        else if (kind == "function")
            page = e.functions;
        else if (kind == "builtin")
            page = e.builtins;
        else if (kind == "variable")
            page = e.variables;
        else if (kind == "command")
            page = e.commands;
        else if (kind == "keyword")
            page = e.keywords;
    }*/


    function _print(string s_attrs, string content, Item[] page) internal pure returns (string out) {
        if (content.empty()) {
            for (Item i: page) {
                (string name, uint16 mask, string value) = i.unpack();
                if (name.empty())
                    continue;
                string attrs = _mask_str(mask);
                if (_match_attr_set(s_attrs, attrs)) {
                    if ((mask & ATTR_FUNCTION) > 0)
                        out.append(name + " ()\n{\n" + _indent(_translate(_unwrap(value), ";", "\n"), 4, "\n") + "}\n");
                    else
                        out.append(attrs + " " + name + "=" + value + "\n");
                }
            }
        }
    }

    /*function _add(string s_attrs, string content, Item[] page) internal pure returns (Item[] res) {
        res = page;
        uint16 mask = _get_mask_ext(s_attrs);
        (string[] lines, uint n_lines) = _split(content, "\n");
        for (string line: lines) {
            (string attrs, string stmt) = _strsplit(line, " ");
            (string name, string value) = _strsplit(stmt, "=");
            Item item = Item(name, mask, value);
            uint index = _item_attr_index(s_attrs, name, page);
            if (index == 0)
                res.push(item);
            else
                res[index - 1] = item;
        }
    }*/

    /*function print(string s_attrs, string content, Item[] page) external pure returns (string out) {
        return _print(s_attrs, content, page);
    }*/

    /*function add(string s_attrs, string content, Item[] page) external pure returns (Item[] res) {
        return _add(s_attrs, content, page);
    }*/

    function imprt(string content) external pure returns (Item[] res) {
        (string[] lines, ) = _split(content, "\n");
        for (string line: lines) {
            if (line.empty())
                continue;
            (string attrs, string stmt) = _strsplit(line, " ");
            (string name, string value) = _strsplit(stmt, "=");
            if (_strchr(name, "[") > 0)
                name = _unwrap(name);
            if (!value.empty()) {
                if (_strchr(value, "\"") > 0)
                    value = _unwrap(value);
            }
            uint16 mask = _get_mask_ext(attrs);
            Item item = Item(name, mask, value);
            res.push(item);
        }
    }

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = _get_args(args);
        ec = EXECUTE_SUCCESS;
        if (params.empty()) {
            out.append(pool + "\n");
        } else {
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"set",
"[-abefhkmnptuvxBCHP] [--] [arg ...]",
"Set or unset values of shell options and positional parameters.",
"Change the value of shell attributes and positional parameters, or display the names and values of shell variables.",
"-a  Mark variables which are modified or created for export.\n\
-b  Notify of job termination immediately.\n\
-e  Exit immediately if a command exits with a non-zero status.\n\
-f  Disable file name generation (globbing).\n\
-h  Remember the location of commands as they are looked up.\n\
-k  All assignment arguments are placed in the environment for a command, not just those that precede the command name.\n\
-m  Job control is enabled.\n\
-n  Read commands but do not execute them.\n\
-p  Turned on whenever the real and effective user ids do not match. Disables processing of the $ENV file and importing\n\
    of shell functions.  Turning this option off causes the effective uid and gid to be set to the real uid and gid.\n\
-t  Exit after reading and executing one command.\n\
-u  Treat unset variables as an error when substituting.\n\
-v  Print shell input lines as they are read.\n\
-x  Print commands and their arguments as they are executed.\n\
-B  the shell will perform brace expansion\n\
-C  If set, disallow existing regular files to be overwritten by redirection of output.\n\
-E  If set, the ERR trap is inherited by shell functions.\n\
-H  Enable ! style history substitution.  This flag is on by default when the shell is interactive.\n\
-P  If set, do not resolve symbolic links when executing commands such as cd which change the current directory.\n\
-T  If set, the DEBUG and RETURN traps are inherited by shell functions.\n\
--  Assign any remaining arguments to the positional parameters. If there are no remaining arguments, the positional\n\
    parameters are unset.\n\
-   Assign any remaining arguments to the positional parameters. The -x and -v options are turned off.",
"Using + rather than - causes these flags to be turned off. The flags can also be used upon invocation of the shell.\n\
The current set of flags may be found in $-. The remaining n ARGs are positional parameters and are assigned, in order,\n\
to $1, $2, .. $n. If no ARGs are given, all shell variables are printed.",
"Returns success unless an invalid option is given.");
    }
}
