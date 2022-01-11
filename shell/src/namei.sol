pragma ton-solidity >= 0.53.0;

import "Utility.sol";
import "../lib/libuadm.sol";

contract namei is Utility, libuadm {

    function exec(string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);
        for (string arg: params) {
            (, uint8 ft, uint16 parent, ) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_namei(flags, arg, parent, inodes, data) + "\n");
            else
                err.append("Failed to resolve relative path for" + arg + "\n");
        }
    }

    function _namei(string f, string path, uint16 parent, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out) {
        bool modes = _flag_set("m", f) || _flag_set("l", f);
        bool owners = _flag_set("o", f) || _flag_set("l", f);

        out.append("f: " + path + "\n");
        string[] parts = _disassemble_path(path);
        uint len = parts.length;
        uint16 cur_dir = parent;
        for (uint i = len; i > 0; i--) {
            string part = parts[i - 1];
            (uint16 ino, uint8 ft) = _lookup_dir(inodes[cur_dir], data[cur_dir], part);
            (uint16 mode, uint16 owner_id, uint16 group_id, , , , , , , ) = inodes[ino].unpack();
            string s_owner = _get_user_name(owner_id, inodes, data);
            string s_group = _get_group_name(group_id, inodes, data);

            out.append(" " + (modes ? _permissions(mode) : _file_type_sign(ft)) + " " + (owners ? s_owner + " "  + s_group + " " : "") + part + "\n");
            cur_dir = ino;
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return (
            "namei",
            "follow a pathname until a terminal point is found",
            "[options] pathname...",
            "Interprets its arguments as pathnames to any type of Unix file (symlinks, files, directories, and so forth). namei then follows each pathname until an endpoint is found (a file, a directory, a device node, etc). If it finds a symbolic link, it shows the link, and starts following it, indenting the output to show the context.",
            "xmolnv",
            1,
            M, [
                "show mount point directories with a 'D'",
                "show the mode bits of each file",
                "show owner and group name of each file",
                "use a long listing format (-m -o -v)",
                "don't follow symlinks",
                "vertical align of modes and owners"]);
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
