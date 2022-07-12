pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";

contract builtin is pbuiltin {

    function _main(shell_env e_in) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        string[] page = e.environ[sh.ERRNO];
        string cmd = vars.val("COMMAND", e.environ[sh.SPECVARS]);
        string[] pipeline = e.environ[sh.PIPELINE];
        string exec_line = pipeline[pipeline.length - 1];
        (string attrs, , string value) = vars.split_var_record(exec_line);
        uint8 return_code = uint8(vars.int_val("RETURN_CODE", page));
        uint8 error_no = uint8(vars.int_val("ERRNO", page));
        uint8 exit_status = uint8(vars.int_val("EXIT_STATUS", page));
        if (return_code + error_no + exit_status > 0) {
            s_of res = e.ofiles[libfdt.STDERR_FILENO];
            string err_msg = "-eilish: ";
            string reason = vars.val("REASON", page);
            string em;
            if (error_no > 0) {
                em = vars.val(str.toa(error_no), e.environ[sh.ERRORSTR]);
            }
            if (return_code > 0) {
                em = vars.val("BUILTIN_MOD", page) + ": ";
                em.append(reason);
            }
            err_msg.append(em);
            if (exit_status > 0)
                err_msg.append("ec: " + str.toa(exit_status));
            rc = return_code;
            res.fputs(err_msg);
            e.ofiles[libfdt.STDERR_FILENO] = res;
        }
        delete e.environ[sh.PIPELINE][pipeline.length - 1];
    }

    function _name() internal pure override returns (string) {
        return "builtin";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"builtin",
"[shell-builtin [arg ...]]",
"Execute shell builtins.",
"Execute SHELL-BUILTIN with arguments ARGs without performing command lookup.",
"",
"",
"Returns the exit status of SHELL-BUILTIN, or false if SHELL-BUILTIN is not a shell builtin.");
    }

}
