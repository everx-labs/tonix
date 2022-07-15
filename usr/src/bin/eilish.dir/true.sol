pragma ton-solidity >= 0.62.0;
import "pbuiltin.sol";
contract true_ is pbuiltin {

    function _main(shell_env e_in) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        rc = EXIT_SUCCESS;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp("true", "", "Return a successful result.", "", "", "", "Always succeeds.");
    }
}