pragma ton-solidity >= 0.67.0;

import "putil.sol";
import "path.sol";

contract basename is putil {

    using libpath for string;

    function _main(shell_env e_in) internal pure override returns (shell_env e) {
        e = e_in;
        s_of res = e.ofiles[libfdt.STDOUT_FILENO];
        string[] params = e.params();
        if (params.empty())
            e.perror("missing operand");

        bool multiple_args = e.flag_set("a");
        string line_terminator = e.flag_set("z") ? "\x00" : "\n";

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
