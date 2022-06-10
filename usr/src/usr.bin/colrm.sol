pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract colrm is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        string[] pparams;
        for (string param: p.params()) {
            s_of f = p.fopen(param, "r");
            if (!f.ferror()) {
                (string sout, string serr) = _print(f, pparams);
                if (serr.empty())
                    p.puts(sout);
                else
                    p.perror("cannot open");
            } else
                pparams.push(param);
        }
    }

    function _print(s_of f, string[] params) internal pure returns (string out, string err) {
        uint stop;
        uint n_params = params.length;
        uint start;
        bool second_cut = false;

        if (n_params > 0)
            start = str.toi(params[0]);
        if (start < 1)
            return (out, "error");
        if (n_params > 1) {
            stop = str.toi(params[1]);
            if (stop < start)
                return (out, "also an error");
            second_cut = true;
        }

        while(!f.feof()) {
            string s = f.fgetln();
            if (s.empty())
                continue;
            uint slen = s.byteLength();
            out.append(s.substr(0, math.min(slen, start - 1)));
            if (second_cut && stop < slen)
                out.append(s.substr(stop));
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"colrm",
"[start [stop]]",
"remove columns from a file",
"Removes selected columns from the lines of a file. A column is defined as a single character in a line. Output is written to the standard output.\n\
If only the start column is specified, columns numbered less than the start column will be written. If both start and stop columns are\n\
specified, columns numbered less than the start column or greater than the stop column will be written.  Column numbering starts with one, not zero.",
"",
"",
"Written by Boris",
"",
"column, cut, paste",
"0.01");
    }
}
