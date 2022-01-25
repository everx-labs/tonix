pragma ton-solidity >= 0.56.0;

import "Utility.sol";

contract unexpand is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] v_args, string flags, ) = arg.get_env(argv);
        string[] params;

        for (string s_arg: v_args) {
            (uint16 index, uint8 ft, , ) = fs.resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN) {
                (string s_out, string s_err) = _unexpand(flags, fs.get_file_contents(index, inodes, data), params);
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

    function _unexpand(string flags, string texts, string[] params) private pure returns (string out, string err) {
        (string[] text, ) = stdio.split(texts, "\n");
        bool convert_all_blanks = arg.flag_set("a", flags);
        bool use_tab_size = arg.flag_set("t", flags);
        uint16 tab_size = 8;

        if (!params.empty() && use_tab_size) {
            tab_size = stdio.atoi(params[0]);
            if (tab_size < 1)
                return (out, "error");
        }

        string pattern = fmt.spaces(tab_size);
        for (string line: text) {
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
"",
"0.01");
    }

}
