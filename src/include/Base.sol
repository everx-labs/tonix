pragma ton-solidity >= 0.56.0;

struct Session {
    uint16 pid;
    uint16 uid;
    uint16 gid;
    uint16 wd;
    string user_name;
    string group_name;
    string host_name;
    string cwd;
}

struct Err {
    uint8 reason;
    uint16 explanation;
    string arg;
}

struct Host {
    string name;
    address addr;
}

struct Action {
    uint8 act_type;
    uint16 n_files;
}

struct Ar {
    uint8 ar_type;
    uint8 file_type;
    uint16 index;
    uint16 dir_index;
    string path;
    string text;
}

struct DeviceInfo {
    uint8 major_id;
    uint8 minor_id;
    string name;
    uint16 blk_size;
    uint16 n_blocks;
    address device_address;
}

/* Base functions and definitions */
contract Base {

    uint8 constant EXECUTE_SUCCESS  = 0;
    uint8 constant EXECUTE_FAILURE  = 1;
    uint8 constant EX_BADUSAGE      = 2; // Usage messages by builtins result in a return status of 2

    uint16 constant M = 0xFFFF;

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
    uint16 constant KILO = 1024;
    string constant ROOT = "/";

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
