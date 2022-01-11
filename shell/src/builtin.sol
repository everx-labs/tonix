pragma ton-solidity >= 0.53.0;

import "Shell.sol";

contract builtin is Shell {

    function _get_fd(string[] e) internal pure returns (uint16 fd) {
        for (uint i = IS_USER_FD; i < e.length; i++)
            if (e[i].empty())
                return uint16(i);
    }

    function open(string pathname, uint16 flags, string[] e) external pure returns (uint8 ec, uint16 fd, string[] env) {
        env = e;
        string fd_table = e[IS_FD_TABLE];
        string cur_val = _val(pathname, fd_table);
        if (cur_val.empty()) {
            fd = _get_fd(e);
            string record = format("-{} [{}]={}\n", flags, fd, pathname);
            fd_table.append(record);
        } else {
            fd = _atoi(cur_val);
        }
//        fd_table = _set_item_value(pathname, fd_table, format("{}", fd));

        env[IS_FD_TABLE] = fd_table;
    }

    function read(uint16 fd, uint32 count, string[] e) external pure returns (uint8 ec, string out, uint32 b_count, string[] env) {
        env = e;
        uint len = e.length;
        if (fd >= len)
            ec = 1;
        string page = e[fd];
        uint page_len = page.byteLength();
        uint cap = math.min(page_len, count);
        out = page.substr(0, cap);
        /*
EAGAIN   fd is not a socket and has been marked nonblocking (O_NONBLOCK), and the read would block
EWOULDBLOCK fs is a socket and has been marked nonblocking (O_NONBLOCK), and the read would block.
EBADF    fd is not a valid file descriptor or is not open for reading.
EFAULT   buf is outside your accessible address space.
EINTR    The call was interrupted by a signal before any data was read; see signal(7).
EINVAL   fd is attached to an object which is unsuitable for reading; or the file was opened with the O_DIRECT flag, and either
                dress specified in buf, the value specified in count, or the file offset is not suitably aligned.
EIO I/O error. process is in a background process group, tries to read from its controlling terminal
EISDIR fd refers to a directory.*/

    }

    function write(uint16 fd, string buf, uint32 count, string[] e) external pure returns (uint32 b_count, uint16 errno, string[] env) {
        env = e;
        string fd_table = e[IS_FD_TABLE];
        string page = e[fd];
        string cur_val = _val(format("{}", fd), fd_table);
        if (cur_val.empty()) {
            // error
        } else {
            page.append(buf);
            env[fd] = page;
        }

       /*
EDESTADDRREQ fd refers to a datagram socket for which a peer address has not been set using connect(2).
EDQUOT The user's quota of disk blocks on the filesystem containing the file referred to by fd has been exhausted.
EFAULT buf is outside your accessible address space.
EFBIG  An attempt was made to write a file that exceeds the implementation-defined maximum file size or the process's file size  limit,
    or to write at a position past the maximum allowed offset.
EINTR  The call was interrupted by a signal before any data was written; see signal(7).
EINVAL fd  is  attached to an object which is unsuitable for writing; or the file was opened with the O_DIRECT flag, and either the ad‐
    dress specified in buf, the value specified in count, or the file offset is not suitably aligned.
EIO    A low-level I/O error occurred while modifying the inode.  rite-back of data written by an earlier write(), which  may have been issued to a different file descriptor on the same file.

ENOSPC The device containing the file referred to by fd has no room for the data.
EPERM  The operation was prevented by a file seal; see fcntl(2).
EPIPE  fd is connected to a pipe or socket whose reading end is closed.  When this happens the writing process will also receive a SIG‐
    PIPE signal.  (Thus, the write return value is seen only if the program catches, blocks or ignores this signal.)    */
    }

    function b_exec(string[] e) external pure returns (uint8 ec, string out, Write[] wr) {
        ec = 0;
        (string[] params, string flags, ) = _get_args(e[IS_ARGS]);
    }

    function _get_arg_value_uint16(string arg) internal pure returns (uint16 ec, uint16 val) {
        optional(int) arg_val = stoi(arg);
        if (!arg_val.hasValue())
            ec = 1;
        else
            val = uint16(arg_val.get());
    }

    function _true() internal pure returns (uint16) {
        return 0;
    }

    function _false() internal pure returns (uint16) {
        return 1;
    }

    function _exit(string args) internal pure returns (uint16 ec) {
        uint16 arg_val;
        if (!args.empty())
            (ec, arg_val) = _get_arg_value_uint16(args);
        return ec > 0 ? ec : arg_val;
    }

    function _logout(string args) internal pure returns (uint16 ec) {
        uint16 arg_val;
        if (!args.empty())
            (ec, arg_val) = _get_arg_value_uint16(args);
        return ec > 0 ? ec : arg_val;
    }

    function _return(string args) internal pure returns (uint16 ec) {
        uint16 arg_val;
        if (!args.empty())
            (ec, arg_val) = _get_arg_value_uint16(args);
        return ec > 0 ? ec : arg_val;
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"builtin",
"[shell-builtin [arg ...]]",
"Execute shell builtins.",
"Execute SHELL-BUILTIN with arguments ARGs without performing command lookup.",
"",
"",
"Returns the exit status of SHELL-BUILTIN, or false if SHELL-BUILTIN is not a shell builtin.");
    }

}
