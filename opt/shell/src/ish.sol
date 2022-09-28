pragma ton-solidity >= 0.62.0;

import "libshellenv.sol";
import "libnlist.sol";

contract ish {

    using libshellenv for shell_env;
    using libnv for nvlist_t;
    using xio for s_of;
    shell_env _e;
    nvlist_t[] _nv;

    function import_env(shell_env e_in) external {
        tvm.accept();
        _e = e_in;
    }

    function import_nvl(nvlist_t[] nvl) external {
        tvm.accept();
        _nv = nvl;
    }

    function export_env() external view returns (shell_env e) {
        e = _e;
    }

    function export_nvl() external view returns (nvlist_t[] nvl) {
        nvl = _nv;
    }

    function update_nvl(nvlist_t[] nvl, uint8 n) external {
        tvm.accept();
        _nv[n] = nvl[n];
    }

    function update_env(shell_env e_in, uint8 n) external {
        tvm.accept();
        _e.environ[n] = e_in.environ[n];
    }

    function dump(nvlist_t nv, uint16 f) external pure returns (string out) {
        return libnv.dump(nv, f);
    }

    function exists(nvlist_t nv_in, string name, uint8 ntype) external pure returns (bool out) {
        return libnv.nvlist_exists_type(nv_in, name, ntype);
    }

    function get(nvlist_t nv_in, string name, uint8 ntype) external pure returns (bool success, string out, uint16 nitems) {
        return libnv.get(nv_in, name, ntype);
    }
    function add(nvlist_t nv_in, uint8 ntype, string name, string value, uint16 nitems) external pure returns (nvlist_t nv) {
        nv = nv_in;
        nv.add(ntype, name, value, nitems);
    }
    function append(nvlist_t nv_in, uint8 ntype, string name, string value) external pure returns (nvlist_t nv) {
        nv = nv_in;
        nv.append(ntype, name, value);
    }
    function take(nvlist_t nv_in, uint8 ntype, string name) external pure returns (string out, uint16 nitems, nvlist_t nv) {
        nv = nv_in;
        (out, nitems) = nv.take(name, ntype);
    }

    function free(nvlist_t nv_in, uint8 ntype, string name) external pure returns (nvlist_t nv) {
        nv = nv_in;
        nv.free(name, ntype);
    }

    function transform(shell_env e_in, uint8 n, uint16 f) external pure returns (shell_env e, nvlist_t[] nvs) {
        nvs = _transform_all(e_in, n);
        e = e_in;
        s_of o = e.ofiles[libfdt.STDOUT_FILENO];
        for (nvlist_t nv: nvs)
            o.fputs(libnv.dump(nv, f) + '\n');
        e.ofiles[libfdt.STDOUT_FILENO] = o;
    }

    function _transform_all(shell_env e, uint8 n) internal pure returns (nvlist_t[] nvs) {
        string[] index = vars.array_val("arrayvar", e.environ[sh.ARRAYVAR]);
        uint ilen = index.length;
        for (uint8 i = 0; i < n; i++)
            nvs.push(_transform(e.environ[i], i < ilen ? index[i] : "<empty>", i));
    }

    function _transform(string[] page, string page_name, uint8 n) internal pure returns (nvlist_t nvl) {
        nvl = libnv.nvlist_create(page_name, 0);
        for (string s: page) {
            (string attr, string name, string value) = vars.split_var_record(s);
            if (n == sh.ALIAS || n == sh.BUILTIN || n == sh.COMMAND || n == sh.EXPORT || n == sh.SERVICE ||
            n == sh.SETOPT || n == sh.SHOPT)
                nvl.nvlist_add_string(name, value);
            else if (n == sh.ARRAYVAR || n == sh.SIGNAL) {
                (string[] fields, uint n_fields) = libstring.split(value, ' ');
                nvl.nvlist_add_string_array(name, fields, uint16(n_fields));
            } else if (n == sh.DISABLED || n == sh.ENABLED || n == sh.KEYWORD || n == sh.DIRSTACK) {
                nvl.nvlist_add_null(name);
            } else if (n == sh.FILE || n == sh.FUNCTION || n == sh.DIRECTORY) {
                nvl.nvlist_add_binary(name, value, str.strlen(value));
            } else if (n == sh.GROUP || n == sh.USER)
                nvl.nvlist_add_number(name, str.toi(value));
            else if (n == sh.VARIABLE) {
                if (!attr.empty()) {
                    if (str.strchr(attr, 'a') > 0) {
                        (string[] fields, uint n_fields) = libstring.split(value, ' ');
                        nvl.nvlist_add_string_array(name, fields, uint16(n_fields));
                    } else if (str.strchr(attr, 'i') > 0) {
                        nvl.nvlist_add_number(name, str.toi(value));
                    }
                 } else
                    nvl.nvlist_add_string(name, value);
            }
        }
    }

    function env(uint8 n, uint16 f) external view returns (string out) {
        shell_env e = _e;
        nvlist_t[] nvs = _transform_all(e, n);
        for (nvlist_t nv: nvs)
            e.dump_nvl(nv, f);
        return e.ofiles[libfdt.STDOUT_FILENO].buf.buf;
    }
    function upgrade(TvmCell c) external pure {
        tvm.accept();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }
}