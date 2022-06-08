pragma ton-solidity >= 0.61.0;

import "Shell.sol";
import "../../lib/unistd.sol";

contract pwd is Shell {

    using unistd for s_proc;

    function main(svm sv_in) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        if (!p.flag_set("P")) {
            string wd = p.getwd();
            if (wd.empty()) {
                p.perror("current directory cannot be read");
            } else
                p.puts(wd);
        }
        sv.cur_proc = p;
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
