pragma ton-solidity >= 0.60.0;

import "Utility.sol";

contract printenv is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
        string[] params = p.params();
        string delimiter = p.flag_set("0") ? "\x00" : "\n";

        string[] e = p.environ;
        if (params.empty())
            for (string s: e)
                p.puts(s);
        for (string pa: params) {
            string key = pa + "=";
            uint16 kl = key.strlen();
            for (string s: e) {
                if (s.strlen() > kl && s.substr(0, kl) == key)
                    p.puts(s.substr(kl));
            }
        }
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"printenv",
"[OPTION]... [VARIABLE]...",
"print all or part of environment",
"Print the values of the specified environment VARIABLE(s).  If no VARIABLE is specified, print name and value pairs for them all.",
"-0      end each output line with NUL, not newline",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
