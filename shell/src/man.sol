pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract man is Utility {

    function _get_man_file(string arg, CommandHelp[] help_files) internal pure returns (uint8 ec, CommandHelp help_file) {
        ec = EXECUTE_FAILURE;
        for (CommandHelp bh: help_files)
            if (bh.name == arg)
                return (EXECUTE_SUCCESS, bh);
    }

    function display_man_page(string args, CommandHelp[] help_files) external pure returns (uint8 ec, string out) {
        (string[] params, string flags,) = _get_args(args);
        uint8 command_format = 1;

        if (params.empty())
            out.append("What manual page do you want?\nFor example, try 'man man'.");
        for (string arg: params) {
            (uint8 t_ec, CommandHelp help_file) = _get_man_file(arg, help_files);
            ec = t_ec;
            out.append(t_ec == EXECUTE_SUCCESS ? _get_man_text(command_format, help_file) : ("No manual entry for " + arg + ".\n"));
        }
    }

    /* Informational commands helpers */
    function _get_man_text(uint8 command_format, CommandHelp help_file) private pure returns (string) {
        (string name, string synopsis, string purpose, string description, string options, string notes, string author, string bugs, string see_also, string version) = help_file.unpack();
        options.append("\n--help\tdisplay this help and exit\n--version\n\t\toutput version information and exit");

        /*if (command_format < COMMAND_FORMAT_DESCRIPTION)
            return "";
        else if (command_format == COMMAND_FORMAT_DESCRIPTION)
            return name + " - " + purpose + "\n";
        else if (command_format == COMMAND_FORMAT_SYNOPSIS)
            return name + ": " + name + " " + synopsis + "\n";*/

        if (command_format == 1)
            return _join_fields([
                _format_list("NAME", name + " - " + purpose),
                _format_list("SYNOPSIS", name + " " + synopsis),
                _format_list("DESCRIPTION", description),
                _format_list("OPTIONS", options),
                _format_list("", notes),
                _format_list("AUTHOR", author),
                _format_list("REPORTING BUGS", bugs),
                _format_list("SEE ALSO", see_also),
                _format_line("Version ", version)], "\n");
    }

//        for (string u: uses)
//            usage.append("\t" + name + " " + u + "\n");
//        string options;
//        for (uint i = 0; i < option_descriptions.length; i++)
//            options.append("\t" + "-" + option_names.substr(i, 1) + "\t" + option_descriptions[i] + "\n");
  //      options.append("\t" + "--help\tdisplay this help and exit\n\t--version\n\t\toutput version information and exit\n");

//        return name + "(1)\t\t\t\t\tUser Commands\n\nNAME\n\t" + name + " - " + purpose + "\n\nSYNOPSIS\n" + usage +
//            "\nDESCRIPTION\n\t" + description + "\n\n" + options;

    function _get_help_text(string command) private pure returns (string) {
        (string name, , string description, string[] uses, string option_names, string[] option_descriptions) = _get_command_page(command);
        string usage;
        for (string u: uses)
            usage.append("\t" + name + " " + u + "\n");
        string options = "\n";
        for (uint i = 0; i < option_descriptions.length; i++)
            options.append("  -" + option_names.substr(i, 1) + "\t\t" + option_descriptions[i] + "\n");
        options.append("  --help\tdisplay this help and exit\n  --version\toutput version information and exit\n");

        return "Usage: " + usage + description + options;
    }

    function _get_command_page(string command) private pure returns (string name, string purpose, string desc, string[] uses,
                string option_names, string[] option_descriptions) {
        /*(string[] command_data, uint n_fields) = _split(_get_file_contents_at_path("/usr/" + command, _inodes, _data), "\n");
        if (n_fields > 5)
            return (command_data[0], command_data[1], _join_fields(_get_tsv(command_data[3]), "\n"),
                _get_tsv(command_data[2]), command_data[4], _get_tsv(command_data[5]));*/
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
