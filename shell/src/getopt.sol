pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract getopt is Utility {

    struct CommandInfo {
        uint8 min_args;
        uint16 max_args;
        string options;
        string name;
    }

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        err = "";
        ( , string[] params, string flags, ) = arg.get_env(argv);
        ec = EXECUTE_SUCCESS;
        uint p = stdio.strrchr(s_input, ">");
        uint q = stdio.strrchr(s_input, "<");
        (string c, string s_args) = stdio.strsplit(s_input, " ");
        string out_redirect = p > 0 ? stdio.strtok(s_input, p, " ") : "";
        string in_redirect = q > 0 ? stdio.strtok(s_input, q, " ") : "";
        string[] args;
        string short_options;
        string[] long_options;
        uint16 action;
        if (!s_args.empty())
            (args, short_options, long_options) = _parse_args(s_args);

        if (c != command_info.name)
            parse_errors.push(Err(command_not_found, 0, c));
        else {
            uint flags = _parse_short_options(short_options);
            if (args.empty()) {
                if (c == "du" || c == "ls" || c == "df")
                    args.push(".");
                if (c == "cd")
                    args.push("~");
            }
            if (c == "ln" && args.length == 1)
                args.push(".");

            parse_errors = _check_args(c, command_info, short_options, args);

            source = in_redirect;
            target = out_redirect;

            if (!parse_errors.empty())
                action = ACT_PRINT_ERRORS;

            for (string s: long_options) {
                if (s == "help") action = ACT_PRINT_USAGE;
                if (s == "version") action = ACT_PRINT_VERSION;
            }
        }
    }

    function _action_function(uint16 action) internal pure returns (string) {
        if (action == ACT_PRINT_USAGE) return "usage";
        if (action == ACT_PRINT_VERSION) return "version";
        return "exec";
    }

    function _is_pure_s(string c) internal pure returns (bool) {
        return c == "basename" || c == "dirname" || c == "echo" || c == "pathchk" || c == "uname";
    }

    function _op_stat_s(string c) internal pure returns (bool) {
        return c == "cksum" || c == "du" || c == "file" || c == "ls" || c == "namei" || c == "stat";
    }

    function _op_format_s(string c) internal pure returns (bool) {
        return c == "cat" || c == "colrm" || c == "column" || c == "cut" || c == "expand" || c == "grep" || c == "head" || c == "look"
           || c == "mapfile" || c == "more" || c == "paste" || c == "rev" || c == "tail" || c == "tr" || c == "unexpand" || c == "wc";
    }

    function _op_fs_status_s(string c) internal pure returns (bool) {
        return c == "cksum" || c == "du" || c == "file" || c == "ls" || c == "stat";
    }

    function _op_dev_stat_s(string c) internal pure returns (bool) {
        return c == "df" || c == "findmnt" || c == "lsblk" || c == "mountpoint" || c == "ps" || c == "utmpdump";
    }

    function _op_dev_admin_s(string c) internal pure returns (bool) {
        return c == "losetup" || c == "mknod" || c == "mount" || c == "udevadm" || c == "umount";
    }

    function _op_access_s(string c) internal pure returns (bool) {
        return c == "chgrp" || c == "chmod" || c == "chown";
    }

    function _op_file_s(string c) internal pure returns (bool) {
        return c == "cp" || c == "cmp" || c == "dd" || c == "fallocate" || c == "ln" || c == "mkdir" || c == "mv" || c == "rm"
           || c == "rmdir" || c == "tar" || c == "touch" || c == "truncate";
    }

    function _op_file_action_s(string c) internal pure returns (bool) {
        return c == "cp" || /*c == "cmp" || c == "dd" || */c == "fallocate" || c == "ln" || c == "mkdir" || c == "mv" || c == "rm"
           || c == "rmdir" || c == "tar" || c == "touch" || c == "truncate";
    }

    function _op_session_s(string c) internal pure returns (bool) {
        return c == "cd" || c == "id" || c == "login" || c == "logout" || c == "last" || c == "pwd" || c == "script" || c == "who" || c == "whoami";
    }

    function _op_user_access_s(string c) internal pure returns (bool) {
        return c == "login" || c == "logout";
    }

    function _op_network_s(string c) internal pure returns (bool) {
        return c == "account" || c == "mount" || c == "ping";
    }

    function _op_user_admin_s(string c) internal pure returns (bool) {
        return c == "gpasswd" || c == "groupadd" || c == "groupdel" || c == "groupmod" || c == "useradd" || c == "userdel" || c == "usermod";
    }

    function _op_user_stats_s(string c) internal pure returns (bool) {
        return c == "finger" || c == "last" || c == "lslogins" || c == "utmpdump" || c == "who";
    }

    function _reads_file_fixed_s(string c) internal pure returns (bool) {
        return c == "help" || c == "man" || c == "whatis" || c == "whereis";
    }

    function _parse_args(string s_args) internal pure returns (string[] args, string short_options, string[] long_options) {
        (string[] tokens, ) = stdio.split(s_args, " ");
        bool discard_next = false;
//        for (uint i = 0; i < count; i++) {
//            string token = tokens[i];
        for (string token: tokens) {
            uint len = token.byteLength();
            if (len == 0 || discard_next)
                continue;
            string s1 = token.substr(0, 1);
            if (s1 == ">" || s1 == "<") {
                discard_next = true;
                continue;
            }
            if (s1 == "-" && len > 1) {
                if (token.substr(1, 1) == "-") {
                    if (len > 2)
                        long_options.push(token.substr(2));
                } else
                    short_options.append(token.substr(1));
            } else
                args.push(token);
        }
    }

    function _check_args(string command_s, CommandInfo ci, string short_options, string[] args) private pure returns (Err[] errors) {
        uint16 n_args = uint16(args.length);
        string extra_flags;
        uint short_options_len = short_options.byteLength();
        string possible_options = ci.options;
        for (uint i = 0; i < short_options_len; i++) {
            string actual_option = short_options.substr(i, 1);
            uint p = stdio.strchr(possible_options, actual_option);
            if (p == 0)
                extra_flags.append(actual_option);
        }

        if (n_args < ci.min_args)
            errors.push(Err(missing_file_operand, 0, command_s));
        if (n_args > ci.max_args)
            errors.push(Err(extra_operand, 0, args[ci.max_args]));
        if (!extra_flags.empty())
            errors.push(Err(invalid_option, 0, extra_flags));
        if (!errors.empty())
            errors.push(Err(try_help_for_info, 0, command_s));
    }

    function _parse_short_options(string short_options) private pure returns (uint flags) {
        bytes opts = bytes(short_options);
        for (uint i = 0; i < opts.length; i++)
            flags |= uint(1) << uint8(opts[i]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"getopt",
"optstring parameters",
"parse command options",
"Break up (parse) options in command lines for easy parsing by shell procedures.",
"-o      the short options to be recognized\n\
-q      disable error reporting by getopt(3)\n\
-Q      no normal output\n\
-T      test for getopt(1) version\n\
-u      do not quote the output",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
