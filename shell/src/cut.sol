pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract cut is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        ec = EXECUTE_SUCCESS;
        err = "";
        (uint16 wd, string[] v_args, string flags, ) = arg.get_env(argv);
        string[] params;
        for (string s_arg: v_args) {
            (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN)
                out.append(_cut(flags, fs.get_file_contents(index, inodes, data), params) + "\n");
            else
                params.push(s_arg);
        }
    }

    function _cut(string flags, string text, string[] params) private pure returns (string out) {
        (string[] lines, uint n_lines) = stdio.split(text, "\n");
        bool set_fields = arg.flag_set("f", flags);
        bool use_delimiter = arg.flag_set("d", flags);
        bool only_delimited = arg.flag_set("s", flags);
        string line_delimiter = arg.flag_set("z", flags) ? "\x00" : "\n";
        string delimiter = "\t";
        uint16 field;
        uint n_params = params.length;

        if (!params.empty() && use_delimiter) {
            delimiter = params[0];
            if (set_fields && n_params > 1)
                field = stdio.atoi(params[1]);
        }

        for (uint i = 0; i < n_lines; i++) {
            (string[] fields, uint n_fields) = stdio.split(lines[i], delimiter);
            string matched;
            if (field < n_fields)
                matched = fields[field];
            if (!matched.empty() && !(only_delimited && n_fields == 1))
                out.append(matched + line_delimiter);
        }
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
