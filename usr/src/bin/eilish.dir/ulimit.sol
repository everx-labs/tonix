pragma ton-solidity >= 0.60.0;

import "Shell.sol";

contract ulimit is Shell {

    function _table(TvmCell[] cls) internal pure returns (string out) {
        Column[] columns_format = [
            Column(true, 3, fmt.LEFT),
            Column(true, 5, fmt.LEFT),
            Column(true, 6, fmt.LEFT),
            Column(true, 5, fmt.LEFT)];

        string[][] table = [["N", "cells", "bytes", "refs"]];
        for (uint i = 0; i < cls.length; i++) {
            (uint cells, uint bits, uint refs) = cls[i].dataSize(1000);
            uint bytess = bits / 8;
            table.push([str.toa(i), str.toa(cells), str.toa(bytess), str.toa(refs)]);
        }
        out = fmt.format_table_ext(columns_format, table, " ", "\n");
    }

    function v1(string args, string pool) external pure returns (uint8 ec, string out) {

    }

    function print(string args, string pool) external pure returns (uint8 ec, string out) {
        /*(string[] params, string flags, ) = arg.get_args(args);
        (bool socket_buffer_size, bool core_file_size, bool data_seg_size, bool scheduling_priority, bool file_size, bool pending_signals,
            bool max_locked_memory, bool max_memory_size) = arg.flag_values("bcdefilm", flags);
        (bool open_files, bool pipe_size, bool POSIX_message_queues, bool real_time_priority, bool stack_size, bool cpu_time,
            bool max_user_processes, bool virtual_memory) = arg.flag_values("npqrstuv", flags);
        (bool file_locks, bool max_pseudoterminals, bool max_user_threads, bool soft_resource_limit, bool hard_resource_limit, bool print_all, , ) =
            arg.flag_values("xPTSHa", flags);
        bool use_hard_limit = hard_resource_limit && !soft_resource_limit;*/
        if (!args.empty())
            ec = EXECUTE_SUCCESS;

/*/proc/27196/limits
Limit                     Soft Limit           Hard Limit           Units
Max cpu time              unlimited            unlimited            seconds
Max file size             unlimited            unlimited            bytes
Max data size             unlimited            unlimited            bytes
Max stack size            8388608              unlimited            bytes
Max core file size        0                    unlimited            bytes
Max resident set          unlimited            unlimited            bytes
Max processes             23578                23578                processes
Max open files            1024                 1048576              files
Max locked memory         65536                65536                bytes
Max address space         unlimited            unlimited            bytes
Max file locks            unlimited            unlimited            locks
Max pending signals       23578                23578                signals
Max msgqueue size         819200               819200               bytes
Max nice priority         0                    0
Max realtime priority     0                    0
Max realtime timeout      unlimited            unlimited            us*/
//        if (print_all) {
            (string[] items, ) = pool.split_line("\n", "\n");
            for (string item: items) {
                out.append(item);
//                (string attrs, string name, string value) = _parse_var(item);
//                out.append(name + " " + value + "\n");
            }
//        }
    }



    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"ulimit",
"[-SHabcdefiklmnpqrstuvxPT] [limit]",
"Modify shell resource limits.",
"Provides control over the resources available to the shell and processes it creates, on systems that allow such control.",
"-S        use the `soft' resource limit\n\
-H        use the `hard' resource limit\n\
-a        all current limits are reported\n\
-b        the socket buffer size\n\
-c        the maximum size of core files created\n\
-d        the maximum size of a process's data segment\n\
-e        the maximum scheduling priority (`nice')\n\
-f        the maximum size of files written by the shell and its children\n\
-i        the maximum number of pending signals\n\
-l        the maximum size a process may lock into memory\n\
-m        the maximum resident set size\n\
-n        the maximum number of open file descriptors\n\
-p        the pipe buffer size\n\
-q        the maximum number of bytes in POSIX message queues\n\
-r        the maximum real-time scheduling priority\n\
-s        the maximum stack size\n\
-t        the maximum amount of cpu time in seconds\n\
-u        the maximum number of user processes\n\
-v        the size of virtual memory\n\
-x        the maximum number of file locks\n\
-P        the maximum number of pseudoterminals\n\
-T        the maximum number of threads\n\n\
Not all options are available on all platforms.",
"If LIMIT is given, it is the new value of the specified resource; the\n\
special LIMIT values `soft', `hard', and `unlimited' stand for the\n\
current soft limit, the current hard limit, and no limit, respectively.\n\
Otherwise, the current value of the specified resource is printed.  If\n\
no option is given, then -f is assumed.\n\n\
Values are in 1024-byte increments, except for -t, which is in seconds,\n\
-p, which is in increments of 512 bytes, and -u, which is an unscaled\n\
number of processes.",
"Returns success unless an invalid option is supplied or an error occurs.");
    }
}
