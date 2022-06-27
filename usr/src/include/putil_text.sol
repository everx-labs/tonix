pragma ton-solidity >= 0.61.2;

import "putil_base.sol";

abstract contract putil_text is putil_base {

    function _main(p_env e_in, s_proc p) internal pure override returns (p_env e) {
        e = e_in;
            for (string param: p.params()) {
                s_of f = e.fopen(param, "r");
                if (!f.ferror())
                    e = _process_file(f, e, p);
                else
                    e.perror(param);
            }
    }
    function _command_help() internal pure virtual override returns (CommandHelp);

    function _process_file(s_of f, p_env e_in, s_proc p_in) internal pure virtual returns (p_env e);

}