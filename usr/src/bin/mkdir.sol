pragma ton-solidity >= 0.61.0;

import "../include/Utility.sol";

contract mkdir is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        Err[] errors;
        Ar[] ars;
        (uint16 wd, , , ) = p.get_env();
        uint16 ic = sb.get_inode_count(inodes);
        s_dirent[] contents = p.p_args.ar_misc.pos_args;

        bool error_if_exists = !p.flag_set("p");
        bool report_actions = p.flag_set("v");
        mapping (uint16 => string[]) parent_dirs;

        for (s_dirent de: contents) {
            (uint16 index, uint8 t, string name) = de.unpack();
            uint16 parent = wd;
            if (t == ft.FT_UNKNOWN) {
                ars.push(Ar(aio.MKDIR, index, name, inode.get_dots(ic, parent)));
                parent_dirs[parent].push(udirent.dir_entry_line(ic, name, ft.FT_DIR));
                ic++;
                if (report_actions)
                    p.puts("mkdir: created directory" + str.squote(name));
            } else if (error_if_exists)
                errors.push(Err(0, er.EEXIST, name));
        }
        for ((uint16 dir_i, string[] added_dirents): parent_dirs) {
            uint16 n_dirents = uint16(added_dirents.length);
            if (n_dirents > 0)
                ars.push(Ar(aio.ADD_DIR_ENTRY, dir_i, "", libstring.join_fields(added_dirents, "\n")));
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"mkdir",
"[OPTION]... DIRECTORY...",
"make directories",
"Create the DIRECTORY(ies), if they do not already exist.",
"-m      set file mode (as in chmod), not a=rwx - umask\n\
-p      no error if existing, make parent directories as needed\n\
-v      print a message for each created directory",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
