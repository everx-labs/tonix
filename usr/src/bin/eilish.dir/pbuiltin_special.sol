pragma ton-solidity >= 0.62.0;

// special: break : continue . eval exec exit export readonly return set shift times trap unset

import "pbuiltin_base.sol";
import "vars.sol";

abstract contract pbuiltin_special is pbuiltin_base {
    using vars for string[];
    using vars for string;
    using libshellenv for shell_env;
    function main(shell_env e_in) external pure returns (shell_env e) {
        e = e_in;
        string[] params = e.params();
        bool no_flags = e.flags_empty();
        bool no_params = params.empty();
        uint8 n = _retrieve_pages(e);
        uint8 rc;

        string sattrs = _attr_set(e);
        sattrs = "-" + (sattrs.empty() ? "-" : sattrs);

        if (e.flag_set("p") || (no_flags && no_params)) {
            s_of res = e.ofiles[libfdt.STDOUT_FILENO];
                string[] page = e.environ[n];
                if (no_params) {
                    for (string line: page) {
                        (string attrs, ) = line.csplit(" ");
                        if (vars.match_attr_set(sattrs, attrs))
                            res.fputs(_print_record(line));
                    }
                }
                for (string param: params) {
                    string cur_record = vars.get_pool_record(param, page);
                    if (!cur_record.empty()) {
                        (string cur_attrs, ) = cur_record.csplit(" ");
                        if (vars.match_attr_set(sattrs, cur_attrs))
                            res.fputs(_print_record(cur_record));
                    } else {
                        e.perror(param + ": not found");
                        rc = EXIT_FAILURE;
                    }
                }
            e.ofiles[libfdt.STDOUT_FILENO] = res;
        } else {
            for (string param: e.params()) {
                e.environ[sh.ARRAYVAR][n].arrayvar_add(param);
                e.environ[n].set_var("", param);
            }
            /*e = _modify(e, e.environ[sh.ARRAYVAR][n]);
            for (uint8 n: pages) {
                e.environ[sh.ARRAYVAR][n] = _modify(e, e.environ[sh.ARRAYVAR][n]);
            }*/
            /*for (uint8 n: pages) {
                string[] page = e.environ[n];
                for (string param: e.params()) {
                    string cur_record = vars.get_pool_record(param, page);
                    if (!cur_record.empty()) {
                        (string cur_attrs, ) = cur_record.csplit(" ");
                        if (vars.match_attr_set(sattrs, cur_attrs))
                            e.environ[n] = vars.set_var(sattrs, param, e.environ[n]);
                    } else {
                        e.perror(param + ": not found");
                        rc = EXIT_FAILURE;
                    }
                }
            }*/
        }
        e.environ[sh.ERRNO].set_int_val("RETURN_CODE", rc);
        if (rc > 0) {
            e.environ[sh.ERRNO].set_val("BUILTIN_MOD", _name());
        }
    }

    function _name() internal pure virtual returns (string);
    function _attr_set(shell_env e) internal pure virtual returns (string);
    function _print_record(string record) internal pure virtual returns (string);
    function _retrieve_pages(shell_env e) internal pure virtual returns (uint8);
//    function _modify(shell_env e) internal pure virtual returns (string);
}
