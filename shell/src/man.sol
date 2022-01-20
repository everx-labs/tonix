pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract man is Utility {

    function display_man_page(string args, CommandHelp[] help_files) external pure returns (uint8 ec, string out) {
        (string[] params, string flags,) = _get_args(args);
        string opt_args = _get_map_value("OPT_ARGS", args);
        uint8 command_format = 1;
        if (!_val("help", opt_args).empty())
            command_format = 2;
        else if (!_val("version", opt_args).empty())
            command_format = 3;

        if (params.empty())
            out.append("What manual page do you want?\nFor example, try 'man man'.");
        for (string arg: params) {
            (uint8 t_ec, CommandHelp help_file) = _get_man_file(arg, help_files);
            ec = t_ec;
            out.append(t_ec == EXECUTE_SUCCESS ? _get_man_text(command_format, help_file) : ("No manual entry for " + arg + ".\n"));
        }
    }

    function _get_man_file(string arg, CommandHelp[] help_files) internal pure returns (uint8 ec, CommandHelp help_file) {
        ec = EXECUTE_FAILURE;
        for (CommandHelp bh: help_files)
            if (bh.name == arg)
                return (EXECUTE_SUCCESS, bh);
    }

    function _get_man_text(uint8 command_format, CommandHelp help_file) private pure returns (string) {
        (string name, string synopsis, string purpose, string description, string options, string notes, string author, string bugs, string see_also, string version) = help_file.unpack();
        options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");

        if (command_format == 2) {
            string usage = "Usage: " + name + " " + synopsis;
            return _join_fields([usage, description, _format_custom("Options:", options, 2, "\n")], "\n");
        }

        if (command_format == 3) {
            return name + " " + version + "\n" + author + "\n";
        }

        if (command_format == 1)
//            return _join_fields([
            return _format_custom(name + "(1)", _join_fields([
                _format_list("NAME", name + " - " + purpose),
                _format_list("SYNOPSIS", name + " " + synopsis),
                _format_list("DESCRIPTION", description),
                _format_list("OPTIONS", options),
                _format_list("", notes),
                _format_list("AUTHOR", author),
                _format_list("REPORTING BUGS", bugs),
                _format_list("SEE ALSO", see_also),
                _format_line("Version ", version)], "\n"),
//                "\n");
                0, "\n");
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return (
            "man",
            "[COMMAND]",
            "an interface to the system reference manuals",
            "System's manual pager. Each page argument given to man is normally the name of a program, utility or function.",
            "a",
            0,
            M, [
                "find all matching manual pages"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"man",
"[COMMAND]",
"an interface to the system reference manuals",
"System's manual pager. Each page argument given to man is normally the name of a program, utility or function.",
"-a     display all the manual pages with names that match the search criteria.",
"",
"Written by Boris",
"find all matching manual pages",
"apropos, whatis",
"0.01");
    }
}
