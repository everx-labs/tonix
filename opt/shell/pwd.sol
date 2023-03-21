pragma ton-solidity >= 0.67.0;

import "pbuiltin.sol";

contract _pwd is pbuiltin {

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        if (!cc.flag_set("P")) {
            uint16 wd = e.get_cwd();
            if (wd == 0) {
                e.perror("current directory cannot be read");
                rc = EXIT_FAILURE;
            } else
                e.puts(vars.val("PWD", e.environ[sh.VARIABLE]));
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
_name(),
"[-LP]",
"Print the name of the current working directory.",
"",
"-L        print the value of $PWD if it names the current working directory\n\
-P        print the physical directory, without any symbolic links\n\
By default, pwd behaves as if -L were specified.",
"",
"Returns 0 unless an invalid option is given or the current directory cannot be read.");
    }
    function _name() internal pure override returns (string) {
        return "pwd";
    }
}
