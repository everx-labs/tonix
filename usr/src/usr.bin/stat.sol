pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract stat is Utility {

    function _fmtstr(string s, string fstr, string[] values) internal pure returns (string res) {
        uint len = math.min(fstr.byteLength(), values.length);
        res = s;
        for (uint i = 0; i < len; i++)
            res.trs("%" + fstr.substr(i, 1), values[i]);
    }

    function _fmtstrint(string s, string fstr, uint16[] values) internal pure returns (string res) {
        uint len = math.min(fstr.byteLength(), values.length);
        res = s;
        for (uint i = 0; i < len; i++)
            res.trs("%" + fstr.substr(i, 1), str.toa(values[i]));
    }

    function main(svm sv_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (svm sv) {
        sv = sv_in;
        s_proc p = sv.cur_proc;
        s_vmem[] vm = sv.vmem;
        uma_zone[] uz = sv.sz;
        string[] params = p.params();
        (bool terse, bool fs_info, bool format_str, ) = p.flags_set("tfc");
        string sf = format_str ? p.opt_value("c") : terse ?
            fs_info ? "%n %i %l %t %s %S %b %f %a %c %d" : "%n %s %b %f %u %g %D %i %h %t %T %Y %Z %W %o %C" :
            fs_info ? "  File: \"%n\"\n    ID: %i Namelen: 20\tType: %T\nBlock size: %s\tFundamental block size: %S\n\
Blocks: Total: %b\tFree: %f\tAvailable: %a\nInodes: Total: %c\tFree: %d\n" :
"   File: %n\n   Size: %s\t\tBlocks: %b\tIO Block: %o\t%F\nDevice: %Dh/%dd\tInode: %i\tLinks: %h\tDevice type: %t,%T\n\
Access: (%a/%A)  Uid: (%u/%U)  Gid: (%g/%G)\nModify: %y\nChange: %z\n Birth: -\n";
        (mapping (uint16 => string) user, mapping (uint16 => string) group) = p.get_users_groups();
        string out;
        for (string name: params) {
            s_of f = p.fopen(name, "r");
            if (!f.ferror()) {
                (uint16 st_dev, uint16 st_ino, uint16 st_mode, uint16 st_nlink, uint16 st_uid, uint16 st_gid, uint16 st_rdev, uint32 st_size,
                    uint16 st_blksize, uint16 st_blocks, uint32 st_mtim, uint32 st_ctim) = xio.st(f.attr).unpack();
                (string major, string minor) = st_mode.is_block_dev() || st_mode.is_char_dev() ? inode.get_device_version(st_rdev) : ("0", "0");

                if (fs_info) {
                    (, , string fstype, uint16 inode_count, uint16 block_count, uint16 free_inodes, uint16 free_blocks, uint16 block_size, , , , , , , ,) =
                        sb.get_sb(inodes, data).unpack();
                    string s = _fmtstrint(sf, "abcdfilsS", [free_blocks, block_count + free_blocks, inode_count + free_inodes,
                        free_inodes, free_blocks, st_ino, 32, block_size, block_size]);
                    s = _fmtstr(s, "ntT", [name, format("{:x}", st_ino), fstype]);
                    out.append(s + "\n");
                } else {
                    if (st_mode.is_symlink()) {
                        (, string target, ) = udirent.get_symlink_target(inodes[st_ino], data[st_ino]).unpack();
                        name.append(" -> " + target);
                    }
                    sf.trs("Device type: %t,%T", st_mode.is_block_dev() || st_mode.is_char_dev() ? format("Device type: {},{}", major, minor) : "");
                    out.append(_fmtstr(sf, "aAbBCdDfFgGhinostTuUwWyYzZ", [str.toa(st_mode & 0x01FF), inode.permissions(st_mode), str.toa(st_blocks),
                        str.toa(st_blksize), "", str.toa(st_dev), format("{:x}", st_dev), format("{:x}", st_mode), st_mode.file_type_description(),
                        str.toa(st_gid), group[st_gid], str.toa(st_nlink), str.toa(st_ino), name, str.toa(st_blksize), str.toa(st_size), format("{:x}", major),
                        format("{:x}", minor), str.toa(st_uid), user[st_uid], "-", "0", fmt.ts(st_mtim), format("{}", st_mtim), fmt.ts(st_ctim), format("{}", st_ctim)]) + "\n");
                }
            }
        }
        p.puts(out);
        sv.cur_proc = p;
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
"File creation time, maximum length of filenames, file system type in hex, fundamental block size\n\
and some other attributes are not yet supported",
"",
"0.02");
    }

}
