pragma ton-solidity >= 0.55.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract stat is Utility, libuadm {

    function exec(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        (uint16 wd, string[] params, string flags, ) = _get_env(args);
        for (string arg: params) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_stat(flags, arg, ft, index, inodes, data) + "\n");
            else {
                ec = EXECUTE_FAILURE;
                err.append("Failed to resolve relative path for" + arg + "\n");
            }
        }
    }

    function _stat(string f, string name, uint8 ft, uint16 index, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out) {
        bool terse = _flag_set("t", f);
        bool fs_info = _flag_set("f", f);
        Inode inode = inodes[index];
        uint16 blk_size = _get_block_size(inodes);
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = inode.unpack();
        string s_owner = _get_user_name(owner_id, inodes, data);
        string s_group = _get_group_name(group_id, inodes, data);

        (string major, string minor) = ft == FT_BLKDEV || ft == FT_CHRDEV  ? _get_device_version(device_id) : ("0", "0");

        if (fs_info) {
            (, , string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes, uint16 free_blocks, uint16 block_size,, , , , ,, ,) = _get_sb(inodes, data).unpack();
            out += terse ? format("{} {} {} {} {} {} {} {} {} {} {}\n", name, index, 32, file_system_OS_type, block_size, block_size, block_count + free_blocks, free_blocks, free_blocks, inode_count + free_inodes, free_inodes) :
                format("  File: \"{}\"\n    ID: {} Namelen: {}\tType: {}\nBlock size: {}\tFundamental block size: {}\nBlocks: Total: {}\tFree: {}\tAvailable: {}\nInodes: Total: {}\tFree: {}\n",
                    name, index, 20, file_system_OS_type, block_size, block_size, block_count + free_blocks, free_blocks, free_blocks, inode_count + free_inodes, free_inodes);

        } else {
            if (terse)
                out = format("{} {} {} {:x} {} {} {:x} {} {} {} {} {} {} {} {}\n",
                    name, file_size, n_blocks, mode, owner_id, group_id, device_id, index, n_links, major, minor, modified_at, last_modified, 0, blk_size);
            else {
                if (ft == FT_SYMLINK) {
                    (, string target, ) = _get_symlink_target(inode, data[index]).unpack();
                    name.append(" -> " + target);
                }
                out.append(format("   File: {}\n   Size: {}\t\tBlocks: {}\tIO Block: {}\t", name, file_size, n_blocks, blk_size));
                out.append(ft == FT_REG_FILE && file_size == 0 ? "regular empty" : _file_type_description(mode));
                out = _if(out, ft == FT_REG_FILE || ft == FT_BLKDEV || ft == FT_CHRDEV, " file");
                out.append(format("\nDevice: {:x}h/{}d\tInode: {}\tLinks: {}", device_id, device_id, index, n_links));
                if (ft == FT_BLKDEV || ft == FT_CHRDEV)
                    out.append(format("\tDevice type: {},{}\n", major, minor));
                out.append(format("\nAccess: ({}/{})  Uid: ({}/{})  Gid: ({}/{})\nModify: {}\nChange: {}\n Birth: -\n",
                    mode & 0x01FF, _permissions(mode), owner_id, s_owner, group_id, s_group, _ts(modified_at), _ts(last_modified)));
            }
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("stat", "display file or file system status", "[OPTION]... FILE...",
            "Display file or file system status.",
            "Lft", 1, M, [
            "follow links",
            "display file system status instead of file status",
            "print the information in terse form"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"stat",
"[OPTION]... FILE...",
"display file or file system status",
"Display file or file system status.",
"-L      follow links\n\
-f      display file system status instead of file status\n\
-t      print the information in terse form",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
