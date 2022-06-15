pragma ton-solidity >= 0.61.0;

import "Shell.sol";

contract builtin is Shell {

    function main(svm sv_in, string args) external pure returns (svm sv, string res) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string cmd = vars.val("COMMAND", args);
        string sargs = vars.val("@", args);
        string fn;
        if (cmd == "type" || cmd == "echo" || cmd == "pwd" || cmd == "compgen" ||
            cmd == "declare" || cmd == "alias" || cmd == "readonly" || cmd == "export" || cmd == "set" || cmd == "complete" || cmd == "shopt" || cmd == "enable" || cmd == "exec" ||
            cmd == "help" || cmd == "cd" || cmd == "test" || cmd == "dirs" || cmd == "pushd" || cmd == "popd" ||
            cmd == "mapfile" || cmd == "read" || cmd == "source" ||
            cmd == "unset" || cmd == "unalias" || cmd == "shift" ||
            cmd == "command" || cmd == "ulimit") {

            fn = "main";
            }
        res = "./bin/eilish.dir/" + cmd + " " + sargs;
        sv.cur_proc = p;
    }

    function open_dictionary(svm sv_in, string args) external pure returns (svm sv, string res) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string cmd = vars.val("COMMAND", args);
        string sargs = vars.val("@", args);
        string fn;
        if (cmd == "type" || cmd == "echo" || cmd == "pwd" || cmd == "compgen")
            fn = "main";
        res = "./bin/eilish.dir/" + cmd + " " + fn + " " + sargs;
        sv.cur_proc = p;
    }

    function run_builtin(svm sv_in, string args, string builtins) external pure returns (svm sv, string res) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string flags = vars.val("FLAGS", args);
        string cmd = vars.val("COMMAND", args);
        string sargs = vars.val("@", args);
        string params = vars.val("PARAMS", args);
        string ec = vars.val("?", args);
        string opterr = vars.val("OPTERR", args);

        (bool f_p, bool f_v, bool f_V, bool f_l, bool f_d, bool f_r, bool f_t, bool f_f) = p.flag_values("pvVldrtf");
        bool p_e = params.empty();

        if (ec != "0")
            res = "echo " + (opterr.empty() ? "error parsing command line" : opterr);
        if (cmd == "builtin")
            res = "./ty " + sargs;

        string line = vars.get_pool_record(cmd, builtins);
        if (line.empty())
            res = "echo builtin: " + cmd + ": not a shell builtin";

        (string attrs, , string value) = vars.split_var_record(line);
        if (attrs.strchr("n") > 0)
            res = "echo builtin: " + cmd + "is disabled";

        string fn;
        if (cmd == "declare" || cmd == "alias" || cmd == "readonly" || cmd == "export" || cmd == "set" || cmd == "complete" || cmd == "shopt" || cmd == "enable" || cmd == "exec")
            fn = f_p || p_e ? "print" : "modify";
        else if (cmd == "type" || cmd == "echo" || cmd == "pwd" || cmd == "compgen" || cmd == "board")
            fn = "print";
        else if (cmd == "help")
            fn = "display_help";
        else if (cmd == "cd" || cmd == "test" || cmd == "dirs" || cmd == "pushd" || cmd == "popd")
            fn = "builtin_read_fs";
        else if (cmd == "mapfile" || cmd == "read" || cmd == "source")
            fn = "read_input";
        else if (cmd == "unset" || cmd == "unalias" || cmd == "shift")
            fn = "modify";
        else if (cmd == "command")
            fn = f_v || f_V ? "print" : "execute_command";
        else if (cmd == "ulimit") {
            (bool v1, , , , , , , ) = arg.flag_values("12345678", flags);
            if (params.empty()) fn = "print";
            else if (v1) fn = "v1";
            else fn = "execute";
        } else if (cmd == "hash")
            fn = p_e || f_l ? "print" : f_d || f_r ? "modify" : f_t || flags.empty() ? "lookup" : "";
        else
            res = "echo builtin: " + cmd + ": not a shell builtin";

        string page = "pool";
        if (!value.empty() && value.strchr(" ") == 0)
            page = value;
        if (cmd == "declare" || cmd == "export" || cmd == "readonly")
            page = f_f ? "functions" : fn == "print" ? "pool" : "vars";
        else if (cmd == "complete" || cmd == "compgen") {
            (bool fa, bool fb, bool fc, bool fd, bool fe, bool ff, bool fg, bool fj) = arg.flag_values("abcdefgj", flags);
            (bool fk, bool fs, bool fu, bool fv, , , , ) = arg.flag_values("ksuv", flags);
            page =  fa ? "aliases" :
                    fb ? "builtins" :
                    fc ? "comp_spec" :
                    fd ? "dir_cache" :
                    fe ? "export" :
                    ff ? "filenames" :
                    fg ? "groups" :
                    fj ? "job_list" :
                    fk ? "keywords" :
                    fs ? "services" :
                    fu ? "users" :
                    fv ? "vars" : "";
        }
        res = "./builtin " + cmd + " " + fn + " " + page + " " + sargs;
        sv.cur_proc = p;
    }

    function _get_arg_value_uint16(string arg) internal pure returns (uint16 ec, uint16 val) {
        optional(int) arg_val = stoi(arg);
        if (!arg_val.hasValue())
            ec = 1;
        else
            val = uint16(arg_val.get());
    }

    function _true() internal pure returns (uint16) {
        return 0;
    }

    function _false() internal pure returns (uint16) {
        return 1;
    }

    function _exit(string args) internal pure returns (uint16 ec) {
        uint16 arg_val;
        if (!args.empty())
            (ec, arg_val) = _get_arg_value_uint16(args);
        return ec > 0 ? ec : arg_val;
    }

    function _logout(string args) internal pure returns (uint16 ec) {
        uint16 arg_val;
        if (!args.empty())
            (ec, arg_val) = _get_arg_value_uint16(args);
        return ec > 0 ? ec : arg_val;
    }

    function _return(string args) internal pure returns (uint16 ec) {
        uint16 arg_val;
        if (!args.empty())
            (ec, arg_val) = _get_arg_value_uint16(args);
        return ec > 0 ? ec : arg_val;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"builtin",
"[shell-builtin [arg ...]]",
"Execute shell builtins.",
"Execute SHELL-BUILTIN with arguments ARGs without performing command lookup.",
"",
"",
"Returns the exit status of SHELL-BUILTIN, or false if SHELL-BUILTIN is not a shell builtin.");
    }

}
