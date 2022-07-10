pragma ton-solidity >= 0.61.2;

import "putil.sol";
import "path.sol";

contract dirname is putil {

    using path for string;

    function _main(p_env e_in, s_proc p) internal pure override returns (p_env e) {
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        string line_terminator = p.flag_set("z") ? "\x00" : "\n";
        for (string s: p.params())
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
