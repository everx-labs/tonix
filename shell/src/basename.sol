pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract basename is Utility {

    function main(string argv) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        err = "";
        (string[] params, string flags, ) = arg.get_args(argv);

        if (params.empty())
            return (EXECUTE_FAILURE, "", "basename: missing operand\n");

        bool multiple_args = arg.flag_set("a", flags);
        string line_terminator = arg.flag_set("z", flags) ? "\x00" : "\n";

        if (multiple_args)
            for (string s: params) {
                (, string not_dir) = path.dir(s);
                out.append(not_dir + line_terminator);
            }
        else {
            (, out) = path.dir(params[0]);
            out.append(line_terminator);
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"basename",
"NAME",
"strip directory and suffix from filenames",
"Print NAME with any leading directory components removed.",
"-a      support multiple arguments and treat each as a NAME\n\
-s      remove a trailing SUFFIX; implies -a\n\
-z      end each output line with NUL, not newline",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
