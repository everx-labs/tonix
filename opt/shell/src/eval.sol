pragma ton-solidity >= 0.62.0;

import "pbuiltin_base.sol";

contract eval is pbuiltin_base {

    function main(shell_env e_in) external pure returns (shell_env e) {
        e = e_in;
    }


    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp("eval",
            "[arg ...]",
            "Execute arguments as a shell command.",
            "Combine ARGs into a single string, use the result as input to the shell, and execute the resulting commands.",
            "",
            "",
            "Returns exit status of command or success if command is null.");
    }
}
