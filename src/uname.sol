pragma ton-solidity >= 0.55.0;

import "Utility.sol";

contract uname is Utility {

    function main(string argv) external pure returns (uint8 ec, string out, string err) {
        ( , , string flags, ) = arg.get_env(argv);
        string host_name = vars.val("HOSTNAME", argv);
        string arch = vars.val("HOSTTYPE", argv);

        ec = EXECUTE_SUCCESS;
        err = "";
        (bool all, bool kernel, bool node, bool hw_platform, bool machine, bool processor, bool os, ) = arg.flag_values("asnimpo", flags);
        if (all) out = "Tonix FileSys TVM TONOS TVM\n";
        if (kernel || flags.empty()) out = "Tonix ";
        if (node) out.append(host_name);
        if (hw_platform || machine) out.append("TVM ");
        if (os) out.append("TON OS ");
        if (processor) out.append(arch + " ");
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
