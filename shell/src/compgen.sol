pragma ton-solidity >= 0.55.0;

import "Shell.sol";
import "compspec.sol";

contract compgen is Shell, compspec {

    function read_fs_to_env(Job job_in, mapping (uint => ItemHashMap) env_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (Job job, mapping (uint => ItemHashMap) env) {
        job = job_in;
        env = env_in;
        (, , , , , , , , , , string s_arg, string[] args, string short_options, , , , , , ) = job_in.unpack();
//            (uint16 ec, string out, mapping (uint => ItemHashMap) env_x, string s_action) = _cd(args, short_options, env_in, inodes, data);
        uint n_options = short_options.byteLength();
        string out;
//        string last_arg = _get_last_arg(s_arg);
        uint n_args = args.length;
        string last_arg = n_args > 0 ? args[n_args - 1] : "";

        for (uint i = 0; i < n_options; i++) {
            string o = short_options.substr(i, 1);
            string[] comp = _gen_comp(o, last_arg, env_in);
            for (string s: comp)
                out.append(s + "\n");
            /*string o_map_name = _option_map_name(o);
            if (!o_map_name.empty()) {
                uint o_map_key = tvm.hash(o_map_name);
                if (env.exists(o_map_key)) {
                    for ((, Item item): env[o_map_key].value)
                        out.append(item.name + "\n");
                }
            }*/
        }
//        string p_command = _get_option_param(s_arg, "C");
//        mapping (uint => Item) comp_spec = env[tvm.hash("compspec")].value;
//        (uint16 ec, string[] completions) = _compgen(p_command, short_options, comp_spec);
        job.stdout.append(out);
        job.s_action = "print_out";
    }

    function _compgen(string p_command, string short_options, mapping (uint => Item) comp_spec) internal pure returns (uint16 ec, string[] completions) {
        /*string p_option = _get_option_param(s_arg, "o");
        string p_action = _get_option_param(s_arg, "A"); // The action may be one of the following to generate a list of possible completions: (see links)
        string p_globpat = _get_option_param(s_arg, "G"); // The filename expansion pattern globpat is expanded to generate the possible completions.
        string p_wordlist = _get_option_param(s_arg, "W");
        string p_function = _get_option_param(s_arg, "F");

        string p_filterpat = _get_option_param(s_arg, "X");
        string p_prefix = _get_option_param(s_arg, "P");
        string p_suffix = _get_option_param(s_arg, "S");

        string o_map_name = _option_map_name(p_option);
        string a_map_name = _action_map_name(p_action);*/

//        env = env_in;
        bool process_all = p_command.empty();
//        mapping (uint => Item) comp_spec = env[tvm.hash("compspec")].value;
        bool comp_exists;
        if (!process_all) {
            comp_exists = comp_spec.exists(tvm.hash(p_command));
            if (!comp_exists) {
                uint q = stdio.strrchr(p_command, "/");
                if (q > 0) {
                    string command_name_short = p_command.substr(q);
                    comp_exists = comp_spec.exists(tvm.hash(command_name_short));
                }
            }
        }
        if (comp_exists)
            (completions, ) = stdio.split(comp_spec[tvm.hash(p_command)].value, " ");
        else
            ec = 1;
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
