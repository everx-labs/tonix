pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract pwd is Shell {

    function b_exec(string[] e) external pure returns (uint8 ec, string out) {
        (ec, out) = _pwd(e);
    }

    function exec(string[] e) external pure returns (uint8 ec, string out, string err) {
        (ec, out) = _pwd(e);
        err = "";
    }

    function _pwd(string[] e) internal pure returns (uint8, string) {
        string wd = _val("PWD", e[IS_POOL]);
        return (wd.empty() ? 1 : 0, wd);
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
