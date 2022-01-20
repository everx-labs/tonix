pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract uname is Utility {

    function main(string argv) external pure returns (uint8 ec, string out, string err) {
        ( , , string flags, ) = _get_env(argv);
        string host_name = _val("HOSTNAME", argv);
        string arch = _val("HOSTTYPE", argv);

        ec = EXECUTE_SUCCESS;
        err = "";
        (bool all, bool kernel, bool node, bool hw_platform, bool machine, bool processor, bool os, ) = _flag_values("asnimpo", flags);
        if (all) out = "Tonix FileSys TVM TONOS TVM\n";
        if (kernel || flags.empty()) out = "Tonix ";
        if (node) out.append(host_name);
        if (hw_platform || machine) out.append("TVM ");
        if (os) out.append("TON OS ");
        if (processor) out.append(arch + " ");
    }
    /*function exec(Session session, InputS input) external pure returns (string out) {
        (, , uint flags) = input.unpack();
        if ((flags & _a) > 0) return "Tonix FileSys TON TONOS TON\n";
        if ((flags & _s) > 0 || flags == 0) out = "Tonix ";
        if ((flags & _n) > 0) out.append(session.host_name);
        if ((flags & _i + _m) > 0) out.append("TON ");
        if ((flags & _o) > 0) out.append("TON OS ");
        if ((flags & _p) > 0) out.append("TON ");
    }*/

    function _command_info() internal override pure returns (string command, string purpose, string synopsis, string description, string option_list,
                        uint8 min_args, uint16 max_args, string[] option_descriptions) {
        return ("uname", "print system information", "[OPTION]...",
            "Print certain system information. With no OPTION, same as -s.",
            "asnrvmpio", 0, 0, ["print all information, in the following order, except omit -p and -i if unknown:",
            "print the kernel name",
            "print the network node hostname",
            "print the kernel release",
            "print the kernel version",
            "print the machine hardware name",
            "print the processor type (non-portable)",
            "print the hardware platform (non-portable)",
            "print the operating system"]);
    }

    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"uname",
"[OPTION]...",
"print system information",
"Print certain system information. With no OPTION, same as -s.",
"-a      print all information, in the following order, except omit -p and -i if unknown:\n\
-s      print the kernel name\n\
-n      print the network node hostname\n\
-r      print the kernel release\n\
-v      print the kernel version\n\
-m      print the machine hardware name\n\
-p      print the processor type (non-portable)\n\
-i      print the hardware platform (non-portable)\n\
-o      print the operating system",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
