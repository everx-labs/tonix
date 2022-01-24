pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract colrm is Utility {

    function main(string argv, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (uint8 ec, string out, string err) {
        (uint16 wd, string[] v_args, , ) = arg.get_env(argv);
        string[] params;

        for (string s_arg: v_args) {
            (uint16 index, uint8 ft, , ) = _resolve_relative_path(s_arg, wd, inodes, data);
            if (ft != FT_UNKNOWN) {
                (string s_out, string s_err) = _colrm(_get_file_contents(index, inodes, data), params);
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

    function _colrm(string texts, string[] params) private pure returns (string out, string err) {
        (string[] text, ) = stdio.split(texts, "\n");
        uint stop;
        uint n_params = params.length;
        uint start;
        bool second_cut = false;

        if (n_params > 0)
            start = stdio.atoi(params[0]);
        if (start < 1)
            return (out, "error");
        if (n_params > 1) {
            stop = stdio.atoi(params[1]);
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

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"colrm",
"[start [stop]]",
"remove columns from a file",
"Removes selected columns from the lines of a file. A column is defined as a single character in a line. Output is written to the standard output.",
"",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
