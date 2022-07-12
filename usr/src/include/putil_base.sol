pragma ton-solidity >= 0.61.2;

import "stypes.sol";
import "libhelp.sol";
import "parg.sol";
import "io.sol";
import "libfdt.sol";
import "libshellenv.sol";

abstract contract putil_base {

    using io for s_proc;
    using parg for s_proc;
    using str for string;
    using xio for s_of;
    using libstring for string;
    using libfdt for s_of[];
    using libshellenv for shell_env;

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