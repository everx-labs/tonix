pragma ton-solidity >= 0.60.0;

import "Shell.sol";

contract compgen is Shell {

    // Flag values that control parameter pattern substitution
    uint8 constant MATCH_ANY        = 0;
    uint8 constant MATCH_BEG        = 1;
    uint8 constant MATCH_END        = 2;
    uint8 constant MATCH_TYPEMASK   = 3;
    uint8 constant MATCH_GLOBREP    = 16;
    uint8 constant MATCH_QUOTED     = 32;

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        (bool fa, bool fb, bool fc, bool fd, bool fe, bool ff, bool fg, bool fj) = arg.flag_values("abcdefgj", flags);
        (bool fk, bool fs, bool fu, bool fv, , , , ) = arg.flag_values("ksuv", flags);
        bool print_names = fa || fb || fe || fv;
        bool print_values = fc || fd || ff || fg || fj || fk || fs || fu;
        ec = EXECUTE_SUCCESS;

        string param = params.empty() ? "" : params[0];
        uint p_len = param.byteLength();
        (string[] lines, ) = pool.split("\n");
        for (string line: lines) {
            (, string name, string value) = vars.split_var_record(line);
            if (name.byteLength() >= p_len && name.substr(0, p_len) == param) {
                out.append((print_names ? name : print_values ? value : "") + "\n");
            }
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"compgen",
"[-abcdefgjksuv] [-o option] [-A action] [-G globpat] [-W wordlist]  [-F function] [-C command] [-X filterpat] [-P prefix] [-S suffix] [word]",
"Display possible completions depending on the options.",
"Intended to be used from within a shell function generating possible completions. If the optional WORD argument is supplied, matches against WORD are generated.",
"",
"",
"Returns success unless an invalid option is supplied or an error occurs.");
    }
}
