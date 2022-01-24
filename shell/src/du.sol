pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract du is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);
        for (string s_arg: params) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_du(flags, s_arg, ft, index, inodes, data) + "\n");
            else {
                err.append("Failed to resolve relative path for" + s_arg + "\n");
                ec = EXECUTE_FAILURE;
            }
        }
    }

    function _du(string f, string path, uint8 ft, uint16 index, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string) {
        (bool null_line_end, bool count_files, bool human_readable, bool produce_total, bool summarize, , , ) = arg.flag_values("0ahcs", f);

        string line_end = null_line_end ? "\x00" : "\n";

        if (count_files && summarize)
            return "du: cannot both summarize and show all entries\n";
        Inode inode = inodes[index];
        bytes dir_data = data[index];
        uint32 file_size = inode.file_size;

        (string[][] table, uint32 total) = ft == FT_DIR ? _count_dir(f, path, inode, dir_data, inodes, data) :
            ([[fmt.scale(file_size, human_readable ? KILO : 1), path]], file_size);

        if (produce_total)
            table.push([format("{}", total), "total"]);

        return fmt.format_table(table, "\t", line_end, fmt.ALIGN_LEFT);
    }

    function _count_dir(string f, string dir_name, Inode inode, bytes dir_data, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string[][] lines, uint32 total) {
        (bool count_files, bool include_subdirs, bool human_readable, , , , , ) = arg.flag_values("aSh", f);

        (DirEntry[] contents, int16 status) = _read_dir_data(dir_data);

        if (status > 0) {
            uint len = uint(status);
            for (uint j = 2; j < len; j++) {
                (uint8 ft, string name, uint16 index) = contents[j].unpack();
                if (ft == FT_UNKNOWN)
                    continue;
                Inode sub_inode = inodes[index];
                bytes sub_dir_data = data[index];

                name = dir_name + "/" + name;
                if (ft == FT_DIR) {
                    (string[][] sub_lines, uint32 sub_total) = _count_dir(f, name, sub_inode, sub_dir_data, inodes, data);
                    for (string[] line: sub_lines)
                        lines.push(line);
                    if (include_subdirs)
                        total += sub_total;
                } else {
                    uint32 file_size = sub_inode.file_size;
                    total += file_size;
                    if (count_files)
                        lines.push([fmt.scale(file_size, human_readable ? KILO : 1), name]);
                }
            }
            total += inode.file_size;
            lines.push([fmt.scale(total, human_readable ? KILO : 1), dir_name]);
        } else
            lines.push(["0", "?" + dir_name + "?"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"du",
"[OPTION]... [FILE]...",
"estimate disk usage",
"Summarize disk usage of the set of FILEs, recursively for directories.",
"-a      write counts for all files, not just directories\n\
-b      block size = 1 byte\n\
-c      produce a grand total\n\
-D      dereference only symlinks that are listed on the command line\n\
-h      print sizes in human readable format (e.g., 12K 1M)\n\
-H      equivalent to -D\n\
-k      block size = 1K\n\
-L      dereference all symbolic links\n\
-l      count sizes many times if hard linked\n\
-m      block size = 1M\n\
-P      don't follow any symbolic links (this is the default)\n\
-S      for directories do not include size of subdirectories\n\
-s      display only a total for each argument\n\
-x      skip directories on different file systems\n\
-0      end each output line with NUL, not newline",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
