pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract unexpand is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err, Err[] errors) {
        (, , string flags, string pi) = arg.get_env(argv);
        bool use_tab_size = arg.flag_set("t", flags);
        uint16 tab_size = use_tab_size ? str.toi(arg.opt_arg_value("t", argv)) : 8;

        DirEntry[] contents = dirent.parse_param_index(pi);
        for (DirEntry de: contents) {
            (uint8 ft, string name, uint16 index) = de.unpack();
            if (ft != FT_UNKNOWN) {
                string text = fs.get_file_contents(index, inodes, data);
                (string[] lines, ) = stdio.split(text, "\n");
                out.append(_print(lines, flags, tab_size));
            } else
                errors.push(Err(0, er.ENOENT, name));
        }
        ec = errors.empty() ? EXECUTE_SUCCESS : EXECUTE_FAILURE;
        err = "";
    }

    function _print(string[] lines, string flags, uint16 tab_size) private pure returns (string out) {
        bool convert_all_blanks = arg.flag_set("a", flags);
        string pattern = fmt.spaces(tab_size);
        for (string line: lines) {
            if (convert_all_blanks)
                out.append(stdio.translate(line, pattern, "\t"));
            else {
                uint p = 0;
                while (line.substr(p, 1) == " ")
                    p++;
                if (p > 0) {
                    (uint n_tabs, uint n_spaces) = math.divmod(p, tab_size);
                    for (uint i = 0; i < n_tabs; i++)
                        out.append("\t");
                    for (uint i = 0; i < n_spaces; i++)
                        out.append(" ");
                    out.append(line.substr(p));
                } else
                    out.append(line);
            }
            out.append("\n");
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"unexpand",
"[OPTION]... [FILE]...",
"convert spaces to tabs",
"Convert blanks in each FILE to tabs, writing to standard output.",
"-a      convert all blanks, instead of just initial blanks\n\
-t      have tabs N characters apart instead of 8 (enables -a)",
"",
"Written by Boris",
"",
"expand",
"0.01");
    }

}
