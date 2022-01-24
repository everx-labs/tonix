pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract tail is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] v_args, string flags, ) = arg.get_env(argv);
        string[] params;
        for (string s_arg: v_args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN) {
                (string s_out, string s_err) = _tail(flags, _get_file_contents(index, inodes, data), s_arg, params);
                if (s_err.empty())
                    out.append(s_out + "\n");
                else {
                    err.append(s_err + "\n");
                    ec = EXECUTE_FAILURE;
                }
            } else
                params.push(s_arg);
        }
    }

    function _tail(string flags, string texts, string s_arg, string[] params) private pure returns (string out, string err) {
        (string[] text, ) = stdio.split(texts, "\n");
        (bool num_lines, bool never_headers, bool always_headers, bool null_delimiter, , , ,) = arg.flag_values("nqvz", flags);
        string line_delimiter = null_delimiter ? "\x00" : "\n";
        string file_name = s_arg;
        uint n_lines = 10;
        uint len = text.length;
        uint n_params = params.length;

        if (num_lines && n_params > 0) {
            n_lines = stdio.atoi(params[0]);
            if (n_lines < 1)
                return (out, "error");
        }

        if (n_lines > len)
            n_lines = len;

        if (!file_name.empty() && (always_headers || !never_headers))
             out = "==> " + file_name + " <==\n";

        for (uint i = len - n_lines; i < len; i++)
            out.append(text[i] + line_delimiter);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"tail",
"[OPTION]... [FILE]...",
"output the last part of files",
"Print the last 10 lines of each FILE to standard output. With more than one FILE, precede each with a header giving the file name.",
"-n      output the last NUM lines, instead of the last 10;  or use -n +NUM to output starting with line NUM\n\
-q      never output headers giving file names\n\
-v      always output headers giving file names\n\
-z      line delimiter is NUL, not newline",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
