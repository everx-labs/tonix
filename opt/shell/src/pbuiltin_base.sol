pragma ton-solidity >= 0.63.0;

struct BuiltinHelp {
    string name;
    string synopsis;
    string purpose;
    string description;
    string options;
    string arguments;
    string exit_status;
}
import "parg.sol";
import "libshellenv.sol";
import "libjobcommand.sol";
import "udev.sol";

abstract contract pbuiltin_base is udev {
//contract pbuiltin_base is udev {
    using libstring for string;
    using str for string;
    using xio for s_of;
    using io for s_proc;
    using parg for s_proc;
    using libshellenv for shell_env;
    using libjobcommand for job_cmd;

    function builtin_help() external pure returns (BuiltinHelp bh) {
        return _builtin_help();
    }

    function _builtin_help() internal pure virtual returns (BuiltinHelp bh);

    uint8 constant EXIT_SUCCESS = 0;
    uint8 constant EXIT_FAILURE = 1;
    uint8 constant EX_BADUSAGE  = 2; // Usage messages by builtins result in a return status of 2

    /*function upgrade(TvmCell c) external {
        tvm.accept();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
        onCodeUpgrade();
    }

    function onCodeUpgrade() internal {
        tvm.resetStorage();
    }

    modifier accept {
        tvm.accept();
        _;
    }*/
}
