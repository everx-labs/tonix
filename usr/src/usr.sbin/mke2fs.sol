pragma ton-solidity >= 0.60.0;

import "Utility.sol";
import "../lib/vfs.sol";

contract mke2fs is Utility {

    function main(string argv) external pure returns (string out, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        out = "";
        (inodes, data) = vfs.get_system_init(argv);
    }

    function get_device_fs(string devices) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        return vfs.get_device_fs(devices);
    }

    function t_mkfs_2(string config) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, TvmCell c, string out) {
        return vfs.get_system_init_2(config);
    }

    function process_system_init(uint16 mode, string config) external pure returns (string out) {
        uint16 level = mode & 0xFF;
        uint16 form = (mode >> 8) & 0xFF;
        (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) = vfs.get_system_init(config);
        return inode.dumpfs(level, form, inodes, data);
    }

    function get_system_init(string config) external pure returns (mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) {
        return vfs.get_system_init(config);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"mke2fs",
"[options] [fs-options] device [size]",
"build a Tonix filesystem",
"Used to build a Tonix filesystem on a device.",
"-b      specify the size of blocks in bytes\n\
-d      copy the contents of the given directory into the root directory of the filesystem\n\
-I      specify the size of each inode in bytes\n\
-j      create the filesystem with an ext3 journal\n\
-n      not actually create a filesystem, but display what it would do if it were to create a filesystem\n\
-S      write superblock and group descriptors only",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
