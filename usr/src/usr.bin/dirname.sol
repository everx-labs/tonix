pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract dirname is Utility {

    using path for string;

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        string line_terminator = p.flag_set("z") ? "\x00" : "\n";
        for (string s: p.params())
            p.puts(s.dirp() + line_terminator);
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
