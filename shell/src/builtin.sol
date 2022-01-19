pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract builtin is Shell {

    function _match_function_comp_spec(string cmd, string flags, string comp_spec) internal pure returns (string) {
        (string[] lines, ) = _split(comp_spec, "\n");
        for (string line: lines) {
            if (_strstr(line, " " + cmd + " ") > 0) {
                (string fn_attrs, string fn_name, ) = _split_var_record(line);
                if (_match_attr_set(fn_attrs, flags))
                    return fn_name;
            }
        }
    }

    function _item_val(string name, Item[] coll) internal pure returns (string) {
        for (Item i: coll)
            if (i.name == name)
                return i.value;
    }

    function run_builtin(Item[] annotation) external pure returns (string res) {
        string flags = _item_val("FLAGS", annotation);
        string cmd = _item_val("COMMAND", annotation);
        string s_args = _item_val("@", annotation);
        string params = _item_val("PARAMS", annotation);
        string ec = _item_val("?", annotation);
        string opterr = _item_val("OPTERR", annotation);

        if (ec == "1")
            return "echo error parsing command line";
        else if (ec == "2")
            return "echo " + opterr;

        string fn;
        string page = "pool";

        if (cmd == "declare" || cmd == "alias" || cmd == "readonly" || cmd == "export" || cmd == "set" || cmd == "complete") {
            if (_flag_set("p", flags) || params.empty())
                fn = "print";
            else
                fn = "modify";
        } else if (cmd == "type" || cmd == "echo" || cmd == "pwd") {
            fn = "print";
        } else if (cmd == "help") {
            fn = "display_help";
        } else if (cmd == "cd" || cmd == "test") {
            fn = "builtin_read_fs";
        } else if (cmd == "mapfile" || cmd == "read" || cmd == "source") {
            fn = "read_input";
        } else if (cmd == "unset" || cmd == "unalias" || cmd == "shift") {
            fn = "modify";
        } else if (cmd == "command") {
            if (_flag_set("v", flags) || _flag_set("V", flags))
                fn = "print";
            else
                fn = "execute_command";
        } else if (cmd == "ulimit") {
            (bool v1, bool v2, bool v3, bool v4, bool v5, bool v6, bool v7, bool v8) = _flag_values("12345678", flags);
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
            if (params.empty() || _flag_set("l", flags))
                fn = "print";
            else if (_flag_set("d", flags) || _flag_set("r", flags) )
                fn = "modify";
            else if (_flag_set("t", flags) || flags.empty())
                fn = "lookup";
        }

        if (cmd == "alias" || cmd == "unalias")
            page = "aliases";
        else if (cmd == "hash")
            page = "hashes";
        else if (cmd == "shift")
            page = "pos_params";
        else if (cmd == "declare" || cmd == "export" || cmd == "readonly") {
            if (_flag_set("f", flags))
                page = "functions";
            else if (fn == "print")
                page = "pool";
            else
                page = "vars";
        } else if (cmd == "type")
            page = "pool";
        else if (cmd == "echo" || cmd == "pwd" || cmd == "cd")
            page = "vars";

        string exec_path = "builtin";
        string exec_line = "./" + exec_path + " " + cmd + " " + fn + " " + page + " " + s_args;
        res = exec_line;
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
