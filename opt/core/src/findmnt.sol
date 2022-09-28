pragma ton-solidity >= 0.62.0;

import "putil_stat.sol";

contract findmnt is putil_stat {

    function _main(shell_env e_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal override pure returns (shell_env e) {
        e = e_in;
        (bool flag_fstab_only, bool flag_mtab_only, , bool like_df, bool first_fs_only, bool no_headings,
            bool no_truncate, bool all_columns) = e.flag_values("smkDfnuo");
        bool df_style = like_df || all_columns;
        bool non_df_style = !like_df || all_columns;

        string[][] table;

        uint target_path_width = no_truncate ? 70 : 30;
        uint source_width = no_truncate ? 70 : 20;

        Column[] columns_format = [
            Column(non_df_style, target_path_width, fmt.LEFT),
            Column(true, source_width, fmt.LEFT),
            Column(true, 6, fmt.LEFT),
            Column(non_df_style, target_path_width, fmt.LEFT),
            Column(df_style, 6, fmt.RIGHT),
            Column(df_style, 6, fmt.RIGHT),
            Column(df_style, 6, fmt.RIGHT),
            Column(df_style, 4, fmt.RIGHT),
            Column(df_style, target_path_width, fmt.LEFT)];

        if (!no_headings)
            table = [["TARGET", "SOURCE", "FSTYPE", "OPTIONS", "SIZE", "USED", "AVAIL", "USE%", "TARGET"]];

        (, , , , uint16 block_count, , uint16 free_blocks, , , , , , , , , ) = sb.get_sb(inodes, data).unpack();

        uint u_used = block_count;
        uint u_avl = free_blocks;
        uint u_units = u_used + u_avl;
        uint u_p_used = u_used * 100 / u_units;

        string text;
        if (!flag_mtab_only)
            text = fs.get_file_contents_at_path("/etc/fstab", inodes, data);
        if (!flag_fstab_only)
            text.append(fs.get_file_contents_at_path("/etc/mtab", inodes, data));

        (string[] tab_lines, ) = text.split("\n");
        for (string line: tab_lines) {
            (string[] fields, uint n_fields) = line.split("\t");
            if (n_fields > 3) {
                table.push([
                    fields[1],
                    fields[0],
                    fields[2],
                    fields[3],
                    str.toa(u_units),
                    str.toa(u_used),
                    str.toa(u_avl),
                    str.toa(u_p_used) + "%",
                    fields[1]]);
                if (first_fs_only)
                    break;
            }
        }
        e.puts(fmt.format_table_ext(columns_format, table, " ", "\n"));
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"findmnt",
"[options]\t[options] device|mountpoint[options] [device...]",
"find a filesystem",
"List all mounted filesystems or search for a filesystem.",
"-s      search in static table of filesystems\n\
-m      search in table of mounted filesystems\n\
-k      search in kernel table of mounted filesystems (default)\n\
-A      disable all built-in filters, print all filesystems\n\
-b      print sizes in bytes rather than in human readable format\n\
-D      imitate the output of df(1)\n\
-f      print the first found filesystem only\n\
-n      don't print column headings\n\
-u      don't truncate text in columns",
"",
"Written by Boris",
"",
"",
"0.02");
    }

}
