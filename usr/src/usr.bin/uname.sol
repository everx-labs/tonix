pragma ton-solidity >= 0.61.0;

import "Utility.sol";

contract uname is Utility {

    function main(s_proc p_in) external pure returns (s_proc p) {
        p = p_in;
//    function main(string argv) external pure returns (uint8 ec, string out, string err) {
//        ( , , string flags, ) = arg.get_env(argv);
//        string host_name = vars.val("HOSTNAME", argv);
//        string arch = vars.val("HOSTTYPE", argv);
        string host_name = p.env_value("HOSTNAME");
        string arch = p.env_value("HOSTTYPE");
        string out;
        (bool all, bool kernel, bool node, bool hw_platform, bool machine, bool processor, bool os, ) = p.flag_values("asnimpo");
        if (all) out = "Tonix FileSys TVM TONOS TVM\n";
        if (kernel || p.flags_empty()) out = "Tonix ";
        if (node) out.append(host_name);
        if (hw_platform || machine) out.append("TVM ");
        if (os) out.append("TON OS ");
        if (processor) out.append(arch + " ");
        p.puts(out);
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
