pragma ton-solidity >= 0.62.0;

import "putil.sol";

contract uname is putil {

    function _main(shell_env e_in) internal override pure returns (shell_env e) {
        e = e_in;
        string host_name = e.env_value("HOSTNAME");
        string arch = e.env_value("HOSTTYPE");
        string out;
        (bool all, bool kernel, bool node, bool hw_platform, bool machine, bool processor, bool os, ) = e.flag_values("asnimpo");
        if (all) out = "Tonix FileSys TVM TONOS TVM\n";
        if (kernel || e.flags_empty()) out = "Tonix ";
        if (node) out.append(host_name);
        if (hw_platform || machine) out.append("TVM ");
        if (os) out.append("TON OS ");
        if (processor) out.append(arch + " ");
        e.puts(out);
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
"0.02");
    }

}
