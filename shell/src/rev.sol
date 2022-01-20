pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract rev is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] v_args, , ) = _get_env(argv);

        for (string arg: v_args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_rev(_get_file_contents(index, inodes, data)) + "\n");
            else {
                err.append("Failed to resolve relative path for" + arg + "\n");
                ec = EXECUTE_FAILURE;
            }
        }
    }

    function _rev(string texts) private pure returns (string out) {
        (string[] text, ) = _split(texts, "\n");
        for (string line: text) {
            uint line_len = line.byteLength();
            for (uint i = line_len; i > 0; i--)
                out.append(line.substr(i - 1, 1));
            out.append("\n");
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        string[] empty;
        return ("rev", "reverse lines characterwise", "[option] [file...]",
            "Copies the specified files to standard output, reversing the order of characters in every line.",
            "", 1, M, empty);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"rev",
"[option] [file...]",
"reverse lines characterwise",
"Copies the specified files to standard output, reversing the order of characters in every line.",
"",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
