pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract pwd is Shell {

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (, string flags, ) = _get_args(args);
        bool print_physical = !flags.empty() && _flag_set("P", flags);
        if (!print_physical) {
            string wd = _val("PWD", pool);
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
