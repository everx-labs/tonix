pragma ton-solidity >= 0.62.0;

import "Utility.sol";

contract mount is Utility {

    uint16 constant SUCCESS         = 0;
    uint16 constant INVOC_PERM      = 1;  // incorrect invocation or permissions
    uint16 constant SYSTEM_ERROR    = 2;  // system error (out of memory, cannot fork, no more loop devices)
    uint16 constant INTERNAL_ERROR  = 4;  // internal mount bug
    uint16 constant USER_INTERRUPT  = 8;  // user interrupt
    uint16 constant ERR_WRITE_MTAB  = 16; // problems writing or locking /etc/mtab
    uint16 constant MOUNT_FAILURE   = 32; // mount failure
    uint16 constant SOME_SUCCEEDED  = 64; // some mount succeeded

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
        string fstype = p.opt_value("t");
//        (bool force, bool use_group_id, bool is_system_group, , , , , ) = arg.flag_values("fgr", flags);
        string mountinfo; // = fs.get_file_contents_at_path("/proc/self/mountinfo", inodes, data);
//        string fstab = fs.get_file_contents_at_path("/etc/fstab", inodes, data);
//        string mtab = fs.get_file_contents_at_path("/etc/mtab", inodes, data);
        uint n_params = params.length;
        if (n_params == 2) {
            // device dir
        } else if (n_params == 1) {
//            string spath = params[0];
            // device/dir
        } else if (n_params == 0) {
            // either -l or -a
            // -l
            (string[] lines, ) = mountinfo.split("\n");
            for (string line: lines) {
                (string[] fields, uint n_fields) = line.split(" ");
                if (n_fields > 6) {
//                    uint16 mount_id = str.toi(fields[0]);
//                    uint16 parent_id = str.toi(fields[1]);
//                    (string smajor, string sminor) = str.split(fields[2], ":");
//                    uint8 major_id = uint8(str.toi(smajor));
//                    uint8 minor_id = uint8(str.toi(sminor));
//                    string root = fields[3];
                    string mountpoint = fields[4];
                    string options = fields[5];
//                    string separator = fields[6];
                    string fs_type = n_fields > 7 ? fields[7] : "";
                    string source = n_fields > 8 ? fields[8] : "";
//                    string super_options = n_fields > 9 ? fields[9] : "";
                    p.puts(source + " on " + mountpoint + " type " + fs_type + " (" + options + ")");
                }
            }
        }

    }
/*
36 35 98:0 /mnt1 /mnt2 rw,noatime master:1 - ext3 /dev/root rw,errors=continue
(1)(2)(3)   (4)   (5)      (6)      (7)   (8) (9)   (10)         (11)

(1) mount ID:  unique identifier of the mount (may be reused after umount)
(2) parent ID:  ID of parent (or of self for the top of the mount tree)
(3) major:minor:  value of st_dev for files on filesystem
(4) root:  root of the mount within the filesystem
(5) mount point:  mount point relative to the process's root
(6) mount options:  per mount options
(7) optional fields:  zero or more fields of the form "tag[:value]"
(8) separator:  marks the end of the optional fields
(9) filesystem type:  name of filesystem of the form "type[.subtype]"
(10) mount source:  filesystem specific information or "none"
(11) super options:  per super block options
*/
    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"mount",
"[-l]\t-a [-fnrvw]\t[-fnrsvw] [-o options] device|dir\t[-fnrsvw] [-t fstype] [-o options] device dir",
"mount a filesystem",
"Attach the filesystem found on some device to the file tree",
"-a      mount all filesystems mentioned in fstab\n\
-c      don't canonicalize paths\n\
-f      dry run; skip the mount syscall\n\
-T      alternative file to /etc/fstab\n\
-l      show also filesystem labels\n\
-n      don't write to /etc/mtab\n\
-r      mount the filesystem read-only\n\
-v      say what is being done\n\
-w      mount the filesystem read-write (default)\n\
-N      perform mount in another namespace\n\
-B      mount a subtree somewhere else\n\
-M      move a subtree to some other place",
"",
"Written by Boris",
"",
"umount, findmnt, losetup, mke2fs",
"0.02");
    }

}
