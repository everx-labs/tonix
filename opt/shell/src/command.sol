pragma ton-solidity >= 0.63.0;

import "pbuiltin.sol";
import "xio.sol";
import "libkeg.sol";
import "libshellenv.sol";
import "inode.sol";
import "fs.sol";

contract command is pbuiltin {

    using sbuf for s_sbuf;
    using libkeg for uma_keg;

    uint16 constant CDESC_ALL       = 1; // type -a
    uint16 constant CDESC_SHORTDESC = 2; // command -V
    uint16 constant CDESC_REUSABLE  = 4; // command -v
    uint16 constant CDESC_TYPE      = 8; // type -t
    uint16 constant CDESC_PATH_ONLY = 16; // type -p
    uint16 constant CDESC_FORCE_PATH= 32; // type -ap or type -P
    uint16 constant CDESC_NOFUNCS   = 64; // type -f

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        string[][] ev = e.environ;
        string cmd = vars.val("COMMAND", ev[sh.VARIABLE]);
        string argv = vars.val("@", ev[sh.VARIABLE]);
        string[] hash_pool = ev[sh.PATHHASH];
        string path = vars.get_pool_record(cmd, hash_pool);
        if (path.empty()) {
            rc = EXIT_FAILURE;
        } else {
            string exec_line = "./" + path + "/" + cmd + " " + argv;
            e.environ[sh.PIPELINE].push(exec_line);
        }
    }

    /*function print(string args, string pool) external pure returns (uint8 ec, string out) {
        (string[] params, string flags, ) = arg.get_args(args);
        bool descr = arg.flag_set("v", flags);
        bool verbose = arg.flag_set("V", flags);
        for (string arg: params) {
            string t = vars.get_array_name(arg, pool);
            string value;
            if (t == "keyword")
                value = descr ? arg : (arg + " is a shell keyword");
            else if (t == "alias") {
                string val = vars.val(arg, pool);
                value = descr ? "alias " + arg + "=" + str.squote(val) : (arg + " is aliased to `" + val + "\'");
            } else if (t == "function")
                value = descr ? arg : (arg + " is a function\n" + vars.print_reusable(vars.get_pool_record(arg, pool)));
            else if (t == "builtin")
                value = descr ? arg : (arg + " is a shell builtin");
            else if (t == "command") {
                string path_map = vars.get_pool_record(arg, pool);
                string path;
                if (!path_map.empty())
                    (, path, ) = vars.split_var_record(path_map);
                if (!path.empty())
                    value = descr ? arg : (arg + " is hashed (" + path + "/" + arg + ")");
                else {
                    value = "/bin/" + arg;
                    if (verbose)
                        value = arg + " is " + value;
                }
            } else {
                ec = EXECUTE_FAILURE;
                if (verbose)
                    out.append("-tosh: command: " + arg + ": not found\n");
            }
            out.append(value + "\n");
        }
    }*/

    function _export_env(string varss) internal pure returns (string[] env) {
        (string[] lines, ) = varss.split("\n");
        for (string line: lines) {
            (string attrs, string name, string value) = vars.split_var_record(line);
            if (vars.match_attr_set("-x", attrs))
                env.push(name + "=" + value);
        }
    }

    function _file_stati(s_proc p, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) internal pure returns (s_of[] fdt, s_dirent[] pa, string out) {
        uint16 wd = p.p_pd.pwd_cdir.inono();
        s_of[] fdt_ofiles = p.p_fd.fdt_ofiles;
        uint16 counter = p.p_fd.fdt_nfiles;

        s_sbuf s;
        uint16 index;
        uint16 bs = sb.get_block_size(inodes);
        pa = p.p_args.ar_misc.pos_args;
        for (uint i = 0; i < pa.length; i++) {
            s_dirent de = pa[i];
            string name = de.d_name;
            uint8 t;
            if (name.substr(0, 1) == "/") {
                index = fs.resolve_absolute_path(name, inodes, data);
                if (index >= sb.ROOT_DIR && inodes.exists(index))
                    t = libstat.mode_to_file_type(inodes[index].mode);
            } else
                (index, t, , ) = fs.resolve_relative_path(name, wd, inodes, data);
            out.append(vars.var_record(libstat.file_type_sign(t), name, str.toa(index)) + "\n");
            if (index >= sb.ROOT_DIR) {
                if (!_is_open(fdt_ofiles, index)) {
                    s.sbuf_new(data[index], inodes[index].file_size, 0);
                    s.sbuf_finish();
                    fdt.push(s_of(_attr(inodes[index], bs, index), io.SRD, counter++, name, 0, s));
                }
                pa[i] = s_dirent(index, t, name);
            }
        }
    }

    function _is_open(s_of[] fdt, uint16 index) internal pure returns (bool) {
        for (s_of f: fdt)
            if (f.inono() == index)
                return true;
        return false;
    }

    function _attr(Inode ino, uint16 bs, uint16 i) internal pure returns (uint) {
        (uint16 mode, uint16 owner_id, uint16 group_id, uint16 n_links, uint16 device_id, uint16 n_blocks, uint32 file_size, uint32 modified_at, uint32 last_modified, ) = ino.unpack();
        return (uint(device_id) << 224) + (uint(i) << 208) + (uint(mode) << 192) + (uint(n_links) << 176) + (uint(owner_id) << 160) + (uint(group_id) << 144) +
            (uint(file_size) << 96) + (uint(bs) << 80) + (uint(n_blocks) << 64) + (uint(modified_at) << 32) + last_modified;
    }

    function _name() internal pure override returns (string) {
        return "command";
    }

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
_name(),
"[-pVv] command [arg ...]",
"Execute a simple command or display information about commands.",
"Runs COMMAND with ARGS suppressing shell function lookup, or display information about the specified COMMANDs. Can be used to invoke commands on disk when a function with the same name exists.",
"-p    use a default value for PATH that is guaranteed to find all of the standard utilities\n\
-v    print a description of COMMAND similar to the `type' builtin\n\
-V    print a more verbose description of each COMMAND",
"",
"Returns exit status of COMMAND, or failure if COMMAND is not found.");
    }
}
