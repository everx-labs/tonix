pragma ton-solidity >= 0.61.1;

import "pbuiltin.sol";
import "../../lib/unistd.sol";

contract pwd is pbuiltin {

    using unistd for s_proc;

    function _main(s_proc p_in, string[] , shell_env) internal pure override returns (s_proc p) {
        p = p_in;
        if (!p.flag_set("P")) {
            string wd = p.getwd();
            if (wd.empty()) {
                p.perror("current directory cannot be read");
            } else
                p.puts(wd);
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
