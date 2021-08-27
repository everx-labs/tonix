pragma ton-solidity >= 0.48.0;

abstract contract Base {

    uint16 constant SUPER_USER_GROUP = 0;
    uint16 constant REG_USER_GROUP = 1000;
    uint16 constant GUEST_USER_GROUP = 10000;

    uint16 constant SUPER_USER  = 0;  // uid 0
    uint16 constant REG_USER    = 2000;
    uint16 constant GUEST_USER  = 10000;

    uint16 constant INODES = 10;
    uint16 constant ROOT_DIR = INODES + 1;
    uint16 constant USERS = 1000;

    modifier accept {
        tvm.accept();
        _;
    }

    /* Upgrade */
    function upgrade(TvmCell c) external {
        tvm.accept();
        TvmCell newcode = c.toSlice().loadRef();
        tvm.commit();
        tvm.setcode(newcode);
        tvm.setCurrentCode(newcode);
        onCodeUpgrade();
    }

    function onCodeUpgrade() internal {
        tvm.resetStorage();
        _init();
    }

    function _init() internal virtual;
}
