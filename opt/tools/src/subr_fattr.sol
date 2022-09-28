pragma ton-solidity >= 0.62.0;

import "libshellenv.sol";
import "libfattr.sol";
import "Base.sol";

contract subr_fattr is Base {

    using libshellenv for shell_env;
    using libfattr for s_thread;

    function main(shell_env e_in, s_proc p_in, uint[] attrs_in) external pure returns (shell_env e, s_proc p, uint[] attrs) {
        e = e_in;
        p = p_in;
        string[] sq = e.environ[sh.SIGNAL];
        attrs = attrs_in;
        for (string line: sq) {
            (, string name, string value) = vars.split_var_record(line);
            uint16 num = str.toi(name);
            (string[] args, ) = libstring.split(value, ' ');
            e.puts("Syscall " + name + " args: " + value);
            s_sigqueue siq;
	        uint16 code;
	        uint16 original_code;
	        s_sysent callp;
	        uint16[8] scargs;
            s_syscall_args sargs = s_syscall_args(code, original_code, callp, scargs);
            s_thread t = s_thread(p, p.p_pid + 1, siq, 0, 0, 0, p.p_ucred, p.p_ucred, p.p_limit, libproc.syscall_name(num), 0, 0, sargs, td_states.TDS_RUNNING, 0);            
//            s_sigqueue siq;
//            s_thread t = s_thread(p, p.p_pid + 1, siq, 0, 0, 0, p.p_ucred, p.p_ucred, p.p_limit, libproc.syscall_name(num), 0, 0, sargs, td_states.TDS_RUNNING, 0);
            //s_thread t;// = s_thread(p, p.p_pid + 1, 0, 0, p.p_ucred, p.p_ucred, p.p_limit, libfdt.syscall_name(num), 0, td_states.TDS_RUNNING, 0);
            uint[] res = t.do_syscall(num, args, attrs_in);
            uint8 ec = t.td_errno;
            uint32 rv = t.td_retval;
            e.puts("Syscall [attr] " + name + " ec: " + str.toa(ec) + " result: " + str.toa(rv));
            e.puts(_print_fattrs(res));
            if (ec == 0) {
                attrs = res;
            } else
                attrs = attrs_in;
        }
            e.puts(_print_fattrs(attrs));
    }

    function _print_fattrs(uint[] attrs) internal pure returns (string out) {
        return libstat.format_index(attrs);
    }

}