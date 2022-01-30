pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract namei is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err, Err[] errors) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);
        (mapping (uint16 => string) user, mapping (uint16 => string) group) = arg.get_users_groups(argv);

        for (string s_arg: params) {
            (, uint8 ft, uint16 parent, ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_namei(flags, s_arg, parent, inodes, data, user, group) + "\n");
            else
                errors.push(Err(0, er.ENOENT, s_arg));
        }
        ec = errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
        err = "";
    }

    function _namei(string f, string s_path, uint16 parent, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data, mapping (uint16 => string) user, mapping (uint16 => string) group) internal pure returns (string out) {
        bool modes = arg.flag_set("m", f) || arg.flag_set("l", f);
        bool owners = arg.flag_set("o", f) || arg.flag_set("l", f);

        out.append("f: " + s_path + "\n");
        string[] parts = path.disassemble_path(s_path);
        uint len = parts.length;
        uint16 cur_dir = parent;

        for (uint i = len; i > 0; i--) {
            string part = parts[i - 1];
            (uint16 ino, uint8 ft) = fs.lookup_dir(inodes[cur_dir], data[cur_dir], part);
            (uint16 mode, uint16 owner_id, uint16 group_id, , , , , , , ) = inodes[ino].unpack();
            string s_owner = user[owner_id];
            string s_group = group[group_id];
            out.append(" " + (modes ? inode.permissions(mode) : inode.file_type_sign(ft)) + " " + (owners ? s_owner + " "  + s_group + " " : "") + part + "\n");
            cur_dir = ino;
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"namei",
"[options] pathname...",
"follow a pathname until a terminal point is found",
"Interprets its arguments as pathnames to any type of Unix file (symlinks, files, directories, and so forth). namei then follows each pathname until an endpoint is found (a file, a directory, a device node, etc). If it finds a symbolic link, it shows the link, and starts following it, indenting the output to show the context.",
"-x      show mount point directories with a 'D'\n\
-m      show the mode bits of each file\n\
-o      show owner and group name of each file\n\
-l      use a long listing format (-m -o -v)\n\
-n      don't follow symlinks\n\
-v      vertical align of modes and owners",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
