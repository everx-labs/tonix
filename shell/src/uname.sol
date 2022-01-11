pragma ton-solidity >= 0.51.0;

import "Utility.sol";

contract uname is Utility {

    function exec(Session session, InputS input) external pure returns (string out) {
        (, , uint flags) = input.unpack();
        if ((flags & _a) > 0) return "Tonix FileSys TON TONOS TON\n";
        if ((flags & _s) > 0 || flags == 0) out = "Tonix ";
        if ((flags & _n) > 0) out.append(session.host_name);
        if ((flags & _i + _m) > 0) out.append("TON ");
        if ((flags & _o) > 0) out.append("TON OS ");
        if ((flags & _p) > 0) out.append("TON ");
    }

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
"",
"OPTION... [FILE]...",
"",
"",
"-a     d",
"",
"Written by Boris",
"",
"",
"0.01");
    }

}
