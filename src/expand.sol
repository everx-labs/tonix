pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract expand is Utility {

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
        bool convert_initial_tabs = arg.flag_set("i", flags);
        string tab_spaces = fmt.spaces(tab_size);
        for (string line: lines) {
            if (convert_initial_tabs) {
                uint p = 0;
                while (line.substr(p, 1) == "\t")
                    p++;
                if (p > 0) {
                    for (uint i = 0; i < p; i++)
                        out.append(tab_spaces);
                    out.append(line.substr(p));
                } else
                    out.append(line);
            } else
                out.append(stdio.translate(line, "\t", tab_spaces));
            out.append("\n");
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"expand",
"[OPTION]... [FILE]...",
"convert tabs to spaces",
"Convert tabs in each FILE to spaces, writing to standard output.",
"-i     do not convert tabs after non blanks\n\
-t      have tabs N characters apart, not 8",
"",
"Written by Boris",
"",
"unexpand",
"0.01");
    }

}
