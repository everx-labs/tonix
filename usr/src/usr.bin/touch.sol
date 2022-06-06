pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract touch is Utility {

  function induce(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Ar[] ars, Err[] /*errors*/) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(args);
        Arg[] arg_list;
        for (string param: params) {
            (uint16 index, uint8 t, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(param, wd, inodes, data);
            arg_list.push(Arg(param, t, index, parent, dir_index));
        }
        uint16 ic = sb.get_inode_count(inodes);
        bool create_files = !arg.flag_set("c", flags);
        bool update_if_exists = !arg.flag_set("m", flags);
        mapping (uint16 => string[]) parent_dirs;

        for (Arg a: arg_list) {
            (string spath, , uint16 index, uint16 parent, uint16 dir_index) = a.unpack();
            (, string file_name) = path.dir(spath);
            if (dir_index == 0 && create_files) {
                string contents;
                ars.push(Ar(aio.MKFILE, index, file_name, contents));
                parent_dirs[parent].push(udirent.dir_entry_line(ic, file_name, ft.FT_REG_FILE));
                ic++;
            } else if (update_if_exists)
                ars.push(Ar(aio.UPDATE_TIME, index, spath, ""));
        }
        for ((uint16 dir_i, string[] added_dirents): parent_dirs) {
            uint16 n_dirents = uint16(added_dirents.length);
            if (n_dirents > 0)
                ars.push(Ar(aio.ADD_DIR_ENTRY, dir_i, "", libstring.join_fields(added_dirents, "\n")));
        }
        out = "";
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"touch",
"[OPTION]... FILE...",
"change file timestamps",
"Update the modification time of each FILE to the current time. A FILE argument that does not exist is created empty, unless -c is supplied.",
"-c      do not create any files\n\
-m      change only the modification time",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
