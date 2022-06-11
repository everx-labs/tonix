pragma ton-solidity >= 0.61.0;

import "../lib/stypes.sol";
import "../lib/libhelp.sol";
import "../lib/parg.sol";
import "../lib/io.sol";

abstract contract putil {

    using io for s_proc;
    using parg for s_proc;
    using str for string;
    using xio for s_of;
    using libstring for string;

    function main(s_proc p_in) external pure returns (s_proc p) {
        if (parg.opt_value(p_in, "help").empty())
            p = _main(p_in);
        else {
            p = p_in;
            p.puts(libhelp.usage(_command_help()));
        }
    }
    function _main(s_proc p_in) internal pure virtual returns (s_proc);

    function command_help() external pure returns (CommandHelp) {
        return _command_help();
    }

    function _command_help() internal pure virtual returns (CommandHelp);

//    uint8 constant EXECUTE_SUCCESS  = 0;
//    uint8 constant EXECUTE_FAILURE  = 1;
    uint8 constant EXIT_SUCCESS  = 0;
    uint8 constant EXIT_FAILURE  = 1;
    uint8 constant EX_BADUSAGE      = 2; // Usage messages by builtins result in a return status of 2

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