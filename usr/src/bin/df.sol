pragma ton-solidity >= 0.61.0;

import "../include/Utility.sol";

contract df is Utility {

    function main(s_proc p_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p) {
        p = p_in;

        (, , string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes, uint16 free_blocks, , , , , , , , uint16 first_inode, ) = sb.get_sb(inodes, data).unpack();
        (bool human_readable, bool powers_of_1000, bool list_inodes, bool block_1k, bool posix_output, , , ) = p.flag_values("hHikP");

        string fs_name = file_system_OS_type;
        Column[] columns_format = [
            Column(true, 20, fmt.LEFT),
            Column(true, 11, fmt.RIGHT),
            Column(true, 6, fmt.RIGHT),
            Column(true, 9, fmt.RIGHT),
            Column(true, 9, fmt.RIGHT),
            Column(true, 15, fmt.LEFT)];

        string sunits;
        string sused;
        string savl;
        string sp_used;
        uint u_used = list_inodes ? (inode_count - first_inode) : block_count;
        uint u_avl = list_inodes ? free_inodes : free_blocks;
        uint u_units = u_used + u_avl;
        uint u_p_used = u_used * 100 / u_units;

        if (list_inodes) {
            sunits = "Inodes";
            sused = "IUsed";
            savl = "IFree";
            sp_used = "IUse%";
        } else if (human_readable || block_1k) {
            sunits = "Size";
            sused = "Used";
            savl = "Avail";
            sp_used = "Use%";
        } else if (posix_output || powers_of_1000) {
            sunits = "1024-blocks";
            sused = "Used";
            savl = "Available";
            sp_used = "Capacity%";
        } else {
            sunits = "1K-blocks";
            sused = "Used";
            savl = "Available";
            sp_used = "Use%";
        }

        string[] header = ["Filesystem", sunits, sused, savl, sp_used, "Mounted on"];
        string[] row0 = [fs_name, str.toa(u_units), str.toa(u_used), str.toa(u_avl), str.toa(u_p_used) + "%", "/"];

        p.puts(fmt.format_table_ext(columns_format, [header, row0], " ", "\n"));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"df",
"[OPTION]... [FILE]...",
"report file system disk space usage",
"Displays the amount of disk space available on the file system containing each file name argument.",
"-a      include pseudo, duplicate, inaccessible file systems\n\
-h      print sizes in powers of 1024 (e.g., 1023K)\n\
-H      print sizes in powers of 1000 (e.g., 1.1K)\n\
-i      list inode information instead of block usage\n\
-k      block size = 1K\n\
-l      limit listing to local file systems\n\
-P      use the POSIX output format\n\
-v      (ignored)",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
