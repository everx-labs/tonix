pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract paste is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] params, string flags, ) = arg.get_env(argv);

        for (string s_arg: params) {
            (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN) {
                string text = fs.get_file_contents(index, inodes, data);
                (string[] lines, uint n_lines) = stdio.split(text, "\n");

                string line_delimiter = arg.flag_set("z", flags) ? "\x00" : "\n";
                for (uint i = 0; i < n_lines; i++) {
                    (string[] texts_s, uint n_fields) = stdio.split(lines[i], "\n");
                    for (uint j = 0; j < n_fields; j++)
                        out.append(texts_s[j] + line_delimiter);
                }
            } else {
                err.append("Failed to resolve relative path for" + s_arg + "\n");
                ec = EXECUTE_FAILURE;
            }
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"paste",
"[OPTION]... [FILE]...",
"merge lines of files",
"Write lines consisting of the sequentially corresponding lines from each FILE, separated by TABs, to standard output.",
"-s      paste one file at a time instead of in parallel\n\
-z      line delimiter is NUL, not newline",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
