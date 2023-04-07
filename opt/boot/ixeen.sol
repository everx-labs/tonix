pragma ton-solidity >= 0.67.0;

import "libstr.sol";
import "common.h";
import "libsb.sol";
import "libufsd.sol";
contract ixeen is common {

    function libu(ufsd ud, uint8 n) external pure returns (ufsd d, mapping (uint32 => TvmCell) res, string out, string cmd) {
        d = ud;
        res;
        out;cmd;
        if (n == 1) {

        } else if (n == 2) {

        }
    }
    function read_ufs_disk() internal view returns (ufsd) {
        uint32 a = UUDISK_LOC;
        if (_ram.exists(a)) {
            return abi.decode(_ram[a], ufsd);
        }
    }
    uint8 constant UUDISK_LOC = 5;
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
    bytes constant QUICKS = "cCuUhHbBqQwWxXzZ";
    uint constant CLAST = 7;
    enum MENU { MAIN, DUMP, ALLOC, CMP, MIR, LAST }
    string[][] constant MCS = [
        ["UFS disk helper", "Dump", "Allocate", "Compare", "Mirror", "Details"],
        ["Dump", "Memory", "Cylinder groups", "UFS disk header", "Superblock", "Root", "Inode table" ],
        ["Allocate", "Dirs", "Inodes", "Blocks", "Root" ],
        ["Compare", "cgget", "cgput", "Apply"],
        ["Adjust", "Data block count"],
        ["Details", "Info"]
    ];
    function _mir(uint n) internal view returns (string cmd) {
        cmd;
        ufsd ud = read_ufs_disk();
        if (n == 1) {
//            ud.
        }
//            return CO_Q + " mk --n " + format("{}", dev_id) + " | jq -r .out\n";
    }
    function _cmp(uint n) internal view returns (string cmd) {
        ufsd ud = read_ufs_disk();
        if (n == 1) {
            cmd.append(SELF_Q + " oa --h $h --n " + format("{} --t {} ", ud.ccg, n) + " >tmp/oa.res\n");
//            cmd.append()
        }
//            return CO_Q + " mk --n " + format("{}", dev_id) + " | jq -r .out\n";
    }

    function _alloc_dirs(ufsd ud, uint8 n) internal view returns (ufsd d, mapping (uint32 => TvmCell) res) {
        uint16 stt = ud.cg.nino;
        uint16 bn = ud.cg.nblk;
        TvmBuilder b;
        uint16 des = ud.fs.desize;
        udinode pdi = abi.decode(_ram[ud.dp], udinode);
//        udirent[] pdes = abi.decode(_ram[pdi.db1], udirent[]);
        udinode di = udinode(DEF_DIR_MODE, stt, 2, 2 * des, block.timestamp, bn, 0, 1, UID_ROOT, uint8(GID_WHEEL));
        udirent dot = udirent(FT_DIR, stt, 1, 1, 0, 1);
        udirent dotdot = udirent(FT_DIR, pdi.ino, 2, 1, 1, 2);
        repeat(n) {
            b.store(di);
            res[bn] = abi.encode([dot, dotdot]);
//            pdes.push(udirent(FT_DIR, ud.dp, 2, 1, 1, 2));
            stt++;
            bn++;
            dot.ino = stt;
            di.ino = stt;
            di.db1 = bn;
        }
        d = ud;
    }

    function oa(uint h, uint8 n, uint8 t) external view returns (ug g1, ug g2, mapping (uint32 => TvmCell) res) {
        h;
        ufsd ud = read_ufs_disk();
        ufsb f = ud.fs;
        g1 = ud.cg;
        g2 = abi.decode(_ram[f.cblkno + n], ug);
        if (t == 1) {

        } else if (t == 2) {

        } else if (t == 3) {

        } else
            return (g1, g2, res);
        res[f.cblkno + n] = abi.encode(g1);
    }

    function oin(uint h, uint8 n, uint8 t) external view returns (ufsd ud1, ufsd ud2, mapping (uint32 => TvmCell) res) {
        h;
        ud1 = read_ufs_disk();
        ud2 = ud1;
        uint16 stt = ud1.cg.nino;
        uint16 bn = ud1.cg.nblk;
        if (t == 1) {
            (ud2, res) = _alloc_dirs(ud1, n);
            ud2.alloc_dirs(n);
        } else if (t == 2)
            ud2.alloc_inodes(n);
        else if (t == 3)
            ud2.alloc_blocks(n);
        else if (t == 4) {
            ud2.alloc_inodes(1);
            ud2.alloc_dirs(1);
            udinode d0;
            res[250] = abi.encode(d0);
            stt++;
            udinode dr = udinode(DEF_DIR_MODE, stt, 2, 2 * ud2.fs.desize, block.timestamp, bn, 0, 1, UID_ROOT, uint8(GID_WHEEL));
            uint16 dp = ud2.dp > 0 ? ud2.dp : 251;
            res[dp] = abi.encode(dr);
            res[ud2.inoblock] = abi.encode([d0, dr]);
            udirent dot = udirent(FT_DIR, stt, 1, 1, 0, 1);
            udirent dotdot = udirent(FT_DIR, stt, 2, 1, 1, 2);
            res[bn] = abi.encode([dot, dotdot]);


        } else
            return (ud1, ud2, res);
        res[UUDISK_LOC] = abi.encode(ud2);
    }

    function _input(uint t) internal pure returns (string cmd) {
        string out = "How many?\n";
        cmd.append(_print_cmd(out));
        cmd.append("read -r ii && " + SELF_Q + " oin --h $h --n $ii --t " + format("{}", t) + " >tmp/oin.res\n");
//        cmd.append("h=`jq -r .hout tmp/oin.res`\n");
//        cmd.append("run_input $IDEV\n");
    }

    function _alloc(uint n) internal pure returns (string cmd) {
        if (n == 1)
            cmd = _input(n);
        else if (n == 2)
            cmd = _input(n);
        else if (n == 3)
            cmd = _input(n);
        else if (n == 4)
            cmd = SELF_Q + " oin --h $h --n 1 --t " + format("{}", n) + " >tmp/oin.res\n";
    }
    function _dump(uint n) internal view returns (string out) {
        ufsd ud = read_ufs_disk();
        mapping (uint32 => TvmCell) m3 = _ram;
        if (n == 1)
            out.append(libvmem.dump_mem(m3));
        else if (n == 4)
            out.append(libufsd.print_sb(ud.fs));
        else if (n == 3)
            out.append(libufsd.print_disk_header(ud));
        else if (n == 5) {
//            out.append(libufsd.print_disk_header(ud));
            out.append(libufsd.print_udino(abi.decode(_ram[0xFB], udinode)));
        } else if (n == 6) {
            udinode[] dis = abi.decode(_ram[ud.inoblock], udinode[]);
            for (udinode di: dis)
                out.append(libufsd.print_udino(di));
//            out.append(libufsd.print_disk_header(ud));
        } else {
            ufsb f = ud.fs;
            uint16 i;
            repeat (f.ncg) {
                ug g = abi.decode(m3[f.cblkno + i], ug);
                if (n == 2)
                    out.append(libufsd.print_ug(g));
                i++;
            }
        }
    }
    function onc(uint h, string s) external view returns (uint hout, string cmd, string out) {
//    function onc(uint h, string s, ufsd udin) external view returns (uint hout, string cmd, string out, ufsd ud) {
//        ud = udin;
        if (s.empty())
            return (hout, cmd, out);
        bytes1 b0 = bytes(s)[0];
        uint8 v = uint8(b0);
        (uint idev, uint ct, uint ctx, uint itm, uint arg, uint val) = _from_handle(h);
        MENU ectx = MENU(ctx);
        uint nitm;

        if (libstr.strchr(QUICKS, b0) > 0) {    // quick co    mmand
            if (v >= 0x41 && v <= 0x5A) // convert to lowercase
                v += 0x20;
            if (v == 0x62)  // go back to main menu
                ectx = MENU.MAIN;
//            else if (v == 0x68)
//                out.append(_print_help(ctx, itm));
            else    // execute a quick command
                cmd.append(_quick_command(v));
            nitm = itm;
        } else if (v >= 0x30 && v <= 0x39) {    // decimal digit
            uint8 n = v - 0x30; // digit ascii to value
            if (ectx == MENU.MAIN)   // switch context to a sub-menu
                ectx = MENU(n);
            else if (ectx == MENU.DUMP)  // do
                out.append(_dump(n));
            else if (ectx == MENU.ALLOC)  // do
                cmd.append(_alloc(n));
            else if (ectx == MENU.CMP)  // do
                cmd.append(_cmp(n));
            else if (ectx == MENU.MIR)  // do
                cmd.append(_mir(n));
            if (n == 0) // '0' prints current menu
                out.append(print_menu(ectx));
            nitm = n;
        }
        if (ectx != MENU(ctx)) {  // remember the current context
            nitm = 0;
            out.append(print_menu(ectx));
        }
        hout = _to_handle(idev, ct, uint(ectx), nitm, arg, val);
//        if (!out.empty())
//            cmd.append(_print_cmd(out));
    }

    function _print_cmd(string s) internal pure returns (string) {
        return "printf \"" + s + "\";";
    }
    function print_menu(MENU n) internal view returns (string out) {
        return print_list_menu(MCS[uint(n < MENU.LAST ? n : MENU.MAIN)]);
    }
    function _quick_command(uint8 v) internal pure returns (string cmd) {
        mapping (uint8 => string) q;
        q[0x63] = "make cc";
        q[0x75] = "make up_" + SELF;
//        q[0x77] = "make up_" + CO;
        q[0x71] = "echo Bye! && exit 0";
        q[0x78] = "set -x";
        q[0x7A] = "set +x";
        return q.exists(v) ? q[v] : "echo Unrecognized quick command";
    }
    function print_list_menu(string[] items) internal pure returns (string out) {
        uint len = items.length;
        if (len > 0)
            out.append(items[0] + "\n\n");
        for (uint i = 1; i < len; i++)
            out.append(format("{}) {}\n", i, items[i]));
    }

}


