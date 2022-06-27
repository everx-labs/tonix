pragma ton-solidity >= 0.61.2;

import "../lib/stypes.sol";
import "../lib/libhelp.sol";
import "../lib/parg.sol";
import "../lib/io.sol";
import "../lib/libfdt.sol";
import "../lib/libprocenv.sol";

abstract contract putil_base {

    using io for s_proc;
    using parg for s_proc;
    using str for string;
    using xio for s_of;
    using libstring for string;
    using libfdt for s_of[];
    using libprocenv for p_env;

    function main(p_env e_in, s_proc p_in) external pure returns (p_env e, s_proc p) {
        e = e_in;
        if (parg.opt_value(p_in, "help").empty())
            e = _main(e_in, p_in);
        else {
            p = p_in;
            e.puts(libhelp.usage(_command_help()));
        }
    }
    function _main(p_env e_in, s_proc p_in) internal pure virtual returns (p_env);

    function command_help() external pure returns (CommandHelp) {
        return _command_help();
    }

    function _command_help() internal pure virtual returns (CommandHelp);

    uint8 constant EXIT_SUCCESS = 0;
    uint8 constant EXIT_FAILURE = 1;
    uint8 constant EX_BADUSAGE  = 2; // Usage messages by builtins result in a return status of 2

    function upgrade(TvmCell c) external {
        tvm.accept();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
        onCodeUpgrade();
    }

    function onCodeUpgrade() internal {
        tvm.resetStorage();
    }

    modifier accept {
        tvm.accept();
        _;
    }

}