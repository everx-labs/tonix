pragma ton-solidity >= 0.53.0;

import "Utility.sol";

contract expand is Utility {

    function exec(string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (string[] args, string flags, ) = _get_args(e[IS_ARGS]);
        string[] params;

        for (string arg: args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN) {
                (string s_out, string s_err) = _expand(flags, _get_file_contents(index, inodes, data), params);
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

    function _expand(string flags, string texts, string[] params) private pure returns (string out, string err) {
        (string[] text, ) = _split(texts, "\n");
        bool convert_initial_tabs = _flag_set("i", flags);
        bool use_tab_size = _flag_set("t", flags);
        uint16 tab_size = 8;

        if (!params.empty() && use_tab_size) {
            tab_size = _atoi(params[0]);
            if (tab_size < 1)
                return (out, "error");
        }

        string tab_spaces = _spaces(tab_size);
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
                out.append(_translate(line, "\t", tab_spaces));
            out.append("\n");
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("expand", "convert tabs to spaces", "[OPTION]... [FILE]...",
            "Convert tabs in each FILE to spaces, writing to standard output.",
            "it", 1, M, [
            "do not convert tabs after non blanks",
            "have tabs N characters apart, not 8"]);
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
