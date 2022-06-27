pragma ton-solidity >= 0.61.2;

import "putil.sol";
import "../lib/path.sol";

contract basename is putil {

    using path for string;

    function _main(p_env e_in, s_proc p) internal pure override returns (p_env e) {
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        string[] params = p.params();
        if (params.empty())
            e.perror("missing operand");

        bool multiple_args = p.flag_set("a");
        string line_terminator = p.flag_set("z") ? "\x00" : "\n";

        if (multiple_args)
            for (string s: params) {
                s.dirp();
                res.fputs(s + line_terminator);
            }
        else {
            string s = params[0];
            s.dirp();
            res.fputs(s + line_terminator);
        }
        e.ofiles[libfdt.STDOUT_FILENO] = res;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"basename",
"OPTION... NAME...",
"strip directory and suffix from filenames",
"Print NAME with any leading directory components removed.",
"-a      support multiple arguments and treat each as a NAME\n\
-s      remove a trailing SUFFIX; implies -a\n\
-z      end each output line with NUL, not newline",
"",
"Written by Boris",
"Suffix removal is not yet supported",
"dirname, readlink",
"0.01");
    }

}
