pragma ton-solidity >= 0.53.0;

import "Utility.sol";

contract head is Utility {

    function exec(string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (string[] args, string flags, ) = _get_args(e[IS_ARGS]);
        string[] params;

        for (string arg: args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN) {
                (string s_out, string s_err) = _head(flags, _get_file_contents(index, inodes, data), arg, params);
                if (s_err.empty())
                    out.append(s_out + "\n");
                else {
                    err.append(s_err + "\n");
                    ec = EXECUTE_FAILURE;
                }
            } else
                params.push(arg);
        }
    }

    function _head(string flags, string texts, string arg, string[] params) private pure returns (string out, string err) {
        (string[] text, ) = _split(texts, "\n");
        bool num_lines = _flag_set("n", flags);
        bool never_headers = _flag_set("q", flags);
        bool always_headers = _flag_set("v", flags);
        string line_delimiter = _flag_set("z", flags) ? "\x00" : "\n";
        uint len = text.length;
        string file_name = arg;
        uint n_lines = 10;
        uint n_params = params.length;

        if (num_lines && n_params > 0) {
            n_lines = _atoi(params[0]);
            if (n_lines < 1)
                return (out, "error");
        }
        if (n_lines > len)
            n_lines = len;

        if (!file_name.empty() && (always_headers || !never_headers))
             out = "==> " + file_name + " <==\n";

        for (uint i = 0; i < n_lines; i++)
            out.append(text[i] + line_delimiter);
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("head", "output the first part of files", "[OPTION]... [FILE]...",
            "Print the first 10 lines of each FILE to standard output. With more than one FILE, precede each with a header giving the file name.",
            "nqvz", 1, M, [
            "print the first NUM lines instead of the first 10;  with the leading '-', print all but the last  NUM lines of each file",
            "never print headers giving file names",
            "always print headers giving file names",
            "line delimiter is NUL, not newline"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"head",
"[OPTION]... [FILE]...",
"output the first part of files",
"Print the first 10 lines of each FILE to standard output. With more than one FILE, precede each with a header giving the file name.",
"-n      print the first NUM lines instead of the first 10;  with the leading '-', print all but the last  NUM lines of each file\n\
-q      never print headers giving file names\n\
-v      always print headers giving file names\n\
-z      line delimiter is NUL, not newline",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
