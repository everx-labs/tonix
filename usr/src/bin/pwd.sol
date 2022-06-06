pragma ton-solidity >= 0.60.0;

import "../include/Shell.sol";
import "../lib/unistd.sol";

contract pwd is Shell {

    using unistd for s_proc;

//    function print(string args, string pool) external pure returns (uint8 ec, string out) {
    function print(s_proc p, string args, string pool) external pure returns (uint8 ec, string out) {
        (, string flags, ) = arg.get_args(args);
        bool print_physical = !flags.empty() && arg.flag_set("P", flags);
        if (!print_physical) {
//            string wd = vars.val("PWD", pool);
            string wd = p.getwd();
            if (wd.empty()) {
                ec = EXECUTE_FAILURE;
                out = "pwd: current directory cannot be read\n";
            } else
                out = wd + "\n";
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
"pwd",
"[-LP]",
"Print the name of the current working directory.",
"",
"-L        print the value of $PWD if it names the current working directory\n\
-P        print the physical directory, without any symbolic links\n\
By default, pwd behaves as if -L were specified.",
"",
"Returns 0 unless an invalid option is given or the current directory cannot be read.");
    }

}
