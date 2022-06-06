pragma ton-solidity >= 0.60.0;

import "Shell.sol";

contract source is Shell {

    function read_input(string args, string input, string pool) external pure returns (uint8 ec, string out, string res) {
//        (string[] params, , ) = arg.get_args(args);
        if (!args.empty())
            ec = EXECUTE_SUCCESS;

        string file_contents = input;
        string tosh_path = vars.val("TOSH", pool);
        string sargs = vars.val("$@", pool);
        string cmd = vars.val("$0", pool);
        string exec_queue;
        string exec_cmd;

        (string[] lines, uint n_lines) = file_contents.split(";");
        for (uint i = 0; i < n_lines; i++) {
            string sline = lines[i];
            if (sline.empty())
                continue;
            string first_sym = sline.substr(0, 1);
            if (first_sym == '.')
                sline = tosh_path + sline.substr(1);
            uint len = sline.byteLength();
            if (len > 2) {
                sline.translate("$@", sargs);
                sline.translate("$0", cmd);
            }
            string exec_line = sline + "\n";
            exec_queue.append(format("[{}]=\"{}\"\n", i, sline));
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
