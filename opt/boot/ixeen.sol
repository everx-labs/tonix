pragma ton-solidity >= 0.67.0;

import "libstr.sol";
//import "libflags.sol";
import "disk_loader.sol";
import "libufs2.sol";
//library libcomplete {
//    uint8 constant ACTION_LAST = 7;
//    action_info[ACTION_LAST + 1] constant CA = [
//action_info("0", "menu", "", "menu", "", "",
//    "printf \"Quick commands:\n1) help\n2) compile\n3) update\n4) view\n5) apply\n6) discard\n7) quit\n\""),
//action_info("1", "help", "", "help", "", "", "run ixeen rpw --s help"),
//action_info("2", "compile", "", "compile", "", "", "make cc"),
//action_info("3", "update", "", "update", "", "", "make uc"),
//action_info("4", "view", "", "view changes", "", "", "[ -s st.args ] && tonos-cli -c etc/xeen.conf runx -m ck st.args | jq -r .out"),
//action_info("5", "apply", "", "apply changes", "", "", "[ -s st.args ] && tonos-cli -c etc/xeen.conf callx -m st st.args"),
//action_info("6", "discard", "", "discard changes", "", "", "rm -f st.args;"),
//action_info("7", "quit", "", "quit", "", "", "echo Bye! && exit 0")
//    ];
//}

contract ixeen is disk_loader {

    function main(string[] args, mapping (uint8 => string) flags) external view returns (string out, string err, mapping (uint32 => TvmCell) m) {
        uufsd ud = read_ufs_disk();
        uufsd2 d;
        d.clone(ud);
        mapping (uint32 => TvmCell) m3 = _ram;
        out.append(libvmem.dump_mem(m3));
//        d.map(m0);
        d.map(m3);
//        out.append(libufs2.print_disk_header(d));
        d.inherit_ufs();
        out.append(libufs2.print_disk_header(d));
        fsb f = d.d_fsb;
        uint16 i;
        repeat (f.ncg) {
            cg g = abi.decode(m3[d.d_fs.fs_cblkno + i], cg);
            out.append(libsb.print_cg(f, g));
            i++;
        }
    }
    TvmCell _rom;
    uint32 _version;
    function immap(mapping (uint32 => TvmCell) m) external accept {
        for ((uint32 a, TvmCell c): m)
            if (_ram[a] != c)
                _ram[a] = c;
    }
    function ldr(uint32 a, uint32 n) external view returns (TvmCell[] cc) {
        repeat(n) {
            if (_ram.exists(a))
                cc.push(_ram[a]);
            a++;
        }
    }
    function _dev_info() internal view returns (string out) {
        out.append(format("version: {}\n", _version));
    }

    function open() external pure returns (string cmd) {
        return "echo Welcome to Tonix!; read -p \"> \" -rsn1 inp; tonos-cli -c etc/$X.conf runx -m complete --b \"$inp\" >complete.res; cmd=`jq -r .cmd complete.res`; eval \"$cmd\"";
    }
    string constant SELF = "ixeen";
    string constant Q_PREFIX = "tonos-cli -c etc/";
    string constant Q_SUFFIX = ".conf runx -m ";
    string constant C_SUFFIX = ".conf callx -m ";
    string constant SELF_Q = Q_PREFIX + SELF + Q_SUFFIX;
    function complete(string b) external pure returns (string cmd) {
        for (cmd_info ci: CI)
            if (ci.hotkey == b) {
                string s = ci.name;
                cmd.append("read -p \"" + s + " \" input\n");
                cmd.append(SELF_Q + " rl2 --params \"$input\" --optstring \"" + ci.optstring + "\" >tmp/rl2\n");
                cmd.append(Q_PREFIX + s + Q_SUFFIX + " main -- tmp/rl2 >tmp/" + s + ".res\n");
                cmd.append("jq -r .out tmp/" + s + ".res\n");
                return cmd;
            }
        for (action_info ai: CA)
            if (ai.hotkey == b)
                return ai.body;
        return "echo ?" + b + "? press 0 for menu";
    }
    uint8 constant EXECUTE_SUCCESS  = 0;
    uint8 constant EXECUTE_FAILURE  = 1;
    uint8 constant EX_BADUSAGE      = 2;
    uint8 constant EX_NOTFOUND	= 127;
    struct cmd_info {
        string hotkey;
        string name;
        string optstring;
    }
    cmd_info[] constant CI = [
cmd_info("", "", ""),
cmd_info("h", "help",    "dms"),
cmd_info("d", "dump",    "abcdefghi:j:k:l:m:n:"),
cmd_info("m", "mount",   "adflpruvwo:t:F:"),
cmd_info("i", "image",   "acnrsQb:B:I:o:"),
cmd_info("l", "bsdlabel","enwARf:"),
cmd_info("g", "gpart",   "lprFNa:b:f:i:n:s:t:"),
cmd_info("n", "newfs",   "acjnqvDFSVb:C:i:I:J:G:N:d:m:o:g:L:M:O:p:r:E:t:T:U:e:z:"),
cmd_info("s", "stat",    "f"),
cmd_info("a", "access",  ""),
cmd_info("e", "examine", ""),
cmd_info("r", "read",    ""),
cmd_info("w", "write",   ""),
cmd_info("f", "fetch",   ""),
cmd_info("t", "store",   ""),
cmd_info("b", "boot",    "qv"),
cmd_info("u", "ufsd",     "")];
    action_info[6] constant CA = [
action_info("",  "",        ""),
action_info("0", "menu",    "printf \"Quick commands:\n1) help\n2) menu\n3) compile\n4) update\n5) quit\n\""),
action_info("3", "compile", "make cc"),
action_info("4", "update",  "make up_tsh"),
action_info("5", "quit",    "echo Bye! && exit 0")
    ];
    struct action_info {
        string hotkey;
        string name;
        string body;
    }
    function rl2(string params, string optstring) external pure returns (uint8 ec, string[] args, mapping (uint8 => string) flags) {
        return _rl2(params, optstring);
    }
    function _rl2(bytes s, bytes optstring) internal pure returns (uint8 ec, string[] args, mapping (uint8 => string) flags) {
        uint8 opt_name;
        uint[] tp = libstr.strtok(s, 0x20);
        uint pos;
        for (uint te: tp) {
            bytes w = pos > 0 ? s[pos + 1 : te] : s[ : te];
            pos = te;
            uint wl = w.length;
            if (wl == 0)
                continue;
            if (w[0] == '-' && wl > 1) {
                bytes1 b = w[1];
                uint8 v = uint8(b);
                uint q = libstr.strchr(optstring, b);
                if (q == 0) {
                    ec = EX_BADUSAGE;
                    break;
                }
                if (optstring[q] == ":")
                    opt_name = v;
                else
                    flags[v] = "";
            } else {
                if (opt_name > 0) {
                    flags[opt_name] = w;
                    opt_name = 0;
                } else
                    args.push(w);
            }
        }
    }
}
