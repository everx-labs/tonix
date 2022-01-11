pragma ton-solidity >= 0.53.0;

import "Utility.sol";

contract unexpand is Utility {

    function exec(string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (string[] args, string flags, ) = _get_args(e[IS_ARGS]);
        string[] params;

        for (string arg: args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN) {
                (string s_out, string s_err) = _unexpand(flags, _get_file_contents(index, inodes, data), params);
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

    function _unexpand(string flags, string texts, string[] params) private pure returns (string out, string err) {
        (string[] text, ) = _split(texts, "\n");
        bool convert_all_blanks = _flag_set("a", flags);
        bool use_tab_size = _flag_set("t", flags);
        uint16 tab_size = 8;

        if (!params.empty() && use_tab_size) {
            tab_size = _atoi(params[0]);
            if (tab_size < 1)
                return (out, "error");
        }

        string pattern = _spaces(tab_size);
        for (string line: text) {
            if (convert_all_blanks)
                out.append(_translate(line, pattern, "\t"));
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

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("unexpand", "convert spaces to tabs", "[OPTION]... [FILE]...",
            "Convert blanks in each FILE to tabs, writing to standard output.",
            "at", 1, M, [
            "convert all blanks, instead of just initial blanks",
            "have tabs N characters apart instead of 8 (enables -a)"]);
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
