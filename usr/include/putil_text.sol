pragma ton-solidity >= 0.67.0;

import "putil_base.sol";

abstract contract putil_text is putil_base {

    function _main(shell_env e_in) internal pure override returns (shell_env e) {
        e = e_in;
            for (string param: e.params()) {
                s_of f = e.fopen(param, "r");
                if (!f.ferror())
                    e = _process_file(f, e);
                else
                    e.perror(param);
            }
    }
    function _command_help() internal pure virtual override returns (CommandHelp);

    function _process_file(s_of f, shell_env e_in) internal pure virtual returns (shell_env e);

}