pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";
import "unistd.sol";

contract pwd is pbuiltin {

    function _main(s_proc p, string[] , shell_env e_in) internal pure override returns (shell_env e) {
        e = e_in;
        if (!p.flag_set("P")) {
            string wd = unistd.getwd(p);
            if (wd.empty())
                e.perror("current directory cannot be read");
            else
                e.puts(wd);
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
