pragma ton-solidity >= 0.62.0;

import "Shell.sol";
import "libshellenv.sol";
import "libjobcommand.sol";

contract help is Shell {
    using libshellenv for shell_env;
    using libjobcommand for job_cmd;
    function main(shell_env e_in, BuiltinHelp[] help_files, job_cmd cc_in) external pure returns (shell_env e, job_cmd cc) {
        e = e_in;
        cc = cc_in;

        string[] args = cc.params();
        uint8 command_format = _get_help_format(cc);

        if (args.empty())
            e.puts(_print_help_msg(help_files));

        for (string arg: args) {
            (uint8 t_ec, BuiltinHelp help_file) = _get_help_file(arg, help_files);
            e.puts(t_ec == EXECUTE_SUCCESS ?
                _help_cmd(command_format, help_file) :
                "-eilish: help: no help topics match `" + arg + "'.  Try `help help' or `info " + arg + "'.");
        }
    }

    uint8 constant COMMAND_FORMAT_DESCRIPTION       = 1;
    uint8 constant COMMAND_FORMAT_SYNOPSIS          = 2;
    uint8 constant COMMAND_FORMAT_DEFAULT           = 3;
    uint8 constant COMMAND_FORMAT_PSEUDO_MAN_PAGE   = 4;
    uint8 constant COMMAND_FORMAT_MAN_PAGE          = 5;
    uint8 constant COMMAND_FORMAT_DASH_DASH_HELP    = 6;
    uint8 constant COMMAND_FORMAT_WHATIS            = 7;
    uint8 constant COMMAND_FORMAT_APROPOS           = 8;

    function _get_help_format(job_cmd cc) internal pure returns (uint8 command_format) {
        command_format = COMMAND_FORMAT_DEFAULT;
        if (cc.flag_set("d"))
            command_format = COMMAND_FORMAT_DESCRIPTION;
        if (cc.flag_set("s"))
            command_format = COMMAND_FORMAT_SYNOPSIS;
        if (cc.flag_set("m"))
            command_format = COMMAND_FORMAT_PSEUDO_MAN_PAGE;
    }

    function _get_help_file(string arg, BuiltinHelp[] help_files) internal pure returns (uint8 ec, BuiltinHelp help_file) {
        ec = EXECUTE_FAILURE;
        for (BuiltinHelp bh: help_files)
            if (bh.name == arg)
                return (EXECUTE_SUCCESS, bh);

        if (arg == "true" || arg == "false" || arg == "logout" || arg == "exit" || arg == "return")
            return (EXECUTE_SUCCESS, _get_command_info(arg));
    }

    function _print_help_msg(BuiltinHelp[] help_files) internal pure returns (string out) {
        for (BuiltinHelp bh: help_files)
            out.append(bh.name + " " + bh.synopsis + "\n");
    }

    function _help_cmd(uint8 command_format, BuiltinHelp bh) internal pure returns (string out) {
        (string name, string synopsis, string purpose, string description, string options, string arguments, string exit_status) = bh.unpack();
        if (command_format < COMMAND_FORMAT_DESCRIPTION)
            return "";
        else if (command_format == COMMAND_FORMAT_DESCRIPTION)
            return name + " - " + purpose + "\n";
        else if (command_format == COMMAND_FORMAT_SYNOPSIS)
            return name + ": " + name + " " + synopsis + "\n";

        string help_text = libstring.join_fields([
            purpose,
            description,
            "Options:\n" + fmt.indent(options, 2, "\n"),
            fmt.indent(arguments, 0, "\n"),
            "Exit Status:\n" + fmt.indent(exit_status, 0, "\n")], "\n\n");

        if (command_format == COMMAND_FORMAT_DEFAULT)
            return fmt.format_list(name + ": " + name + " " + synopsis, help_text);

        if (command_format == COMMAND_FORMAT_PSEUDO_MAN_PAGE)
            return libstring.join_fields([
                fmt.format_list("NAME", name + " - " + purpose),
                fmt.format_list("SYNOPSIS", name + " " + synopsis),
                fmt.format_list("DESCRIPTION", help_text),
                fmt.format_list("SEE ALSO", "eilish(1)"),
                fmt.format_list("IMPLEMENTATION", "in progress")], "\n");
    }

    function _get_command_info(string c) internal pure returns (BuiltinHelp) {
        if (c == "true") return BuiltinHelp(c, "", "Return a successful result.", "", "", "", "Always succeeds.");
        else if (c == "false") return BuiltinHelp(c, "", "Return an unsuccessful result.", "", "", "", "Always fails.");
        else if (c == "logout") return BuiltinHelp(c, "[n]", "Exit a login shell.",
            "Exits a login shell with exit status N.  Returns an error if not executed in a login shell.", "", "", "");
        else if (c == "exit") return BuiltinHelp(c, "[n]", "Exit the shell.",
            "Exits the shell with a status of N.  If N is omitted, the exit status is that of the last command executed.", "", "", "");
        else if (c == "return") return BuiltinHelp(c, "[n]", "Return from a shell function.",
            "Causes a function or sourced script to exit with the return value specified by N.  If N is omitted, the return status is that of the last command executed within the function or script.",
            "", "", "Returns N, or failure if the shell is not executing a function or script.");
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
"help",
"[-dms] [pattern ...]",
"Display information about builtin commands.",
"Displays brief summaries of builtin commands. If PATTERN is specified, gives detailed help on all commands\n\
matching PATTERN, otherwise the list of help topics is printed.",
"-d        output short description for each topic\n\
-m        display usage in pseudo-manpage format\n\
-s        output only a short usage synopsis for each topic matching PATTERN",
"Arguments:\n\
  PATTERN   Pattern specifying a help topic",
"Returns success unless PATTERN is not found or an invalid option is given.");
    }
}
