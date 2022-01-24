pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract builtin is Shell {

    function _item_val(string name, Item[] coll) internal pure returns (string) {
        for (Item i: coll)
            if (i.name == name)
                return i.value;
    }

    function run_builtin(string args) external pure returns (string res) {
        string flags = vars.val("FLAGS", args);
        string cmd = vars.val("COMMAND", args);
        string s_args = vars.val("@", args);
        string params = vars.val("PARAMS", args);
        string ec = vars.val("?", args);
        string opterr = vars.val("OPTERR", args);

        if (ec == "1")
            return "echo error parsing command line";
        else if (ec == "2")
            return "echo " + opterr;

        string fn;
        string page = "pool";

        if (cmd == "builtin")
            return "./ty " + s_args;

        if (cmd == "declare" || cmd == "alias" || cmd == "readonly" || cmd == "export" || cmd == "set" || cmd == "complete") {
            if (arg.flag_set("p", flags) || params.empty())
                fn = "print";
            else
                fn = "modify";
        } else if (cmd == "type" || cmd == "echo" || cmd == "pwd")
            fn = "print";
        else if (cmd == "help")
            fn = "display_help";
        else if (cmd == "cd" || cmd == "test" || cmd == "dirs" || cmd == "pushd" || cmd == "popd")
            fn = "builtin_read_fs";
        else if (cmd == "mapfile" || cmd == "read" || cmd == "source")
            fn = "read_input";
        else if (cmd == "unset" || cmd == "unalias" || cmd == "shift")
            fn = "modify";
        else if (cmd == "command") {
            if (arg.flag_set("v", flags) || arg.flag_set("V", flags))
                fn = "print";
            else
                fn = "execute_command";
        } else if (cmd == "ulimit") {
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
        } else if (cmd == "hash") {
            if (params.empty() || arg.flag_set("l", flags))
                fn = "print";
            else if (arg.flag_set("d", flags) || arg.flag_set("r", flags) )
                fn = "modify";
            else if (arg.flag_set("t", flags) || flags.empty())
                fn = "lookup";
        }

        if (cmd == "alias" || cmd == "unalias")
            page = "aliases";
        else if (cmd == "hash")
            page = "hashes";
        else if (cmd == "shift")
            page = "pos_params";
        else if (cmd == "declare" || cmd == "export" || cmd == "readonly") {
            if (arg.flag_set("f", flags))
                page = "functions";
            else if (fn == "print")
                page = "pool";
            else
                page = "vars";
        } else if (cmd == "type")
            page = "pool";
        else if (cmd == "echo" || cmd == "pwd" || cmd == "cd")
            page = "vars";
        else if (cmd == "dirs" || cmd == "pushd" || cmd == "popd")
            page = "dir_stack";

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