//    function conv_ufs_ud() external view returns (ufsd ud, TvmCell c) {
////        uint32 a = UUDISK_LOC2;
//        uufs2d ud2 = abi.decode(_ram[UUDISK_LOC2], uufs2d);
//        (string name, uint8 ufsv, uint8 fd, uint32 bsize, uint16 sblock, uint16 si, uint16 inoblock, uint16 inomin, uint16 inomax,
//            uint16 dp, ufsb fs, , uint16 ccg, uint16 lcg, string error, uint16 sblockloc, uint8 lookupflags, uint8 mine) = ud2.unpack();
//        ug cg0 = abi.decode(_ram[UUDISK_LOC + 1], ug);
//        ud = ufsd(name, ufsv, fd, bsize, sblock, si, inoblock, inomin, inomax, dp, fs, cg0, ccg, lcg, error, sblockloc, lookupflags, mine);
//        c = abi.encode(ud);
//        uint16 nino;
//        uint16 nblk;
//        repeat (4) {
//            a++;
//            if (_ram.exists(a)) {
//                cg d_cg = abi.decode(_ram[a], cg);
//                (uint16 cgmagic, uint16 cgx, csum cs, uint16 ndblk, uint16 iusedoff, uint16 freeoff, , , uint16 niblk, uint16 rotor, uint16 irotor, , uint16 nextfreeoff,
//                    uint16 initediblk, uint16 unrefs, , uint16 space, ) = d_cg.unpack();
//                (uint16 cs_ndir, uint16 cs_nbfree, uint16 cs_nifree, )  = cs.unpack();
//                csum2 cs2 = csum2(cs_ndir, cs_nbfree, cs_nifree);
//                ucg g = ucg(cgx, cs2, ndblk, iusedoff, freeoff, niblk, rotor, irotor, nextfreeoff, initediblk, unrefs, space, cgmagic);
//                ug u = ug(g, nino, nblk, 0, 0);
//                nino += cs_nifree;
//                nblk += cs_nbfree;
//                gg.push(u);
//                cc.push(abi.encode(u));
//            }
//        }
//    }
//    function conv_ufs_disk() external view returns (uufs2d, TvmCell c) {
//        uint32 a = UUDISK_LOC;
//        if (_ram.exists(a)) {
//            uufsd ud1 = abi.decode(_ram[a], uufsd);
//            (bytes8 name, uint8 ufsv, uint8 fd, uint32 blen, uint16 sblock, uint16 si, uint16 inoblock,
//                uint16 inomin, uint16 inomax, uint16 dp, fsb d_fsb, fss d_fss, cg d_cg, uint16 ccg, uint16 lcg, ,
//                uint16 sblockloc, uint8 lookupflags, uint8 mine) = ud1.unpack();
//            (uint16 cgmagic, uint16 cgx, csum cs, uint16 ndblk, uint16 iusedoff, uint16 freeoff, , , uint16 niblk, uint16 rotor, uint16 irotor, , uint16 nextfreeoff,
//                uint16 initediblk, uint16 unrefs, , uint16 space, ) = d_cg.unpack();
//            (uint16 sbmagic, uint16 sblkno, uint16 cblkno, uint16 iblkno, uint16 dblkno, uint16 ncg, uint16 bsize, , , , uint16 maxcontig, uint16 maxbpg, uint16 id,
//                uint16 fsbtodb, uint16 ipg, , , ,  uint16 sbsize, , uint16 cssize, uint16 cgsize, uint16 inosize, uint16 desize, ) = d_fsb.unpack();
//            (, uint8 clean, , , , , , csum_total cstotal, uint32 time, uint16 size, uint16 dsize, ) = d_fss.unpack();
//            (uint16 cs_ndir, uint16 cs_nbfree, uint16 cs_nifree, , ) = cstotal.unpack();
//            csum2 cs2 = csum2(cs_ndir, cs_nbfree, cs_nifree);
//            ucg g = ucg(cgx, cs2, ndblk, iusedoff, freeoff, niblk, rotor, irotor, nextfreeoff, initediblk, unrefs, space, cgmagic);
//            ufsb fs = ufsb(sblkno, cblkno, iblkno, dblkno, ncg, bsize, maxcontig, maxbpg, fsbtodb, id, sbsize, cssize, cgsize, inosize, desize, bsize / inosize, ipg, cs2, clean > 0 ? 1 : 0, "", "", time, size, dsize, sbmagic);
//            uufs2d u2 = uufs2d(string(bytes(name)), ufsv, fd, blen, sblock, si, inoblock, inomin, inomax, dp, fs, g, ccg, lcg, "", sblockloc, lookupflags, mine);
//            return (u2, abi.encode(u2));
//        }
//    }
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