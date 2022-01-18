pragma ton-solidity >= 0.54.0;

import "Utility.sol";

contract cut is Utility {

    function exec(string args, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        err = "";
        (string[] v_args, string flags, ) = _get_args(args);
        string[] params;
        for (string arg: v_args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_cut(flags, _get_file_contents(index, inodes, data), params) + "\n");
            else
                params.push(arg);
        }
    }

    function _cut(string flags, string text, string[] params) private pure returns (string out) {
        (string[] lines, uint n_lines) = _split(text, "\n");
        bool set_fields = _flag_set("f", flags);
        bool use_delimiter = _flag_set("d", flags);
        bool only_delimited = _flag_set("s", flags);
        string line_delimiter = _flag_set("z", flags) ? "\x00" : "\n";
        string delimiter = "\t";
        uint16 field;
        uint n_params = params.length;

        if (!params.empty() && use_delimiter) {
            delimiter = params[0];
            if (set_fields && n_params > 1)
                field = _atoi(params[1]);
        }

        for (uint i = 0; i < n_lines; i++) {
            (string[] fields, uint n_fields) = _split(lines[i], delimiter);
            string matched;
            if (field < n_fields)
                matched = fields[field];
            if (!matched.empty() && !(only_delimited && n_fields == 1))
                out.append(matched + line_delimiter);
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("cut", "remove sections from each line of files", "OPTION... [FILE]...",
            "Print selected parts of lines from each FILE to standard output.",
            "fsz", 0, 1, [
            "select only these fields; also print any line that contains no delimiter character, unless the -s option is specified",
            "do not print lines not containing delimiters",
            "line delimiter is NUL, not newline empty"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"cut",
"OPTION... [FILE]...",
"remove sections from each line of files",
"Print selected parts of lines from each FILE to standard output.",
"-f     select only these fields; also print any line that contains no delimiter character, unless the -s option is specified\n\
-s      do not print lines not containing delimiters\n\
-z      line delimiter is NUL, not newline empty",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}
