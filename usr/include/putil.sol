pragma ton-solidity >= 0.62.0;

import "putil_base.sol";

abstract contract putil is putil_base {
    function main(shell_env e_in) external pure returns (shell_env e) {
        if (e_in.opt_value("help").empty())
            e = _main(e_in);
        else {
            e = e_in;
            e.puts(libhelp.usage(_command_help()));
        }
    }
    function _main(shell_env e_in) internal pure virtual returns (shell_env e);
    function command_help() external pure returns (CommandHelp) {
        return _command_help();
    }
    function _command_help() internal pure virtual returns (CommandHelp);
}