pragma ton-solidity >= 0.62.0;

import "libshellenv.sol";
import "libtable.sol";
import "libsyscall.sol";
import "Base.sol";
import "libnlist.sol";

contract subr_nl is Base {

    using libshellenv for shell_env;
    using libsyscall for s_thread;
    using libnv for nvlist_t;

    function main(shell_env e_in, s_proc p_in) external pure returns (shell_env e, s_proc p, nvlist_t nvl) {
        e = e_in;
        p = p_in;
        string[] sq = e.environ[sh.SIGNAL];
        s_sysent[] ucs;
        /*uint16[] ids = libsyscall.syscall_ids();
        for (uint16 id: ids)
            ucs.push(s_sysent(libsyscall.syscall_nargs(id), 0, libsyscall.syscall_module(id), id, libsyscall.syscall_name(id)));*/
        for (string line: sq) {
            (, string name, string value) = vars.split_var_record(line);
            uint16 num = str.toi(name);
            (string[] args, ) = libstring.split(value, ' ');
//            string sarg1 = n_args > 0 ? args[0] : "";
//            uint16 arg1 = n_args > 0 ? str.toi(sarg1) : 0;
            e.puts("Syscall " + name + " args: " + value);
            uint8 ec;
            uint32 rv;
            s_sigqueue siq;
	        uint16 code;
	        uint16 original_code;
	        s_sysent callp;
	        uint16[8] scargs;
            s_syscall_args sargs = s_syscall_args(code, original_code, callp, scargs);
            s_thread t = s_thread(p, p.p_pid + 1, siq, 0, 0, 0, p.p_ucred, p.p_ucred, p.p_limit, libproc.syscall_name(num), 0, 0, sargs, td_states.TDS_RUNNING, 0);            
            if (num == libsyscall.SYS_syscall) {
                t.do_syscall(num, args);
                rv = t.td_retval;
                ec = t.td_errno;
                if (ec == 0)
                    p = t.td_proc;
                else
                    e.set_err(ec, "Syscall" + name);
            } else
                 ec = err.ENOSYS;
            e.puts("Syscall " + name + " ec: " + str.toa(ec) + " result: " + str.toa(rv));
        }
        string[][] ev = e.environ;
//        nvlist_t nvl;
        string[] sarr;
        for (string s: ev[sh.ALIAS]) {
            (, string name, string value) = vars.split_var_record(s);
            (string[] fields, uint n_fields) = libstring.split(value, ' ');
            nvl.nvlist_add_string(name, value);
//            nvl.nvlist_add_descriptor(name, sh.ALIAS);
        }
        for (string s: ev[sh.ARRAYVAR]) {
            (, string name, string value) = vars.split_var_record(s);
            (string[] fields, uint n_fields) = libstring.split(value, ' ');
            nvl.nvlist_add_string_array(name, fields, uint16(n_fields));
//            nvl.nvlist_add_descriptor(name, sh.ARRAYVAR);
        }
        for (string s: ev[sh.BUILTIN]) {
            (string attr, string name, string value) = vars.split_var_record(s);
//            nvl.nvlist_add_bool(name, str.strchr(attr, 'n') == 0);
            nvl.nvlist_add_string(name, value);
//            nvl.nvlist_add_descriptor(name, sh.BUILTIN);
        }

        e.ofiles[libfdt.STDOUT_FILENO] = nvl.nvlist_fdump(e.ofiles[libfdt.STDOUT_FILENO]);
    }
}