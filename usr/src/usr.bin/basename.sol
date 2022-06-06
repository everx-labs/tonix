pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract basename is Utility {

    using path for string;

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
        if (params.empty())
            p.perror("basename: missing operand");

        bool multiple_args = p.flag_set("a");
        string line_terminator = p.flag_set("z") ? "\x00" : "\n";

        if (multiple_args)
            for (string s: params) {
                s.dirp();
                p.puts(s + line_terminator);
            }
        else {
            string s = params[0];
            s.dirp();
            p.puts(s + line_terminator);
        }
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
