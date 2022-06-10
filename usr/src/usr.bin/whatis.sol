pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract whatis is Utility {

    function main(s_proc p_in, CommandHelp[] help_files) external pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();

//    function display_man_page(string argv, CommandHelp[] help_files) external pure returns (uint8 ec, string out) {
//        (string[] params, string flags,) = arg.get_args(argv);
        if (params.empty())
            p.puts("whatis what?");
        for (string param: params) {
            (uint8 t_ec, CommandHelp help_file) = _get_man_file(param, help_files);
            p.puts(t_ec == EXECUTE_SUCCESS ? _get_man_text(help_file) : (param + ": nothing appropriate."));
        }
    }

    function _get_man_file(string arg, CommandHelp[] help_files) internal pure returns (uint8 ec, CommandHelp help_file) {
        ec = EXECUTE_FAILURE;
        for (CommandHelp bh: help_files)
            if (bh.name == arg)
                return (EXECUTE_SUCCESS, bh);
    }

    function _get_man_text(CommandHelp help_file) private pure returns (string) {
        (string name, , string purpose, , , , , , , ) = help_file.unpack();
        return name + " (1)\t\t\t - " + purpose + "\n";
    }

     function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"whatis",
"[-dlv] name ...",
"display one-line manual page descriptions",
"Searches the manual page names and displays the manual page descriptions of any name matched.",
"-d      emit debugging messages\n\
-l      do not trim output to terminal width\n\
-v      print verbose warning messages",
"",
"Written by Boris",
"Options are not yet implemented",
"apropos, man, mandb",
"0.02");
    }

}
