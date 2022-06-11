pragma ton-solidity >= 0.61.0;

import "putil.sol";

contract whoami is putil {

    function _main(s_proc p_in) internal override pure returns (s_proc p) {
        p = p_in;
        p.puts(p.env_value("USER"));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"whoami",
"OPTION...",
"print effective userid",
"Print the user name associated with the current effective user ID. Same as id -un.",
"",
"",
"Written by Boris",
"",
"",
"0.02");
    }

}
