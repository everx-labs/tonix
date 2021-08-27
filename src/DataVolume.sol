pragma ton-solidity >= 0.49.0;
pragma experimental ABIEncoderV2;

import "Device.sol";

contract DataVolume is Device {

    function _make_fs() internal {
        _create_fs("DataVolumeFS", 1, ["etc", "errors"]);
        _add_primary_device("sda", 1024, 100);
    }

    function _init() internal override accept {
        _make_fs();
        INodeS[] etc_files = _files(
            ["commands", "exports", "mtab", "group", "hostname", "hosts", "magic", "motd", "passwd", "shadow"], [
            "account\tbasename\tcat\tcd\tchgrp\tchmod\tchown\tcksum\tcmp\tcolumn\tcp\tcut\tdd\tdf\tdirname\tdu\techo\tfile\tfindmnt\tgrep\thelp\tid\tln\tls\tlsblk\tman\tmkdir\tmount\tmv\tpaste\tping\tpwd\trm\trmdir\tstat\ttouch\tuname\twc\twhoami",
            "InputParser/usr/share/errors\t/usr/share/commands\nStat\t/\nCommandProcessor\t/\n",
            "DataVolume\t/usr/share/errors\t1\tdefaults\nCommandManual\t/usr/share/commands\t1\tdefaults\nStatusManual\t/usr/share/commands\t1\tdefaults\n",
            "root\t0\nboris\t1000\nguest\t10000\n",
            format("{}\n", address(this)),
            "0:47169541fd28e7688079c4319a8de3b358ce13d87e25bbd3eaded12ae9b09f40\tCommandProcessor\n0:44981ddf8d0d7d593598e44b754482c5792f0d49d8416ebfeb24834bf26a77d9\tStat\n0:439f4e7f5eedbe2348632124e0e6b08a30b10fc2d45951365f4a9388fc79c3fb\tDataVolume\n0:68c00d417291837826ed9e7aa451d40629dde6d7cf8bcc4fec63cc0978d08205\tSuperBlock\n0:41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5\tBlockDevice\n0:4be68a2f14b949f1388f8e5dce3bbee14d35518abd8efcc93919bbb921218f8d\tInputParser\n0:46b494f9e5c5ecfd9a48ddffbe6a85af564445ab58ed1241fd0fb6a666ec369e\tOptions\n0:4b937783725628153f2fa320f25a7dd1d68acf948e38ea5a0c5f7f3857db8981\tCommandManual\n0:41d95cddc9ca3c082932130c208deec90382f5b7c0036c8d84ac3567e8b82420\tStatusManual\n",
            "11\n",
            "Welcome to Tonix.\nType \"help\" to get a list of commands.\n\"man <COMMAND>\" or \"help <COMMAND>\" sometimes might be helpful.\nSome options for certain commands work as well.\nFeel free to navigate a pre-made file system using intuitive commands.\nPath resolution does not work yet, one step at a time please.\nYour feedback is highly appreciated!\nHave fun :)\n",
            "root\t0\t0\troot\t/root\nboris\t1000\t1000\tboris\t/home/boris\nguest\t10000\t10000\tguest\t/home/guest\n",
            ""]);
        uint16 from = _ic;
        _add_reg_files(ROOT_DIR + 1, etc_files);
        uint16 to = _ic;
        _sb_exports.push(_get_export_sb(from, to - from));
        INodeS[] error_files = _files(
            ["reasons", "status", "internal"], [
            "missing operand\tcannot remove\tcannot stat\tcannot access\tcannot create directory\tcannot open\tinvalid option\textra operand\tfailed to remove\tmissing operand after\tmissing file operand\tmissing destination file operand after\tinvalid group\tmissing filename\tinvalid mode\tinvalid owner\tcannot touch\tcannot create regular file\ttoo many arguments\ttoo many operands\tTry '--help' for more information\tfailed to access\t-r not specified; omitting directory\tcannot overwrite directory with non-directory\toptions -l and -s are incompatible",
            "No such file or directory\tFile exists\tNot a directory\tIs a directory\tPermission denied",
            "direntry not found\tinode not found\tparent direntry not found\tchild direntry not found\tinvalid user id\tinvalid working directory"]);
        from = _ic;
        _add_reg_files(ROOT_DIR + 2, error_files);
        to = _ic;
        _sb_exports.push(_get_export_sb(from, to - from));
    }

}
