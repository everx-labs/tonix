pragma ton-solidity >= 0.56.0;

import "include/Internal.sol";
import "lib/arg.sol";
import "lib/fs.sol";
import "lib/uadmin.sol";

struct CommandHelp {
    string name;
    string synopsis;
    string purpose;
    string description;
    string options;
    string notes;
    string author;
    string bugs;
    string see_also;
    string version;
}

struct Arg {
    string path;
    uint8 ft;
    uint16 idx;
    uint16 parent;
    uint16 dir_index;
}

abstract contract Utility is Internal {

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

    function command_help() external pure returns (CommandHelp ch) {
        return _command_help();
    }

    function _command_help() internal pure virtual returns (CommandHelp ch);
}