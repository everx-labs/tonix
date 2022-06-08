pragma ton-solidity >= 0.61.0;

import "Shell.sol";

contract source is Shell {

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        string[] params = p.params();

        string pool = vmem.vmem_fetch_page(sv.vmem[1], 8);
        string file_contents;
        s_of f = p.fdopen(0, "r");
        if (!f.ferror())
            file_contents = f.gets_s(0);

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
        //res = exec_cmd; // TODO: apply to redirections

        sv.cur_proc = p;
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
