pragma ton-solidity >= 0.48.0;

import "Base.sol";
abstract contract Commands is Base {

    uint8 constant TEXT_FILE = 1;
    uint8 constant BINARY_FILE = 2;

    uint8 constant res0     = 0;
    uint8 constant CMD_NAME = 1;
    uint8 constant basename = 1;
    uint8 constant cat      = 2;
    uint8 constant cd       = 3;
    uint8 constant chgrp    = 4;
    uint8 constant chmod    = 5;
    uint8 constant chown    = 6;
    uint8 constant cksum    = 7;
    uint8 constant cmp      = 8;
    uint8 constant cp       = 9;
    uint8 constant dd       = 10;
    uint8 constant df       = 11;
    uint8 constant dirname  = 12;
    uint8 constant du       = 13;
    uint8 constant echo     = 14;
    uint8 constant file     = 15;
    uint8 constant help     = 16;
    uint8 constant ln       = 17;
    uint8 constant ls       = 18;
    uint8 constant man      = 19;
    uint8 constant mkdir    = 20;
    uint8 constant mv       = 21;
    uint8 constant paste    = 22;
    uint8 constant pwd      = 23;
    uint8 constant rm       = 24;
    uint8 constant rmdir    = 25;
    uint8 constant stat     = 26;
    uint8 constant touch    = 27;
    uint8 constant uname    = 28;
    uint8 constant wc       = 29;
    uint8 constant whoami   = 30;
    uint8 constant mount    = 31;
    uint8 constant ping     = 32;
    uint8 constant account  = 33;
    uint8 constant CMD_NAME_LAST = account;

    uint8 constant option_help     = 255;
    uint8 constant option_version  = 254;

    uint16 constant M = 0xFFFF;

    uint16 constant NO_ACTION        = 0;
    uint16 constant PRINT_ERROR      = 1;
    uint16 constant PRINT_OUT        = 2;
    uint16 constant PRINT_IN         = 4;
    uint16 constant PRINT_STAT       = 8;
    uint16 constant PROCESS_COMMAND  = 16;
    uint16 constant INODE_EVENT      = 64;
    uint16 constant IO_EVENT         = 128;
    uint16 constant READ_EVENT       = 256;
//    uint16 constant READ_INODE       = 6;

    string[CMD_NAME_LAST + 1] public _command_names;

    function _init_commands() internal {
        _command_names = [
            "res0", "basename", "cat", "cd", "chgrp", "chmod", "chown", "cksum", "cmp", "cp",
            "dd", "df", "dirname", "du", "echo", "file", "help", "ln", "ls", "man", "mkdir",
            "mv", "paste", "pwd", "rm", "rmdir", "stat", "touch", "uname", "wc", "whoami",
            "mount", "ping", "account"];
    }

    function update_command_names(string[] cn) external accept {
        _command_names = cn;
    }

    function _match_command(string s) internal view returns (uint8) {
        for (uint8 i = CMD_NAME; i <= CMD_NAME_LAST; i++)
            if (_command_names[i] == s)
                return i;
        return 0;
    }

    function _is_pure(uint8 c) internal pure returns (bool) {
        return c == basename || c == dirname || c == uname;
    }

    function _op_stat(uint8 c) internal pure returns (bool) {
        return c == cat || c == cksum || c == df || c == du || c == file || c == paste || c == ls || c == stat || c == wc;
    }

    function _op_access(uint8 c) internal pure returns (bool) {
        return c == chmod || c == chgrp || c == chown;
    }

    function _op_file(uint8 c) internal pure returns (bool) {
        return c == cp || c == dd || c == ln || c == mkdir || c == mv || c == rm || c == rmdir || c == touch;
    }

    function _op_session(uint8 c) internal pure returns (bool) {
        return c == pwd || c == whoami || c == cd || c == echo || c == dd || c == cmp;
    }

    function _op_fs(uint8 c) internal pure returns (bool) {
        return c == mount;
    }

    function _op_network(uint8 c) internal pure returns (bool) {
        return c == ping || c == account;
    }

    function _op_file_read(uint8 c) internal pure returns (bool) {
        return c == cat || c == cmp || c == echo || c == paste || c == wc;
    }

    function _reads_file_fixed(uint8 c) internal pure returns (bool) {
        return c == help || c == man;
    }

}
