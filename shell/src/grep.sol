pragma ton-solidity >= 0.53.0;

import "Utility.sol";

contract grep is Utility {

    function exec(string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        (string[] args, string flags, ) = _get_args(e[IS_ARGS]);
        string[] params;
        string[] f_args;
        uint n_args = args.length;

        for (uint i = 0; i < n_args; i++) {
            string arg = args[i];
            (, uint8 ft, , ) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft == FT_UNKNOWN)
                params.push(arg);
            else
                f_args.push(arg);
        }

        for (string arg: f_args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_grep(flags, _get_file_contents(index, inodes, data), params) + "\n");
            else
                err.append("Failed to resolve relative path for" + arg + "\n");
        }
    }

    function _grep(string flags, string text, string[] params) private pure returns (string out) {
        (string[] lines, uint n_lines) = _split(text, "\n");
        bool invert_match = _flag_set("v", flags);
        bool match_lines = _flag_set("x", flags);
        uint n_params = params.length;

        string pattern;
        if (n_params > 0)
            pattern = params[0];

        uint p_len = pattern.byteLength();
        for (uint i = 0; i < n_lines; i++) {
            string line = lines[i];
            if (line.empty())
                continue;
            bool found = false;
            if (match_lines)
                found = line == pattern;
            else {
                if (p_len > 0) {
                    uint l_len = line.byteLength();
                    for (uint j = 0; j < l_len - p_len; j++)
                        if (line.substr(j, p_len) == pattern) {
                            found = true;
                            break;
                        }
                }
            }
            if (invert_match)
                found = !found;
            if (found || p_len == 0)
                out.append(line + "\n");
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("grep", "print lines that match patterns", "[OPTION...] PATTERNS [FILE...]",
            "Searches for PATTERNS in each FILE and prints each line that matches a pattern.",
            "vx", 2, M, [
            "invert the sense of matching, to select non-matching lines",
            "select only those matches that exactly match the whole line"]);
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
