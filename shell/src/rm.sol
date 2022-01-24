pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract rm is Utility {

    function _remove_dir_entries(string dir_list, string[] victims) internal pure returns (string contents) {
        contents = dir_list;
        for (string s: victims)
            contents = stdio.translate(contents, s, "");
    }

    function induce(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(args);
        Arg[] arg_list;
        for (string s_arg: params) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(s_arg, wd, inodes, data);
            arg_list.push(Arg(s_arg, ft, index, parent, dir_index));
        }
        (out, file_action, ars, errors) = _rm(flags, arg_list, inodes, data);
    }

    function _rm(string flags, Arg[] arg_list, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Action action, Ar[] ars, Err[] errors) {
        bool verbose = arg.flag_set("v", flags);
        bool remove_empty_dirs = arg.flag_set("d", flags);
        bool force_removal = arg.flag_set("f", flags);

        mapping (uint16 => string[]) victims;

        for (Arg a: arg_list) {
            (string s, uint8 ft, uint16 iop, uint16 parent, uint16 dir_idx) = a.unpack();
            if (iop >= INODES) {
                if (ft == FT_DIR) {
                    if (remove_empty_dirs) {
                        if (inodes[iop].n_links < 3) {
                            ars.push(Ar(IO_UNLINK, ft, iop, dir_idx, s, ""));
                            victims[parent].push(_dir_entry_line(iop, s, ft));
                        } else
                            errors.push(Err(0, ENOTEMPTY, s));
                    } else
                        errors.push(Err(0, EISDIR, s));
                } else {
                    ars.push(Ar(IO_UNLINK, ft, iop, dir_idx, s, ""));
                    if (inodes[iop].n_links < 2)
                        victims[parent].push(_dir_entry_line(iop, s, ft));
                    out = stdio.aif(out, verbose, "removed" + stdio.quote(s) + "\n");
                }
            } else if (!force_removal)
                errors.push(Err(0, iop, s));
        }
        action = Action(IO_UNLINK_FILES, uint16(ars.length));

        for ((uint16 dir_i, string[] victim_dirents): victims)
            if (!victim_dirents.empty())
                ars.push(Ar(IO_UPDATE_DIR_ENTRY, FT_DIR, dir_i, 0, "", _remove_dir_entries(data[dir_i], victim_dirents)));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"rm",
"[OPTION]... [FILE]...",
"remove files or directories",
"Remove each specified file. By default, it does not remove directories. Use -r option to remove each listed directory, too, along with all of its contents.",
"-f      ignore nonexistent files and arguments, never prompt\n\
-r      \n\
-R      remove directories and their contents recursively\n\
-d      remove empty directories\n\
-v      explain what is being done",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
