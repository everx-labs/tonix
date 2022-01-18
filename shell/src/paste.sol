pragma ton-solidity >= 0.54.0;

import "Utility.sol";

contract paste is Utility {

    function exec(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (string[] params, string flags, ) = _get_args(args);
        for (string arg: params) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN) {
                string text = _get_file_contents(index, inodes, data);
                (string[] lines, uint n_lines) = _split(text, "\n");

                string line_delimiter = _flag_set("z", flags) ? "\x00" : "\n";
                for (uint i = 0; i < n_lines; i++) {
                    (string[] texts_s, uint n_fields) = _split(lines[i], "\n");
                    for (uint j = 0; j < n_fields; j++)
                        out.append(texts_s[j] + line_delimiter);
                }
            } else {
                err.append("Failed to resolve relative path for" + arg + "\n");
                ec = EXECUTE_FAILURE;
            }
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("paste", "merge lines of files", "[OPTION]... [FILE]...",
            "Write lines consisting of the sequentially corresponding lines from each FILE, separated by TABs, to standard output.",
            "sz", 1, M, [
            "paste one file at a time instead of in parallel",
            "line delimiter is NUL, not newline"]);
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
