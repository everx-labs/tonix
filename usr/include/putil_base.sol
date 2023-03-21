pragma ton-solidity >= 0.67.0;

import "libhelp.sol";
import "libshellenv.sol";

abstract contract putil_base {

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