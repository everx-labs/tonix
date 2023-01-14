pragma ton-solidity >= 0.62.0;

import "putil_base.sol";
contract whatis is putil_base {

    function main(shell_env e_in, CommandHelp[] help_files) external pure returns (shell_env e) {
        e = e_in;
        string[] params = e.params();

        if (params.empty())
            e.puts("whatis what?");
        for (string param: params) {
            (uint8 t_ec, CommandHelp help_file) = _get_man_file(param, help_files);
            e.puts(t_ec == EXIT_SUCCESS ? _get_man_text(help_file) : (param + ": nothing appropriate."));
        }
    }

    function _get_man_file(string arg, CommandHelp[] help_files) internal pure returns (uint8 ec, CommandHelp help_file) {
        ec = EXIT_FAILURE;
        for (CommandHelp bh: help_files)
            if (bh.name == arg)
                return (EXIT_SUCCESS, bh);
    }

    function _get_man_text(CommandHelp help_file) private pure returns (string) {
        (string name, , string purpose, , , , , , , ) = help_file.unpack();
        return name + " (1)\t\t\t - " + purpose + "\n";
    }

     function _command_help() internal pure returns (CommandHelp) {
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
