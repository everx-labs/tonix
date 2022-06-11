pragma ton-solidity >= 0.61.0;

import "putil.sol";
import "../sys/sys/libpatch.sol";
import "../sys/sys/libstr.sol";

contract patch is putil {

    function _main(s_proc p_in) internal override pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
        if (params.length < 2) {
            (string name, string synopsis, , string description, string options, , , , , ) = _command_help().unpack();
            options.append("\n--help\tdisplay this help and exit\n--version\toutput version information and exit");
            string usage = "Usage: " + name + " " + synopsis + "\n";
            p.puts(libstring.join_fields([usage, description, fmt.format_custom("Options:", options, 2, "\n")], "\n"));
            return p;
        }
        s_of f1 = p.fopen(params[0], "r");
        s_of f2 = p.fopen(params[1], "r");
        if (!f1.ferror()) {
            while (!f1.feof() && !f2.feof()) {
                string line1 = f1.fgetln();
                string line2 = f2.fgetln();
                if (line1 != line2) {
                    p.puts("< " + line1);
                    p.puts("---");
                    p.puts("> " + line2);
                }
            }
        } else
            p.perror(params[0] + ": cannot open");
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
