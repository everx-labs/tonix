pragma ton-solidity >= 0.49.0;

/* Base functions and definitions */
abstract contract Base {

    uint16 constant SUPER_USER_GROUP = 0;
    uint16 constant REG_USER_GROUP = 1000;
    uint16 constant GUEST_USER_GROUP = 10000;

    uint16 constant SUPER_USER  = 0;  // uid 0
    uint16 constant REG_USER    = 1000;
    uint16 constant GUEST_USER  = 10000;

    uint16 constant INODES = 10;
    uint16 constant ROOT_DIR = INODES + 1;
    uint16 constant USERS = 1000;

    uint16 constant DEF_UMASK = 18;

    uint16 constant DEF_BLOCK_SIZE = 1024;
    uint16 constant DEF_BIN_BLOCK_SIZE = 4096;
    uint16 constant MAX_MOUNT_COUNT = 1024;
    uint16 constant DEF_INODE_SIZE = 128;
    uint16 constant MAX_BLOCKS = 400;
    uint16 constant MAX_INODES = 600;

    string constant ROOT = "/";

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

    /* Implemented by contracts to perform post-upgrade initialization */
    function _init() internal virtual;
}
