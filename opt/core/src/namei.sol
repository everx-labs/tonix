pragma ton-solidity >= 0.62.0;

import "putil_stat.sol";
import "path.sol";
contract namei is putil_stat {

    using dirent for s_dirent;
    function _main(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal override pure returns (shell_env e) {
        e = e_in;
        (bool fmodes, bool fowners, bool fmodes_owners, ) = e.flags_set("mol");
        bool modes = fmodes || fmodes_owners;
        bool owners = fowners || fmodes_owners;

        (mapping (uint16 => string) user, mapping (uint16 => string) group) = e.get_users_groups();

//        s_xpwddesc pd = p.p_pd;
        s_of root_dir = e.fopen("/", "r");
        for (string param: e.params()) {
            e.puts("f: " + param);
            bool is_abs = param.substr(0, 1) == "/";
            s_of start_dir = is_abs ? root_dir : e.cwd;
            uint16 cur_dir = start_dir.inono(); //start_dir;

            string cn = param;
            string p1;
            string p2;
            uint q;
            string lcn;
            uint16 mode;
            uint16 owner_id;
            uint16 group_id;

            if (is_abs) {
                e.puts(" d /");
                cn = param.substr(1);
            }
            s_dirent[] dents;
            while (true) {
                if (inodes.exists(cur_dir)) {
                    (mode, owner_id, group_id, , , , , , , ) = inodes[cur_dir].unpack();
                    if (libstat.is_dir(mode) && data.exists(cur_dir))
                        dents = dirent.parse_dirents(data[cur_dir]);
                    else
                        e.perror("inode " + str.toa(cur_dir) + " is not a valid directory");
                } else
                    e.perror("inode " + str.toa(cur_dir) + " not found");
                s_dirent d0;
                (p1, p2) = path.dir2(cn);
                q = cn.strchr('/');
                lcn = p1 == "." ? p2 : p1;
                d0 = _next_dirent(root_dir, dents, lcn);
                (uint16 ino, uint8 t, string name) = d0.unpack();
                string sowner = user[owner_id];
                string sgroup = group[group_id];
                if (!name.empty())
                    e.puts(" " + (modes ? libstat.perm_string(mode) : bytes(libstat.sign(t))) + " " + (owners ? sowner + " "  + sgroup + " " : "") + name);
                if (q == 0 || p2.empty())
                    break;
                cn = p2;
                cur_dir = ino;
            }
        }
    }

    function _next_dirent(s_of root_dir, s_dirent[] dde, string name) internal pure returns (s_dirent) {
        if (name == "/")
            return s_dirent(root_dir.inono(), libstat.FT_DIR, name);
        for (s_dirent de: dde)
            if (de.d_name == name)
                return de;
    }

    /*function _print_component(s_proc p, bool modes, bool owners, s_dirent de) internal pure returns (string) {
        if (!name.empty())
            return " " + (modes ? mode.perm_string() : dirent.sign(t)) + " " + (owners ? sowner + " "  + sgroup + " " : "") + name;
    }*/

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
"0.02");
    }
}
