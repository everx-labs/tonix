pragma ton-solidity >= 0.62.0;

import "putil.sol";
import "path.sol";

contract dirname is putil {

    using path for string;

    function _main(shell_env e_in) internal pure override returns (shell_env e) {
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        string line_terminator = e.flag_set("z") ? "\x00" : "\n";
        for (string s: e.params())
            res.fputs(s.dirp() + line_terminator);
        e.ofiles[libfdt.STDOUT_FILENO] = res;
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
