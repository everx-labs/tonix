pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract rmdir is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        return _induce(session, input, inodes, data);
    }

    function induce(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        return _induce(session, input, inodes, data);
    }

    function _induce(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
//    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();
        Arg[] arg_list;
        for (string arg: args) {
            (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(arg, session.wd, inodes, data);
            arg_list.push(Arg(arg, ft, index, parent, dir_index));
        }
        (out, file_action, ars, errors) = _rmdir(flags, arg_list, inodes, data);
    }

    function _remove_dir_entries(string dir_list, string[] victims) internal pure returns (string contents) {
        contents = dir_list;
        for (string s: victims)
            contents = _translate(contents, s, "");
    }

    function _rmdir(uint flags, Arg[] arg_list, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out, Action action, Ar[] ars, Err[] errors) {
        bool verbose = (flags & _v) > 0;
        bool force_removal = (flags & _f) > 0;

        mapping (uint16 => string[]) victims;

        for (Arg arg: arg_list) {
            (string s, uint8 ft, uint16 iop, uint16 parent, uint16 dir_idx) = arg.unpack();
            out = _if(out, verbose, "rmdir: removing directory," + _quote(s) + "\n");
            if (iop >= INODES) {
                if (ft == FT_DIR) {
                    if (inodes[iop].n_links < 3) {
                        ars.push(Ar(IO_UNLINK, ft, iop, dir_idx, s, ""));
                        victims[parent].push(_dir_entry_line(iop, s, ft));
                    } else
                        errors.push(Err(0, ENOTEMPTY, s));
                } else
                    errors.push(Err(0, ENOTDIR, s));
            } else if (!force_removal)
                errors.push(Err(0, iop, s));
        }
        action = Action(IO_UNLINK_FILES, uint16(ars.length));

        for ((uint16 dir_i, string[] victim_dirents): victims)
            if (!victim_dirents.empty())
                ars.push(Ar(IO_UPDATE_DIR_ENTRY, FT_DIR, dir_i, 0, "", _remove_dir_entries(data[dir_i], victim_dirents)));
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("rmdir", "remove empty directories", "[OPTION]... DIRECTORY...",
            "Remove the DIRECTORY(ies), if they are empty.",
            "pv", 1, M, [
            "remove DIRECTORY and its ancestors; e.g., 'rmdir -p a/b/c' is similar to 'rmdir a/b/c a/b a'",
            "output a diagnostic for every directory processed"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"",
"OPTION... [FILE]...",
"",
"",
"-a     d",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
