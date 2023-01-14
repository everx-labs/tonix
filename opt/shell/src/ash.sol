pragma ton-solidity >= 0.63.0;

import "libshellenv.sol";
import "libnlist.sol";

import "udev.sol";
contract ash is udev {

    using libshellenv for shell_env;
    using libnv for nvlist_t;
    shell_env _e;
    nvlist_t[] _nv;

    constructor(device_t pdev, device_t dev) udev (pdev, dev) public {
        tvm.accept();
    }

    function import_env(shell_env e_in) external {
        tvm.accept();
        _e = e_in;
    }

    function export_env() external view returns (shell_env e) {
        e = _e;
    }

    function update_env(shell_env e_in, uint8 n) external {
        tvm.accept();
        _e.environ[n] = e_in.environ[n];
    }

    function transform(shell_env e_in, uint8 n) external pure returns (shell_env e, nvlist_t[] nvs) {
        nvs = _transform_all(e_in, n);
        e = e_in;
        for (nvlist_t nv: nvs) {
//            e.dump_nvl(nv);
        }
    }

    function _transform_all(shell_env e, uint8 n) internal pure returns (nvlist_t[] nvs) {
        for (uint i = 0; i < n; i++)
            nvs.push(_transform(e, uint8(i)));
    }

    function _transform(shell_env e, uint8 n) internal pure returns (nvlist_t nvl) {
        for (string s: e.environ[n]) {
            (, string name, string value) = vars.split_var_record(s);
            if (n == sh.ALIAS)
                nvl.nvlist_add_string(name, value);
            else if (n == sh.ARRAYVAR) {
                (string[] fields, uint n_fields) = libstring.split(value, ' ');
                nvl.nvlist_add_string_array(name, fields, uint16(n_fields));
            } else if (n == sh.BUILTIN) {
                nvl.nvlist_add_string(name, value);
            }
        }
    }

    /*function upgrade(TvmCell c) external pure {
        tvm.accept();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
    }*/
}