pragma ton-solidity >= 0.55.0;

import "Shell.sol";

contract pushd is Shell {

    function read_fs_to_env(Job job_in, mapping (uint => ItemHashMap) env_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (Job job, mapping (uint => ItemHashMap) env) {
        (, , , , , , , , , , , string[] args, string short_options, , , , , , ) = job_in.unpack();
        bool change_dir = !_get_option_value(short_options, "n");

        env = env_in;
        string home_dir = _lookup_value("shell_vars", "HOME", env);
        string cur_dir = _lookup_value("shell_vars", "PWD", env);

        if (args.empty())
            args.push("~");
        string arg = args[0];
        string new_dir;
        if (arg == "~")
            new_dir = home_dir;
        else if (arg == "-")
            new_dir = _lookup_value("shell_vars", "OLDPWD", env);
        else
            new_dir = cur_dir + "/" + arg;
        uint16 pwd_index = _resolve_absolute_path(cur_dir, inodes, data);
        if (pwd_index > INODES) {
            string abs_path = _get_absolute_path(pwd_index, inodes, data);
            (/*uint16 index*/, uint8 file_type, ) = _lookup_dir_ext(inodes[pwd_index], data[pwd_index], arg);
            if (file_type != FT_UNKNOWN)
                job.s_action = "update_env";
            else
                job.ec = 1;
//            Arg arg_a = _dereference(follow_symlinks ? EXPAND_SYMLINKS : 0, arg, pwd_index, inodes, data);
//            (string path, uint8 ft, uint16 ino, , ) = arg_a.unpack();
            if (change_dir) {
                env[tvm.hash("shell_vars")].value[tvm.hash("PWD")] = Item("PWD", TYPE_STRING, abs_path);
                uint16 nwd = pwd_index;
                cur_dir = _get_absolute_path(nwd, inodes, data);
                env[tvm.hash("shell_vars")].value[tvm.hash("OLDPWD")].value = cur_dir;
                env[tvm.hash("shell_vars")].value[tvm.hash("PWD")].value = new_dir;
            }
        }
    }

  //      if (((flags & _e + _P) > 0) && wd < INODES)
//            es.push(Err(0, ENOENT, s));
        /*if (ino < INODES)
            es.push(Err(0, ENOENT, path));
        else if (ft != FT_DIR)
            es.push(Err(0, ENOTDIR, path));
        else if (es.empty()) {*/
//        }

    function _dereference(uint16 mode, string s_arg, uint16 wd, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (Arg) {
        bool expand_symlinks = (mode & EXPAND_SYMLINKS) > 0;
        (uint16 ino, uint8 ft, uint16 parent, uint16 dir_index) = _resolve_relative_path(s_arg, wd, inodes, data);
        Inode inode;
        if (ino > 0 && inodes.exists(ino))
            inode = inodes[ino];
        if (expand_symlinks && ft == FT_SYMLINK) {
            (ft, s_arg, ino) = _get_symlink_target(inode, data[ino]).unpack();
        }
        return Arg(s_arg, ft, ino, parent, dir_index);
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
            "pushd",
            "[-n] [+N | -N | dir]",
            "Add directories to stack.",
            "\
Adds a directory to the top of the directory stack, or rotates the stack, making the new top\n\
of the stack the current working directory.  With no arguments, exchanges the top two directories.",
            "\
-n        Suppresses the normal change of directory when adding directories to the stack, so only the stack is manipulated.",
            "\
+N        Rotates the stack so that the Nth directory (counting from the left of the list shown by `dirs', starting with zero) is at the top.\n\
-N        Rotates the stack so that the Nth directory (counting from the right of the list shown by `dirs', starting with zero) is at the top.\n\
dir       Adds DIR to the directory stack at the top, making it the new current working directory.\n\
The `dirs' builtin displays the directory stack.",
            "Returns success unless an invalid argument is supplied or the directory change fails.");
    }

}
