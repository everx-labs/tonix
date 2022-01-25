pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract ld is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        return _induce(session, input, inodes, data);
    }

    function induce(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        return _induce(session, input, inodes, data);
    }

    function _induce(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (string out, Action file_action, Ar[] ars, Err[] errors) {
        (, string[] args, uint flags) = input.unpack();

        bool output_map_file = (flags & _M) > 0;
        bool no_page_align_flag = (flags & _n) > 0;
        bool no_page_align_no_ro_flag = (flags & _N) > 0;
        bool use_out_file_name = (flags & _o) > 0;
        bool optimize = (flags & _O) > 0;
        bool gen_relocations = (flags & _q) > 0;
        bool relocatable_output = (flags & _r) > 0;
        bool just_link = (flags & _R) > 0;
        bool strip_all = (flags & _s) > 0;
        bool strip_debug = (flags & _S) > 0;
        bool print_version = (flags & _v) > 0;

        uint n_args = args.length;
        string object_file_name;
        if (print_version)
            out = "ld (Tonix binutils 0.01\n";
        if (n_args > 0) {
            object_file_name = args[0];
            string header = strip_debug ? "" : "set -x\n\n";
            string binary_file = header + _gen_binary(object_file_name);
            out.append(binary_file);
            if (n_args > 1 && use_out_file_name) {
                uint16 ic = sb.get_inode_count(inodes);
                string out_file_path = args[1];
                file_action = Action(IO_CREATE_FILES, 1);
                mapping (uint16 => string[]) parent_dirs;

                (uint16 index, uint8 ft, uint16 parent, uint16 dir_index) = fs.resolve_relative_path(out_file_path, session.wd, inodes, data);
                (string dir_name, string file_name) = path.dir(out_file_path);
                if (dir_index == 0) {
                    ars.push(Ar(IO_MKFILE, FT_REG_FILE, index, dir_index, file_name, binary_file));
                    parent_dirs[parent].push(dirent.dir_entry_line(ic, file_name, FT_REG_FILE));
                    ars.push(Ar(IO_MKBIN, FT_REG_FILE, index, dir_index, out_file_path, binary_file));
                    ic++;
                }
                for ((uint16 dir_i, string[] added_dirents): parent_dirs) {
                    uint16 n_dirents = uint16(added_dirents.length);
                    if (n_dirents > 0)
                        ars.push(Ar(IO_ADD_DIR_ENTRY, FT_DIR, dir_i, n_dirents, dir_name, stdio.join_fields(added_dirents, "\n")));
                }
            }

        }
    }

    function _gen_binary(string command_name) internal pure returns (string out) {
        out = _gen_defs(command_name) + _gen_args(command_name) + _gen_filter(command_name) + _gen_run(command_name) + _gen_call(command_name);
    }

    function _gen_defs(string command_name) internal pure returns (string out) {
        return "fn=$1\nboc=vfs/tmp/bin/" + command_name + ".boc\nabi=build/" + command_name + ".abi.json\n\n";
    }

    function _gen_call(string command_name) internal pure returns (string out) {
        return "args >vfs/tmp/" + command_name + "_$fn.args\nrun >vfs/tmp/" + command_name + "_$fn.out\nfilter vfs/tmp/" + command_name + "_$fn.out\n";
    }

    function _gen_args(string /*command_name*/) internal pure returns (string) {
        string body = _gen_comparison("$fn", "exec", "jq -s 'add' vfs/tmp/session vfs/tmp/getopt_exec.out vfs/tmp/fs", "echo '{}'");
        return _gen_function("args", body);
    }

    function _gen_filter(string command_name) internal pure returns (string) {
        string body = _gen_comparison("$fn", "get_command_info", "cp $1 vfs/usr/share/" + command_name + ".info", "jq -r '.out' <$1");
        return _gen_function("filter", body);
    }

    function _gen_run(string command_name) internal pure returns (string) {
        string body = "~/bin/tonos-cli -j run --boc $boc --abi $abi $fn vfs/tmp/" + command_name + "_$fn.args";
        return _gen_function("run", body);
    }

    function _tabulate(string text) internal pure returns (string out) {
        (string[] lines, ) = stdio.split(text, "\n");
        for (string line: lines)
            out.append("\t" + line + "\n");
    }

    function _gen_function(string function_name, string function_body) internal pure returns (string) {
        return function_name + "() {\n" + _tabulate(function_body) + "}\n\n";
    }

    function _gen_comparison(string arg_1, string arg_2, string branch_1, string branch_2) internal pure returns (string) {
        return "if [ \"" + arg_1 + "\" = \"" + arg_2 + "\" ]; then\n\t" + branch_1 + "\nelse\n\t" + branch_2 + "\nfi";
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"ld",
"[options] objfile ...",
"link binaries",
"Combines a number of object and archive files, relocates their data and ties up symbol references.",
"-M      print map file on standard output\n\
-n      do not page align data\n\
-N      do not page align data, do not make text readonly\n\
-o      set output file name\n\
-O      optimize output file\n\
-q      generate relocations in final output\n\
-r      generate relocatable output\n\
-R      just link symbols\n\
-s      strip all symbols\n\
-S      strip debugging symbols\n\
-v      print version information",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
