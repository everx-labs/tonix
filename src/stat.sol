pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract stat is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);
        for (string s_arg: params) {
            (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_stat(flags, s_arg, ft, index, inodes, data) + "\n");
            else {
                ec = EXECUTE_FAILURE;
                err.append("Failed to resolve relative path for" + s_arg + "\n");
            }
        }
    }

    function _stat(string f, string name, uint8 ft, uint16 index, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out) {
        bool terse = arg.flag_set("t", f);
        bool fs_info = arg.flag_set("f", f);
        Inode ino = inodes[index];
        uint16 blk_size = sb.get_block_size(inodes);
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = ino.unpack();

        string s_owner = uadmin.user_name_by_id(owner_id, fs.get_file_contents_at_path("/etc/passwd", inodes, data));
        string s_group = uadmin.group_name_by_id(group_id, fs.get_file_contents_at_path("/etc/group", inodes, data));

        (string major, string minor) = ft == FT_BLKDEV || ft == FT_CHRDEV  ? inode.get_device_version(device_id) : ("0", "0");

        if (fs_info) {
            (, , string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes, uint16 free_blocks, uint16 block_size,, , , , ,, ,) = sb.get_sb(inodes, data).unpack();
            out += terse ? format("{} {} {} {} {} {} {} {} {} {} {}\n", name, index, 32, file_system_OS_type, block_size, block_size, block_count + free_blocks, free_blocks, free_blocks, inode_count + free_inodes, free_inodes) :
                format("  File: \"{}\"\n    ID: {} Namelen: {}\tType: {}\nBlock size: {}\tFundamental block size: {}\nBlocks: Total: {}\tFree: {}\tAvailable: {}\nInodes: Total: {}\tFree: {}\n",
                    name, index, 20, file_system_OS_type, block_size, block_size, block_count + free_blocks, free_blocks, free_blocks, inode_count + free_inodes, free_inodes);

        } else {
            if (terse)
                out = format("{} {} {} {:x} {} {} {:x} {} {} {} {} {} {} {} {}\n",
                    name, file_size, n_blocks, mode, owner_id, group_id, device_id, index, n_links, major, minor, modified_at, last_modified, 0, blk_size);
            else {
                if (ft == FT_SYMLINK) {
                    (, string target, ) = dirent.get_symlink_target(ino, data[index]).unpack();
                    name.append(" -> " + target);
                }
                out.append(format("   File: {}\n   Size: {}\t\tBlocks: {}\tIO Block: {}\t", name, file_size, n_blocks, blk_size));
                out.append(ft == FT_REG_FILE && file_size == 0 ? "regular empty" : inode.file_type_description(mode));
                out = str.aif(out, ft == FT_REG_FILE || ft == FT_BLKDEV || ft == FT_CHRDEV, " file");
                out.append(format("\nDevice: {:x}h/{}d\tInode: {}\tLinks: {}", device_id, device_id, index, n_links));
                if (ft == FT_BLKDEV || ft == FT_CHRDEV)
                    out.append(format("\tDevice type: {},{}\n", major, minor));
                out.append(format("\nAccess: ({}/{})  Uid: ({}/{})  Gid: ({}/{})\nModify: {}\nChange: {}\n Birth: -\n",
                    mode & 0x01FF, inode.permissions(mode), owner_id, s_owner, group_id, s_group, fmt.ts(modified_at), fmt.ts(last_modified)));
            }
        }
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
