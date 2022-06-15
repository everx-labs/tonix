pragma ton-solidity >= 0.61.0;

import "Utility.sol";
import "../lib/fts.sol";

contract du is Utility {

    function _indent(uint i) internal pure returns (string res) {
        repeat(i) {
            res.append(" ");
        }
    }

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
        (bool null_line_end, bool count_files, bool human_readable, bool produce_total, bool summarize, bool include_subdirs, , ) = p.flag_values("0ahcsS");
        string line_end = null_line_end ? "\x00" : "\n";
        if (count_files && summarize) {
            p.perror("cannot both summarize and show all entries");
            return p;
        }

        string so;

        (, , string argv) = p.get_args();
        for (string param: params) {
            s_of f = p.fopen(param, "r");
            s_fts file_system = fts.fts_open(argv, fts.FTS_COMFOLLOW | fts.FTS_NOCHDIR, 1);
            s_ftsent[] nodes;
            if (!f.ferror()) {
                nodes = fts.fts_read(file_system);
                for (s_ftsent node: nodes) {
                    uint16 fts_info = node.fts_info;
                    if (fts_info == fts.FTS_D || fts_info == fts.FTS_F || fts_info == fts.FTS_SL) {
                        so.append(_indent(uint(node.fts_level)) + node.fts_name + "\n");
                    }
                }
                (, uint16 st_ino, uint16 st_mode, , , , , uint32 st_size, , , , ) = xio.st(f.attr).unpack();
                uint16 index = st_ino;
                Inode inode = inodes[index];
                bytes dir_data = data[index];
                uint32 file_size = st_size;
                (string[][] table, uint32 total) = st_mode.is_dir() ? _count_dir(count_files, include_subdirs, human_readable, param, inode, dir_data, inodes, data) :
                    ([[fmt.scale(file_size, human_readable ? fmt.KILO : 1), param]], file_size);
                if (produce_total)
                    table.push([format("{}", total), "total"]);
                p.puts(fmt.format_table(table, "\t", line_end, fmt.LEFT));
            } else
                p.perror("cannot open");
            fts.fts_close(file_system);
        }
    }

    function _count_dir(bool count_files, bool include_subdirs, bool human_readable, string dir_name, Inode inode, bytes dir_data, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string[][] lines, uint32 total) {
        (DirEntry[] contents, int16 status) = udirent.read_dir_data(dir_data);

        if (status > 0) {
            uint len = uint(status);
            for (uint j = 2; j < len; j++) {
                (uint8 t, string name, uint16 index) = contents[j].unpack();
                if (t == ft.FT_UNKNOWN)
                    continue;
                Inode sub_inode = inodes[index];
                bytes sub_dir_data = data[index];

                name = dir_name + "/" + name;
                if (t == ft.FT_DIR) {
                    (string[][] sub_lines, uint32 sub_total) = _count_dir(count_files, include_subdirs, human_readable, name, sub_inode, sub_dir_data, inodes, data);
                    for (string[] line: sub_lines)
                        lines.push(line);
                    if (include_subdirs)
                        total += sub_total;
                } else {
                    uint32 file_size = sub_inode.file_size;
                    total += file_size;
                    if (count_files)
                        lines.push([fmt.scale(file_size, human_readable ? fmt.KILO : 1), name]);
                }
            }
            total += inode.file_size;
            lines.push([fmt.scale(total, human_readable ? fmt.KILO : 1), dir_name]);
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
"0.02");
    }

}
