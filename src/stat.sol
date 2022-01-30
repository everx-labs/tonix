pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract stat is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err, Err[] errors) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);
        (bool terse, bool fs_info, bool format_str, , , , , ) = arg.flag_values("tfc", flags);
        string sf = format_str ? arg.opt_arg_value("c", argv) : terse ?
            fs_info ? "%n %i %l %t %s %S %b %f %a %c %d" : "%n %s %b %f %u %g %D %i %h %t %T %Y %Z %W %o %C" :
            fs_info ? "  File: \"%n\"\n    ID: %i Namelen: 20\tType: %T\nBlock size: %s\tFundamental block size: %S\n\
Blocks: Total: %b\tFree: %f\tAvailable: %a\nInodes: Total: %c\tFree: %d\n" :
"   File: %n\n   Size: %s\t\tBlocks: %b\tIO Block: %o\t%F\nDevice: %Dh/%dd\tInode: %i\tLinks: %h\tDevice type: %t,%T\n\
Access: (%a/%A)  Uid: (%u/%U)  Gid: (%g/%G)\nModify: %y\nChange: %z\n Birth: -\n";

        for (string name: params) {
            uint16 index;
            uint8 ft;
            if (name.substr(0, 1) == "/") {
                index = fs.resolve_absolute_path(name, inodes, data);
                if (index >= INODES && inodes.exists(index))
                    ft = inode.mode_to_file_type(inodes[index].mode);
            } else
                (index, ft, , ) = fs.resolve_relative_path(name, wd, inodes, data);
            if (ft != FT_UNKNOWN) {
                Inode ino = inodes[index];
                uint16 blk_size = sb.get_block_size(inodes);
                (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = ino.unpack();
                string s_owner = uadmin.user_name_by_id(owner_id, fs.get_file_contents_at_path("/etc/passwd", inodes, data));
                string s_group = uadmin.group_name_by_id(group_id, fs.get_file_contents_at_path("/etc/group", inodes, data));
                (string major, string minor) = ft == FT_BLKDEV || ft == FT_CHRDEV  ? inode.get_device_version(device_id) : ("0", "0");

                if (fs_info) {
                    (, , string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes, uint16 free_blocks, , , , , , ,, ,) = sb.get_sb(inodes, data).unpack();
                    /*out.append(terse ? format("{} {:x} {} {} {} {} {} {} {} {} {}\n", name, index, 32, file_system_OS_type, block_size, block_size, block_count + free_blocks, free_blocks, free_blocks, inode_count + free_inodes, free_inodes) :
                        format("  File: \"{}\"\n    ID: {:x} Namelen: {}\tType: {}\nBlock size: {}\tFundamental block size: {}\nBlocks: Total: {}\tFree: {}\tAvailable: {}\nInodes: Total: {}\tFree: {}\n",
                            name, index, 20, file_system_OS_type, block_size, block_size, block_count + free_blocks, free_blocks, free_blocks, inode_count + free_inodes, free_inodes));*/
                    string s = sf;
                    s = stdio.translate(s, "%a", str.toa(free_blocks));
                    s = stdio.translate(s, "%b", str.toa(block_count + free_blocks));
                    s = stdio.translate(s, "%c", str.toa(inode_count + free_inodes));
                    s = stdio.translate(s, "%d", str.toa(free_inodes));
                    s = stdio.translate(s, "%f", str.toa(free_blocks));
                    s = stdio.translate(s, "%i", format("{:x}", index));
                    s = stdio.translate(s, "%l", "32");
                    s = stdio.translate(s, "%n", name);
                    s = stdio.translate(s, "%s", str.toa(blk_size));
                    s = stdio.translate(s, "%S", str.toa(blk_size));
                    s = stdio.translate(s, "%t", format("{:x}", index));
                    s = stdio.translate(s, "%T", file_system_OS_type);
                    out.append(s + "\n");
                } else {
                    /*if (terse) {
                        out.append(format("{} {} {} {:x} {} {} {:x} {} {} {} {} {} {} {} {}\n",
                            name, file_size, n_blocks, mode, owner_id, group_id, device_id, index, n_links, major, minor, modified_at, last_modified, 0, blk_size));
                    } else {
                        out.append(format("   File: {}\n   Size: {}\t\tBlocks: {}\tIO Block: {}\t", name, file_size, n_blocks, blk_size));
                        out.append(ft == FT_REG_FILE && file_size == 0 ? "regular empty" : inode.file_type_description(mode));
                        out = str.aif(out, ft == FT_REG_FILE || ft == FT_BLKDEV || ft == FT_CHRDEV, " file");
                        out.append(format("\nDevice: {:x}h/{}d\tInode: {}\tLinks: {}", device_id, device_id, index, n_links));
                        if (ft == FT_BLKDEV || ft == FT_CHRDEV)
                            out.append(format("\tDevice type: {},{}\n", major, minor));
                        out.append(format("\nAccess: ({}/{})  Uid: ({}/{})  Gid: ({}/{})\nModify: {}\nChange: {}\n Birth: -\n",
                            mode & 0x01FF, inode.permissions(mode), owner_id, s_owner, group_id, s_group, fmt.ts(modified_at), fmt.ts(last_modified)));
                    }*/
                    if (ft == FT_SYMLINK) {
                        (, string target, ) = dirent.get_symlink_target(ino, data[index]).unpack();
                        name.append(" -> " + target);
                    }

                    string s = sf;
                    s = stdio.translate(s, "%a", str.toa(mode & 0x01FF));
                    s = stdio.translate(s, "%A", inode.permissions(mode));
                    s = stdio.translate(s, "%b", str.toa(n_blocks));
                    s = stdio.translate(s, "%B", str.toa(blk_size));
                    s = stdio.translate(s, "%C", "");
                    s = stdio.translate(s, "%d", str.toa(device_id));
                    s = stdio.translate(s, "%D", format("{:x}", device_id));
                    s = stdio.translate(s, "%f", format("{:x}", mode));
                    s = stdio.translate(s, "%F", inode.file_type_description(mode));
                    s = stdio.translate(s, "%g", str.toa(group_id));
                    s = stdio.translate(s, "%G", s_group);
                    s = stdio.translate(s, "%h", str.toa(n_links));
                    s = stdio.translate(s, "%i", str.toa(index));
                    s = stdio.translate(s, "%n", name);
                    s = stdio.translate(s, "%o", str.toa(blk_size));
                    s = stdio.translate(s, "%s", str.toa(file_size));
                    s = stdio.translate(s, "Device type: %t,%T", ft == FT_BLKDEV || ft == FT_CHRDEV ? format("Device type: {},{}", major, minor) : "");
                    s = stdio.translate(s, "%t", format("{:x}", major));
                    s = stdio.translate(s, "%T", format("{:x}", minor));
                    s = stdio.translate(s, "%u", str.toa(owner_id));
                    s = stdio.translate(s, "%U", s_owner);
                    s = stdio.translate(s, "%w", "-");
                    s = stdio.translate(s, "%W", "0");
                    s = stdio.translate(s, "%y", fmt.ts(modified_at));
                    s = stdio.translate(s, "%Y", format("{}", modified_at));
                    s = stdio.translate(s, "%z", fmt.ts(last_modified));
                    s = stdio.translate(s, "%Z", format("{}", last_modified));
                    out.append(s + "\n");
                }
            } else {
                errors.push(Err(0, er.ENOENT, name));
                ec = EXECUTE_FAILURE;
            }
        }
        ec = err.empty() && errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"stat",
"[OPTION]... FILE...",
"display file or file system status",
"Display file or file system status.",
"-L      follow links\n\
-f      display file system status instead of file status\n\
-c      use the specified FORMAT instead of the default; output a newline after each use of FORMAT\n\
-t      print the information in terse form\n\
The valid format sequences for files (without -f):\n\
  %a   access rights in octal\n\
  %A   access rights in human readable form\n\
  %b   number of blocks allocated (see %B)\n\
  %B   the size in bytes of each block reported by %b\n\
  %C   SELinux security context string\n\
  %d   device number in decimal\n\
  %D   device number in hex\n\
  %f   raw mode in hex\n\
  %F   file type\n\
  %g   group ID of owner\n\
  %G   group name of owner\n\
  %h   number of hard links\n\
  %i   inode number\n\
  %m   mount point\n\
  %n   file name\n\
  %N   quoted file name with dereference if symbolic link\n\
  %o   optimal I/O transfer size hint\n\
  %s   total size, in bytes\n\
  %t   major device type in hex, for character/block device special files\n\
  %T   minor device type in hex, for character/block device special files\n\
  %u   user ID of owner\n\
  %U   user name of owner\n\
  %w   time of file birth, human-readable; - if unknown\n\
  %W   time of file birth, seconds since Epoch; 0 if unknown\n\
  %y   time of last data modification, human-readable\n\
  %Y   time of last data modification, seconds since Epoch\n\
  %z   time of last status change, human-readable\n\
  %Z   time of last status change, seconds since Epoch\n\n\
Valid format sequences for file systems:\n\
  %a   free blocks available to non-superuser\n\
  %b   total data blocks in file system\n\
  %c   total file nodes in file system\n\
  %d   free file nodes in file system\n\
  %f   free blocks in file system\n\
  %i   file system ID in hex\n\
  %l   maximum length of filenames\n\
  %n   file name\n\
  %s   block size (for faster transfers)\n\
  %S   fundamental block size (for block counts)\n\
  %t   file system type in hex\n\
  %T   file system type in human readable form\n\
-t is equivalent to the following FORMAT:\n\
    %n %s %b %f %u %g %D %i %h %t %T %Y %Z %W %o %C\n\
-t -f is equivalent to the following FORMAT:\n\
    %n %i %l %t %s %S %b %f %a %c %d",
"",
"Written by Boris",
"File creation time, maximum length of filenames, file system type in hex, fundametal block size\n\
and some other attributes are not yet supported",
"",
"0.01");
    }

}
