pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract command is Shell {

    uint16 constant CDESC_ALL       = 1; // type -a
    uint16 constant CDESC_SHORTDESC = 2; // command -V
    uint16 constant CDESC_REUSABLE  = 4; // command -v
    uint16 constant CDESC_TYPE      = 8; // type -t
    uint16 constant CDESC_PATH_ONLY = 16; // type -p
    uint16 constant CDESC_FORCE_PATH= 32; // type -ap or type -P
    uint16 constant CDESC_NOFUNCS   = 64; // type -f

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool descr = arg.flag_set("v", flags);
        bool verbose = arg.flag_set("V", flags);
        for (string arg: params) {
            string t = vars.get_array_name(arg, pool);
            string value;
            if (t == "keyword")
                value = descr ? arg : (arg + " is a shell keyword");
            else if (t == "alias") {
                string val = vars.val(arg, pool);
                value = descr ? "alias " + arg + "=" + vars.wrap(val, vars.W_SQUOTE) : (arg + " is aliased to `" + val + "\'");
            } else if (t == "function")
                value = descr ? arg : (arg + " is a function\n" + vars.print_reusable(vars.get_pool_record(arg, pool)));
            else if (t == "builtin")
                value = descr ? arg : (arg + " is a shell builtin");
            else if (t == "command") {
                string path_map = vars.get_pool_record(arg, pool);
                string path;
                if (!path_map.empty())
                    (, path, ) = vars.split_var_record(path_map);
                if (!path.empty())
                    value = descr ? arg : (arg + " is hashed (" + path + "/" + arg + ")");
                else {
                    value = "/bin/" + arg;
                    if (verbose)
                        value = arg + " is " + value;
                }
            } else {
                ec = EXECUTE_FAILURE;
                if (verbose)
                    out.append("-tosh: command: " + arg + ": not found\n");
            }
            out.append(value + "\n");
        }
    }

    function _update_hash_table(string cmd, string comp_spec, string pool) internal pure returns (uint8 ec, string fn_name, string cs_res) {
        string fn_map = vars.get_pool_record(cmd, comp_spec);
        if (fn_map.empty()) {
            string commands = vars.get_map_value("command", pool);
            if (str.sstr(commands, " " + cmd + " ") > 0) {
                fn_name = "main";
                fn_map = vars.get_map_value(fn_name, comp_spec);
                string upd = vars.set_item_value(cmd, "0", fn_map);
                cs_res = stdio.translate(comp_spec, fn_map, upd);
            } else
                ec = EXECUTE_FAILURE;
        } else {
            (, fn_name, ) = vars.split_var_record(fn_map);
            uint16 hc = vars.int_val(cmd, fn_map);
            string upd = vars.set_item_value(cmd, str.toa(hc + 1), fn_map);
            cs_res = stdio.translate(comp_spec, fn_map, upd);
        }
    }

    function _export_env(string args, string pool) internal pure returns (string exports) {
        string s_attrs = "-x";
        (string[] lines, ) = stdio.split(pool, "\n");
        for (string line: lines) {
            (string attrs, ) = str.split(line, " ");
            if (vars.match_attr_set(s_attrs, attrs))
                exports.append(line + "\n");
        }
        exports.append(args);
    }

    function _export_env_ext(string args, string pool, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string exports) {
        string s_attrs = "-x";
        (string[] lines, ) = stdio.split(pool, "\n");
        for (string line: lines) {
            (string attrs, ) = str.split(line, " ");
            if (vars.match_attr_set(s_attrs, attrs))
                exports.append(line + "\n");
        }
        exports.append(args);
        (string[] params, ) = stdio.split(vars.val("PARAMS", args), " ");
        uint16 wd = vars.int_val("WD", pool);
        string f_dirents = _file_stati(params, wd, inodes, data);
        exports.append("-A [PARAM_INDEX]=" + vars.as_map(f_dirents));
    }

    function execute_command(string args, string page, string pool, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string exec_line, string exports, string cs_res) {
        string comp_spec = page;
        string cmd = vars.val("COMMAND", args);
        string s_args = vars.val("@", args);
        string fn_name;

        (ec, fn_name, cs_res) = _update_hash_table(cmd, comp_spec, pool);
        exports = _export_env_ext(args, pool, inodes, data);

        if (ec == EXECUTE_SUCCESS)
            exec_line = "./command " + fn_name + " " + cmd + " " + s_args;
        else
            exec_line = "echo Error executing command: " + cmd + ", args " + s_args;
    }

    function print_errors(string cmd, Err[] errors) external pure returns (string err) {
        return er.print_errors(cmd, errors);
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"command",
"[-pVv] command [arg ...]",
"Execute a simple command or display information about commands.",
"Runs COMMAND with ARGS suppressing  shell function lookup, or display information about the specified COMMANDs.  Can be used to invoke commands on disk when a function with the same name exists.",
"-p    use a default value for PATH that is guaranteed to find all of the standard utilities\n\
-v    print a description of COMMAND similar to the `type' builtin\n\
-V    print a more verbose description of each COMMAND",
"",
"Returns exit status of COMMAND, or failure if COMMAND is not found.");
    }
}
