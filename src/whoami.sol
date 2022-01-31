pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract whoami is Utility {

    function main(string argv) external pure returns (uint8 ec, string out, string err) {
        (string[] params, , ) = arg.get_args(argv);
        ec = params.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
        out = vars.val("USER", argv) + "\n";
        err = "";
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
"0.01");
    }

}
