pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract dirname is Utility {

    function main(string argv) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        err = "";
        (string[] params, , ) = arg.get_args(argv);
        for (string s: params) {
            (string dir, ) = path.dir(s);
            out += dir + "\n";
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"dirname",
"[OPTION] NAME...",
"strip last component from file name",
"Output NAME with its last non-slash component and trailing slashes removed; if NAME contains no /'s, output '.' (meaning the current directory).",
"-z     end each output line with NUL, not newline",
"",
"Written by Boris",
"",
"basename, readlink",
"0.01");
    }
}
