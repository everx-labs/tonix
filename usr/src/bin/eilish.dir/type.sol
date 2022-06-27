pragma ton-solidity >= 0.61.2;

//import "Shell.sol";
//contract type_ is Shell {
import "pbuiltin.sol";
import "../../lib/vars.sol";
contract type_ is pbuiltin {

//    function main(svm sv_in) external pure returns (svm sv) {
    function _main(s_proc p, string[] params, shell_env e_in) internal pure override returns (shell_env e) {
        e = e_in;
        bool f_terse = p.flag_set("t");
        s_of f = e.fopen("pool", "r");
        string pool;
        if (!f.ferror()) {
            pool = f.fgets(0);
        } else
            e.perror("Failed to read objects pool");
//        (bool all_locations, bool func_lookup, bool disk_file_name, bool path_search, , , , ) = arg.flag_values("afpP", flags);

        for (string arg: params) {
            string t = vars.get_array_name(arg, pool);
            string value;
            if (t == "keyword")
                value = f_terse ? "keyword" : (arg + " is a shell keyword");
            else if (t == "alias")
                value = f_terse ? "alias" : (arg + " is aliased to `" + vars.val(arg, pool) + "\'");
            else if (t == "function") {
                value = f_terse ? "function" : (arg + " is a function\n" + vars.print_reusable(vars.get_pool_record(arg, pool)));
            } else if (t == "builtin")
                value = f_terse ? "builtin" : (arg + " is a shell builtin");
            else if (t == "command") {
                string path_map = vars.get_pool_record(arg, pool);
                string path;
                if (!path_map.empty())
                    (, path, ) = vars.split_var_record(path_map);
                if (!path.empty())
                    value = f_terse ? "file" : (arg + " is hashed (" + path + "/" + arg + ")");
                else
                    value = f_terse ? "file" : (arg + " is " + "/bin/" + arg);
            } else {
                e.perror(arg + ": not found");
            }
            e.puts(value);
        }
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"type",
"[-afptP] name [name ...]",
"Display information about command type.",
"For each NAME, indicate how it would be interpreted if used as a command name.",
"-a        display all locations containing an executable named NAME; includes aliases, builtins, and functions, if and only if\n\
          the `-p' option is not also used\n\
-f        suppress shell function lookup\n\
-P        force a PATH search for each NAME, even if it is an alias, builtin, or function, and returns the name of the disk file\n\
          that would be executed\n\
-p        returns either the name of the disk file that would be executed, or nothing if `type -t NAME' would not return `file'\n\
-t        output a single word which is one of `alias', `keyword', `function', `builtin', `file' or `', if NAME is an alias, shell\n\
          reserved word, shell function, shell builtin, disk file, or not found, respectively",
"Arguments:\n\
  NAME      Command name to be interpreted.",
"Returns success if all of the NAMEs are found; fails if any are not found.");
    }
}
