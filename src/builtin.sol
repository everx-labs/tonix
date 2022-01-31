pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract builtin is Shell {

    function run_builtin(string args) external pure returns (string res) {
        string flags = vars.val("FLAGS", args);
        string cmd = vars.val("COMMAND", args);
        string s_args = vars.val("@", args);
        string params = vars.val("PARAMS", args);
        string ec = vars.val("?", args);
        string opterr = vars.val("OPTERR", args);

        (bool f_p, bool f_v, bool f_V, bool f_l, bool f_d, bool f_r, bool f_t, bool f_f) = arg.flag_values("pvVldrtf", flags);
        bool p_e = params.empty();
        if (ec == "1")
            return "echo error parsing command line";
        else if (ec == "2")
            return "echo " + opterr;

        string fn;
        string page = "pool";

        if (cmd == "builtin")
            return "./ty " + s_args;

        if (cmd == "declare" || cmd == "alias" || cmd == "readonly" || cmd == "export" || cmd == "set" || cmd == "complete" || cmd == "shopt")
            fn = f_p || p_e ? "print" : "modify";
        else if (cmd == "type" || cmd == "echo" || cmd == "pwd" || cmd == "compgen")
            fn = "print";
        else if (cmd == "exec")
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
            (bool v1, bool v2, bool v3, bool v4, bool v5, bool v6, bool v7, bool v8) = arg.flag_values("12345678", flags);
            if (params.empty()) fn = "print";
            else if (v1) fn = "v1";
            else if (v2) fn = "v2";
            else if (v3) fn = "v3";
            else if (v4) fn = "v4";
            else if (v5) fn = "v5";
            else if (v6) fn = "v6";
            else if (v7) fn = "v7";
            else if (v8) fn = "v8";
            else fn = "execute";
        } else if (cmd == "hash")
            fn = p_e || f_l ? "print" : f_d || f_r ? "modify" : f_t || flags.empty() ? "lookup" : "";
        else
            return "echo builtin: " + cmd + ": not a shell builtin";

        if (cmd == "alias" || cmd == "unalias")
            page = "aliases";
        else if (cmd == "hash")
            page = "hashes";
        else if (cmd == "shift")
            page = "pos_params";
        else if (cmd == "declare" || cmd == "export" || cmd == "readonly")
            page = f_f ? "functions" : fn == "print" ? "pool" : "vars";
        else if (cmd == "type")
            page = "pool";
        else if (cmd == "shopt")
            page = "shell_opts";
        else if (cmd == "echo" || cmd == "pwd" || cmd == "cd")
            page = "vars";
        else if (cmd == "dirs" || cmd == "pushd" || cmd == "popd")
            page = "dir_stack";
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
                    fj ? "jobs" :
                    fk ? "keywords" :
                    fs ? "services" :
                    fu ? "users" :
                    fv ? "vars" : "";
        }
        res = "./builtin " + cmd + " " + fn + " " + page + " " + s_args;
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
