pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract df is Utility {

    function exec(Session session, InputS input, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (string out) {
        (, , uint flags) = input.unpack();
        session.wd = session.wd;
        out = _df(flags, inodes, data);      // 1k
    }

    function _df(uint flags, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) private pure returns (string out) {
        (, , string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes, uint16 free_blocks, , , , , , , , uint16 first_inode, ) = _get_sb(inodes, data).unpack();
//        (, , string file_system_OS_type, uint16 inode_count, uint16 block_count, uint16 free_inodes, uint16 free_blocks, , , , , , , , uint16 first_inode, ) = _read_sb(inodes, data).unpack();

        bool human_readable = (flags & _h) > 0;
        bool powers_of_1000 = (flags & _H) > 0;
        bool list_inodes = (flags & _i) > 0;
        bool block_1k = (flags & _k) > 0;
        bool posix_output = (flags & _P) > 0;

        string fs_name = file_system_OS_type;
        Column[] columns_format = [
            Column(true, 20, ALIGN_LEFT),
            Column(true, 11, ALIGN_RIGHT),
            Column(true, 6, ALIGN_RIGHT),
            Column(true, 9, ALIGN_RIGHT),
            Column(true, 9, ALIGN_RIGHT),
            Column(true, 15, ALIGN_LEFT)];

        string s_units;
        string s_used;
        string s_avl;
        string s_p_used;
        uint u_used = list_inodes ? (inode_count - first_inode) : block_count;
        uint u_avl = list_inodes ? free_inodes : free_blocks;
        uint u_units = u_used + u_avl;
        uint u_p_used = u_used * 100 / u_units;

        if (list_inodes) {
            s_units = "Inodes";
            s_used = "IUsed";
            s_avl = "IFree";
            s_p_used = "IUse%";
        } else if (human_readable || block_1k) {
            s_units = "Size";
            s_used = "Used";
            s_avl = "Avail";
            s_p_used = "Use%";
        } else if (posix_output || powers_of_1000) {
            s_units = "1024-blocks";
            s_used = "Used";
            s_avl = "Available";
            s_p_used = "Capacity%";
        } else {
            s_units = "1K-blocks";
            s_used = "Used";
            s_avl = "Available";
            s_p_used = "Use%";
        }

        string[] header = ["Filesystem", s_units, s_used, s_avl, s_p_used, "Mounted on"];
        string[] row0 = [
                fs_name,
                format("{}", u_units),
                format("{}", u_used),
                format("{}", u_avl),
                format("{}%", u_p_used),
                "/"];

        out = _format_table_ext(columns_format, [header, row0], " ", "\n");
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return("df", "report file system disk space usage", "[OPTION]... [FILE]...",
            "Displays the amount of disk space available on the file system containing each file name argument.",
            "ahHiklPv", 1, M, [
            "include pseudo, duplicate, inaccessible file systems",
            "print sizes in powers of 1024 (e.g., 1023K)",
            "print sizes in powers of 1000 (e.g., 1.1K)",
            "list inode information instead of block usage",
            "block size = 1K",
            "limit listing to local file systems",
            "use the POSIX output format",
            "(ignored)"]);
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
