pragma ton-solidity >= 0.53.0;

import "Utility.sol";

contract colrm is Utility {

    function exec(string[] e, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (string[] args, , ) = _get_args(e[IS_ARGS]);
        string[] params;

        for (string arg: args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(arg, ROOT_DIR, inodes, data);
            if (ft != FT_UNKNOWN) {
                (string s_out, string s_err) = _colrm(_get_file_contents(index, inodes, data), params);
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

    function _colrm(string texts, string[] params) private pure returns (string out, string err) {
        (string[] text, ) = _split(texts, "\n");
        uint stop;
        uint n_params = params.length;
        uint start;
        bool second_cut = false;

        if (n_params > 0)
            start = _atoi(params[0]);
        if (start < 1)
            return (out, "error");
        if (n_params > 1) {
            stop = _atoi(params[1]);
            if (stop < start)
                return (out, "also an error");
            second_cut = true;
        }
        for (string s: text) {
            if (s.empty())
                continue;
            uint s_len = s.byteLength();
            out.append(s.substr(0, math.min(s_len, start - 1)));
            if (second_cut && stop < s_len)
                out.append(s.substr(stop));
            out.append("\n");
        }
    }

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list, uint8 min_args, uint16 max_args, string[] option_descriptions) {
        string[] empty;
        return ("colrm", "remove columns from a file", "[start [stop]]",
            "Removes selected columns from the lines of a file. A column is defined as a single character in a line. Output is written to the standard output.",
            "", 1, 3, empty);
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
