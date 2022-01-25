pragma ton-solidity >= 0.55.0;

//import "Common.sol";
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

struct Arg {
    string path;
    uint8 ft;
    uint16 idx;
    uint16 parent;
    uint16 dir_index;
}

struct Err {
    uint8 reason;
    uint16 explanation;
    string arg;
}

struct InputS {
    uint8 command;
    string[] args;
    uint flags;
}

struct ParsedCommand {
    string command;
    string[] args;
    string short_options;
    string[] long_options;
    string stdin_redirect;
    string stdout_redirect;
    uint16 action;
    string s_action;
}

struct IOEvent {
    uint8 iotype;
    uint16 parent;
    Arg[] args;
}

struct WriteMetaData {
    uint16 mode;
    uint16 segment;
    uint16 offset;
    uint16 size;
}

struct WDEvent {
    uint8 wdtype;
    WriteMetaData meta_data;
    bytes data;
}

struct AREvent {
    uint8 artype;
    Arg[] args;
    string[] ar_index;
    bytes data;
}

struct UserEvent {
    uint8 uetype;
    uint16 user_id;
    uint16 group_id;
    uint16 options;
    string user_name;
    string group_name;
    uint16[] values;
}

struct LoginEvent {
    uint8 letype;
    uint16 user_id;
    uint16 tty_id;
    uint16 device_id;
    uint32 timestamp;
}

struct Host {
    string name;
    address addr;
}

struct Page {
    string command;
    string purpose;
    string synopsis;
    string description;
    string option_list;
    uint8 min_args;
    uint16 max_args;
    string[] option_descriptions;
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
//contract Base is Common {
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

    uint16 constant SB          = 0;
    uint16 constant DEVICE_INFO = 1;
    uint16 constant SB_INFO     = 2;
    uint16 constant SB_INODES   = SB_INFO + 1;
    uint16 constant SB_BLOCKS   = SB_INFO + 2;
    uint16 constant SB_MOUNTS   = SB_INFO + 3;
    uint16 constant SB_STATE    = SB_INFO + 4;
    uint16 constant SB_INODES_TABLE = SB_INFO + 5;
    uint16 constant SB_SB       = SB_INFO + 6;
    uint16 constant SB_JOURNAL  = SB_INFO + 7;
    uint16 constant SB_BACKUP   = SB_INFO + 8;

    uint16 constant INODES = 10;
    uint16 constant ROOT_DIR = INODES + 1;
    uint16 constant USERS = 1000;

    uint16 constant DEF_UMASK = 18;
    uint16 constant KILO = 1024;
    string constant ROOT = "/";

    uint8 constant IO_WR_COPY       = 1;
    uint8 constant IO_ALLOCATE      = 2;
    uint8 constant IO_TRUNCATE      = 3;
    uint8 constant IO_MKFILE        = 4;
    uint8 constant IO_MKDIR         = 5;
    uint8 constant IO_HARDLINK      = 6;
    uint8 constant IO_SYMLINK       = 7;
    uint8 constant IO_UNLINK        = 8;
    uint8 constant IO_CHATTR        = 9;
    uint8 constant IO_ACCESS        = 10;
    uint8 constant IO_PERMISSION    = 11;
    uint8 constant IO_UPDATE_TIME   = 12;
    uint8 constant IO_UPDATE_TEXT_DATA = 13;
    uint8 constant IO_APPEND_TO_FILE = 14;
    uint8 constant IO_MKBIN         = 15;
    uint8 constant IO_MKNOD         = 16;

    uint8 constant IO_ARCHIVE           = 20;
    uint8 constant IO_AR_CREATE         = 1 + IO_ARCHIVE;
    uint8 constant IO_AR_APPEND         = 2 + IO_ARCHIVE;
    uint8 constant IO_AR_APPEND_FILES   = 3 + IO_ARCHIVE;
    uint8 constant IO_AR_EXTRACT        = 4 + IO_ARCHIVE;

    uint8 constant IO_ACTION                = 50;
    uint8 constant IO_CREATE_ARCHIVE        = 51;
    uint8 constant IO_ADD_FILES_TO_ARCHIVE  = 52;
    uint8 constant IO_UPDATE_ARCHIVE        = 53;
    uint8 constant IO_APPEND_ARCHIVE        = 54;
    uint8 constant IO_CREATE_FILES          = 55;
    uint8 constant IO_UPDATE_NODE           = 56;
    uint8 constant IO_COPY_FILES            = 57;
    uint8 constant IO_MOVE_FILES            = 58;
    uint8 constant IO_HARDLINK_FILES        = 59;
    uint8 constant IO_SYMLINK_FILES         = 60;
    uint8 constant IO_UNLINK_FILES          = 61;
    uint8 constant IO_CHANGE_OWNER          = 62;
    uint8 constant IO_CHANGE_GROUP          = 63;
    uint8 constant IO_CHANGE_MODE           = 64;
    uint8 constant IO_MERGE_FILES          = 65;

    uint8 constant IO_DIR_ENTRY             = 80;
    uint8 constant IO_ADD_DIR_ENTRY         = 81;
    uint8 constant IO_UPDATE_DIR_ENTRY      = 82;
    uint8 constant IO_REMOVE_DIR_ENTRY      = 83;

    uint8 constant IO_ACTION_ITEMS          = 90;
    uint8 constant IO_CREATE_ARCHIVE_FILE   = 91;
    uint8 constant IO_ADD_FILE_TO_ARCHIVE   = 92;
    uint8 constant IO_SET_ARCHIVE_HEADER    = 93;
    uint8 constant IO_BASELINE              = 94;

    uint8 constant UA_ACTION_ITEMS          = 110;
    uint8 constant UA_ADD_USER              = 1 + UA_ACTION_ITEMS;
    uint8 constant UA_ADD_GROUP             = 2 + UA_ACTION_ITEMS;
    uint8 constant UA_DELETE_USER           = 3 + UA_ACTION_ITEMS;
    uint8 constant UA_DELETE_GROUP          = 4 + UA_ACTION_ITEMS;
    uint8 constant UA_UPDATE_USER           = 5 + UA_ACTION_ITEMS;
    uint8 constant UA_UPDATE_GROUP          = 6 + UA_ACTION_ITEMS;
    uint8 constant UA_RENAME_GROUP          = 7 + UA_ACTION_ITEMS;
    uint8 constant UA_CHANGE_GROUP_ID       = 8 + UA_ACTION_ITEMS;

    uint8 constant WD_COPY          = 1;
    uint8 constant WD_ALLOCATE      = 2;
    uint8 constant WD_TRUNCATE      = 3;
    uint8 constant WD_APPEND        = 4;

    uint8 constant AR_CREATE        = 1;
    uint8 constant AR_APPEND_ARCHIVE= 2;
    uint8 constant AR_APPEND_FILES  = 3;
    uint8 constant AR_EXTRACT       = 4;

    /* Upgrade */
    function upgrade(TvmCell c) external {
//        TvmCell newcode = c.toSlice().loadRef();
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
