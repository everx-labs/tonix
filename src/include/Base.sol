pragma ton-solidity >= 0.56.0;

/* Base functions and definitions */
contract Base {

    /* Upgrade */
    function upgrade(TvmCell c) external {
        tvm.accept();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
        onCodeUpgrade();
    }

    function onCodeUpgrade() internal {
    }

    function reset_storage() external accept {
        tvm.resetStorage();
    }

    modifier accept {
        tvm.accept();
        _;
    }

}
