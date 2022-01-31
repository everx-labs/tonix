pragma ton-solidity >= 0.56.0;

import "Shell.sol";

contract source is Shell {

    function read_input(string args, string input, string pool) external pure returns (uint8 ec, string out, string res) {
//        (string[] params, , ) = arg.get_args(args);
        if (!args.empty())
            ec = EXECUTE_SUCCESS;

        string file_contents = input;
        string tosh_path = vars.val("TOSH", pool);
        string s_args = vars.val("$@", pool);
        string cmd = vars.val("$0", pool);
        string exec_queue;
        string exec_cmd;

        (string[] lines, uint n_lines) = stdio.split(file_contents, ";");
        for (uint i = 0; i < n_lines; i++) {
            string s_line = lines[i];
            if (s_line.empty())
                continue;
            string first_sym = s_line.substr(0, 1);
            if (first_sym == '.')
                s_line = tosh_path + s_line.substr(1);
            uint len = s_line.byteLength();
            if (len > 2) {
                s_line = stdio.translate(s_line, "$@", s_args);
                s_line = stdio.translate(s_line, "$0", cmd);
            }
            string exec_line = s_line + "\n";
            exec_queue.append(format("[{}]=\"{}\"\n", i, s_line));
            exec_cmd.append(exec_line);
        }
        res = exec_cmd;
        out = "";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"source",
"filename [arguments]",
"Execute commands from a file in the current shell.",
"Read and execute commands from FILENAME in the current shell. The entries in $PATH are used to find the directory containing FILENAME. If any ARGUMENTS are supplied, they become the positional parameters when FILENAME is executed.",
"",
"",
"Returns the status of the last command executed in FILENAME; fails if FILENAME cannot be read.");
    }
}
