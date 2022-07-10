pragma ton-solidity >= 0.61.0;

import "putil.sol";
import "libpatch.sol";
import "libstr.sol";

contract patch is putil {

    function _main(p_env e_in, s_proc p) internal pure override returns (p_env e) {
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        string[] params = p.params();
        if (params.length < 2) {
            (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
            options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
            string usage = "Usage: " + name + " " + synopsis + "\n";
            res.fputs(libstring.join_fields([usage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n"));
            e.ofiles[libfdt.STDOUT_FILENO] = res;
            return e;
        }
        s_of f1 = p.fopen(params[0], "r");
        s_of f2 = p.fopen(params[1], "r");
        if (!f1.ferror()) {
            while (!f1.feof() && !f2.feof()) {
                string line1 = f1.fgetln();
                string line2 = f2.fgetln();
                if (line1 != line2) {
                    res.fputs("< " + line1);
                    res.fputs("---");
                    res.fputs("> " + line2);
                }
            }
        } else
            p.perror(params[0] + ": cannot open");
        e.ofiles[libfdt.STDOUT_FILENO] = res;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"patch",
"[options] [originalfile [patchfile]]",
"apply a diff file to an original",
"takes a patch file patchfile containing a difference listing and applies those differences to one or more original files, producing patched versions.",
"",
"",
"Written by Boris",
"",
"diff(1), merge(1)",
"0.02");
    }
}
