pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract expand is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] v_args, string flags, ) = arg.get_env(argv);
        string[] params;

        for (string s_arg: v_args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN) {
                (string s_out, string s_err) = _expand(flags, _get_file_contents(index, inodes, data), params);
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

    function _expand(string flags, string texts, string[] params) private pure returns (string out, string err) {
        (string[] text, ) = stdio.split(texts, "\n");
        bool convert_initial_tabs = arg.flag_set("i", flags);
        bool use_tab_size = arg.flag_set("t", flags);
        uint16 tab_size = 8;

        if (!params.empty() && use_tab_size) {
            tab_size = stdio.atoi(params[0]);
            if (tab_size < 1)
                return (out, "error");
        }

        string tab_spaces = fmt.spaces(tab_size);
        for (string line: text) {
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
"",
"0.01");
    }

}
