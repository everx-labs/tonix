pragma ton-solidity >= 0.67.0;

import "putil.sol";

contract printenv is putil {
    using str for string;
    function _main(shell_env e_in) internal override pure returns (shell_env e) {
        e = e_in;
        string[] params = e.params();
        string delimiter = e.flag_set("0") ? "\x00" : "\n";

        string[] ee = e.environ[sh.VARIABLE];
        if (params.empty())
            for (string s: ee)
                e.puts(s);
        for (string pa: params) {
            string key = pa + "=";
            uint16 kl = key.strlen();
            for (string s: ee) {
                if (s.strlen() > kl && s.substr(0, kl) == key)
                    e.puts(s.substr(kl));
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
