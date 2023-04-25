pragma ton-solidity >= 0.67.0;

import "libstr.sol";
import "common.h";
import "libsb.sol";
import "libufsd.sol";
contract ixeen is common {

    function mmap(uint32 a, uint32 n) external view returns (mapping (uint32 => TvmCell) m) {
        return libvmem.mmap(_ram, a, n);
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
    string constant PP = "dump";
    string constant Q_PREFIX = "tonos-cli -c etc/";
    string constant Q_SUFFIX = ".conf runx -m ";
    string constant C_SUFFIX = ".conf callx -m ";
    string constant SELF_Q = Q_PREFIX + SELF + Q_SUFFIX;
    string constant PQ = Q_PREFIX + "dump" + Q_SUFFIX;
    bytes constant QUICKS = "cCuUhHbBqQwWxXzZ";
    uint constant CLAST = 7;
    enum MENU { MAIN, DUMP, ALLOC, CMP, FIX, ULIB, LAST }
    string[][] constant MCS = [
        ["UFS disk helper", "Dump", "Allocate", "Compare", "Mirror", "Library"],
        ["Dump", "Memory", "Cylinder groups", "UFS disk header", "Superblock", "Root", "Inode table", "Open files" ],
        ["Allocate", "Dirs", "Inodes", "Blocks", "Root" ],
        ["Compare", "-"],
        ["Adjust", "-"],
        ["UFS library", "Get inode", "Current inode", "Put inode"]
    ];

    function _ulib(uint n) internal pure returns (string cmd) {
        if (n == 1) {
            cmd.append(_print_cmd("Inode number?\n"));
            cmd.append("read -r ii && " + SELF_Q + " oin --n $ii --t " + format("{}", n + 4) + " >tmp/oin.res\n");
        } else if (n == 2) {
            cmd.append(SELF_Q + " oin --n 0 --t " + format("{}", n + 4) + " >tmp/oin.res\n");
        } else if (n == 3) {
            cmd.append(SELF_Q + " oin --n 1 --t " + format("{}", n + 4) + " >tmp/oin.res\n");
        } else
            return cmd;
        cmd.append("jq -r .out tmp/oin.res\n");
        cmd.append("jq -r .cmd tmp/oin.res >tmp/scr && source tmp/scr\n");
    }
    function _fix(uint n) internal pure returns (string cmd) {
        cmd;n;
    }

    function _cmp(uint n) internal pure returns (string cmd) {
        n;cmd;
    }

    function _alloc_dirs(ufsd ud, uint8 n) internal view returns (ufsd d, mapping (uint32 => TvmCell) res) {
        uint16 stt = ud.cg.nino;
        uint16 bn = ud.cg.nblk;
        TvmBuilder b;
        uint16 des = ud.fs.desize;
        uodir uod = abi.decode(_ram[ud.dp], uodir);
        (TvmCell pdc, , ) = uod.unpack();
        udinode pdi = abi.decode(pdc, udinode);
//        udinode pdi = abi.decode(_ram[ud.dp], udinode);
        uint16 pino = pdi.ino;
//        udirent[] pdes = abi.decode(_ram[pdi.db1], udirent[]);
        udinode di = udinode(DEF_DIR_MODE, stt, 2, 2 * des, block.timestamp, bn, bn + 1, 2, UID_ROOT, uint8(GID_WHEEL));

        TvmCell tc = libufsd.tdots(stt, pino);
        TvmCell nc = libufsd.conc();
//        udirent dot = udirent(FT_DIR, stt, uint32(libufsd._tag_name(1, 1, 0, 1)));
//        udirent dotdot = udirent(FT_DIR, pdi.ino, uint32(libufsd._tag_name(2, 1, 1, 2)));
        repeat(n) {
            b.store(di);
            res[bn] = tc;
            res[bn + 1] = nc;
//            pdes.push(udirent(FT_DIR, ud.dp, 2, 1, 1, 2));
            stt++;
            bn += 2;
            tc = libufsd.tdots(stt, pino);
            di.ino = stt;
            di.db1 = bn;
            di.db2 = bn + 1;
        }
        d = ud;
    }

    function oin(uint8 n, uint8 t) external view returns (ufsd ud, string cmd, string out, mapping (uint32 => TvmCell) res) {
        ud = read_ufs_disk();
        uint16 stt = ud.cg.nino;
        uint16 bn = ud.cg.nblk;
        if (t == 1) {
//            (ud, res) = _alloc_dirs(ud, n);
            udinode[] udis = abi.decode(_ram[ud.inoblock], udinode[]);
            uint clen = udis.length;
            if (clen + n > ud.fs.inopb)
                out.append("Can't allocate that many\n");
            uint cap = math.min(n, ud.fs.inopb - clen);

            uint16 des = ud.fs.desize;
            uodir uod = abi.decode(_ram[ud.dp], uodir);
            (TvmCell pdc, , ) = uod.unpack();
            udinode pdi = abi.decode(pdc, udinode);
            uint16 pino = pdi.ino;
            udinode di = udinode(DEF_DIR_MODE, stt, 2, 2 * des, block.timestamp, bn, bn + 1, 2, UID_ROOT, uint8(GID_WHEEL));
            TvmCell nc = libufsd.conc();

            repeat(cap) {
                di.ino = stt;
                di.db1 = bn;
                di.db2 = bn + 1;
                udis.push(di);
                TvmCell tc = libufsd.tdots(stt, pino);
                res[bn] = tc;
                res[bn + 1] = nc;
                stt++;
                bn += 2;
            }
            res[ud.inoblock] = abi.encode(udis);
            ud.alloc_dirs(uint8(cap));
            cmd.append(PQ + " pp -- --t 21 " + _fc("c", ud.inoblock) + " | jq -r .out\n");
            cmd.append(PQ + " pp -- --t 16 " + _fc("c", UUDISK_LOC) + " | jq -r .out\n");
            cmd.append(PQ + " pcmp -- --t 21 " + _fc("c", ud.inoblock) + " | jq -r .out\n");
            cmd.append(PQ + " pcmp -- --t 16 " + _fc("c", UUDISK_LOC) + " | jq -r .out\n");
        } else if (t == 2)
            ud.alloc_inodes(n);
        else if (t == 3)
            ud.alloc_blocks(n);
        else if (t == 4) {
            ud.alloc_inodes(1);
            ud.alloc_dirs(1);
            udinode d0;
            res[250] = abi.encode(d0);
            stt++;
            udinode dr = udinode(DEF_DIR_MODE, stt, 2, 2 * ud.fs.desize, block.timestamp, bn, bn + 1, 2, UID_ROOT, uint8(GID_WHEEL));
            uint16 dp = ud.dp > 0 ? ud.dp : 251;
            res[dp] = abi.encode(dr);
            res[ud.inoblock] = abi.encode([d0, dr]);
            TvmCell tc = libufsd.tdots(1, 1);
            TvmCell nc = libufsd.conc();
            res[bn] = tc;
            res[bn + 1] = nc;
        } else if (t == 5) {
            out.append("Get inode\n");
            uint16 ndp = 0xFB + n;
            ud.dp = ndp;
            out.append("New inode: " + (ndp > 0 ? libufsd.print_udino(abi.decode(_ram[ndp], udinode)) : "none") + "\n");
            if (ndp > 0) {
                res[ndp] = _ram[ndp];
                udinode ndi = abi.decode(_ram[ndp], udinode);
                res[ndi.db1] = _ram[ndi.db1];
                res[ndi.db2] = _ram[ndi.db2];
                cmd.append(PQ + " pi -- --t 2 " + _fc("dic", ndp) + _fc("dc1", ndi.db1) + _fc("dc2", ndi.db2) + " | jq -r .out\n");
            }
        } else if (t == 6) {
            uint16 ndp = ud.dp;
            out.append("Current inode: ");
            if (ndp > 0) {
                res[ndp] = _ram[ndp];
                cmd.append(PQ + " pp -- --t 3 " + _fc("c", ndp) + " | jq -r .out\n");
            } else
                out.append("None\n");
        } else if (t == 7) {
            uint16 odp = ud.dp;
            uodir uod = abi.decode(_ram[odp], uodir);
            (TvmCell di, TvmCell tc, TvmCell nc) = uod.unpack();
            udinode cdi = abi.decode(di, udinode);
            udinode[] udis = abi.decode(_ram[ud.inoblock], udinode[]);
            res[cdi.db1] = tc;
            res[cdi.db2] = nc;
            cdi.size = uint24(libufsd._sizeof(tc) + libufsd._sizeof(nc));
            cdi.mtime = block.timestamp;
            udis[cdi.ino] = cdi;
            res[ud.inoblock] = abi.encode(udis);
         } else
            return (ud, cmd, out, res);
        res[UUDISK_LOC] = abi.encode(ud);
        out.append(libufsd.bcmp(_ram, res));
    }

    function _fc(string cn, uint n) internal pure returns (string cmd) {
        return " --" + cn + " `jq -r '.res | to_entries[] | select (.key == \"" + format("{}", n) + "\") .value' tmp/oin.res` ";
    }
    function _alloc(uint n) internal pure returns (string cmd) {
        if (n < 4) {
            cmd.append(_print_cmd("How many?\n"));
            cmd.append("read -r ii && " + SELF_Q + " oin --n $ii --t " + format("{}", n) + " >tmp/oin.res\n");
        } else if (n == 4)
            cmd = SELF_Q + " oin --n 1 --t " + format("{}", n) + " >tmp/oin.res\n";
        else
            return cmd;
        cmd.append("jq -r .out tmp/oin.res\n");
        cmd.append("jq -r .cmd tmp/oin.res >tmp/scr && source tmp/scr\n");
    }
//    function open_file(string name, ) internal returns (uofile uof) {
//        uint8 fdtype; // cwd/rtd/txt/mem/NOFD/
//        uint8 ftype;  // REG/DIR/FIFO/CHR/a_inode/unix/unknown
//        uint8 fd;
//        uint16 mode;  // r/w/u u: a_inode/unix
//        uint16 dev;
//        uint16 ino;	  // NULL or applicable vnode
//        uint24 szoff; // DFLAG_SEEKABLE specific fields
//        uint32 name;
//        return uofile()
//    }

//    function makedev(uint major, uint minor) internal returns (uint16) {
//        return uint16((major << 8) + minor);
//    }

//        mp1.cwd = uofile(FD_TYPE_CWD, FT_DIR, 0, 0, makedev(8, 32), 2, 30, "/");
//        mp1.rtd = uofile(FD_TYPE_RTD, FT_DIR, 0, 0, makedev(8, 32), 2, 30, "/");
//        mp1.txt = uofile(FD_TYPE_TXT, FT_REG, 0, 0, makedev(0, 20), 60000, 50000, "/init");

    function _dump(uint n) internal view returns (string out) {
        ufsd ud = read_ufs_disk();
        mapping (uint32 => TvmCell) m3 = _ram;
        if (n == 1)
            out.append(libvmem.dump_mem(m3));
        else if (n == 2) {
            ufsb f = ud.fs;
            uint16 i;
            repeat (f.ncg) {
                ug g = abi.decode(m3[f.cblkno + i], ug);
                out.append(libufsd.print_ug(g));
                i++;
            }
        } else if (n == 3)
            out.append(libufsd.print_disk_header(ud));
        else if (n == 4)
            out.append(libufsd.print_sb(ud.fs));
        else if (n == 5) {
            TvmCell c = _ram[0xFB];
            if (libufsd._sizeof(c) == 20) {
                udinode rd = abi.decode(c, udinode);
                udirent[] des = abi.decode(_ram[rd.db1], udirent[]);
                TvmSlice stas = _ram[rd.db2].toSlice();
                for (udirent de: des)
                    out.append(libufsd.get_name(de.tag, stas));
                out.append(libufsd.print_udino(rd));
            } else
                out.append("Wrong data size\n");
        } else if (n == 6) {
            udinode[] dis = abi.decode(_ram[ud.inoblock], udinode[]);
            for (udinode di: dis)
                out.append(libufsd.print_udino(di));
        } else if (n == 7) {

        }
    }
    function onc(uint h, string s) external view returns (uint hout, string cmd, string out) {
        if (s.empty())
            return (hout, cmd, out);
        bytes1 b0 = bytes(s)[0];
        uint8 v = uint8(b0);
        (uint idev, uint ct, uint ctx, uint itm, uint arg, uint val) = _from_handle(h);
        MENU ectx = MENU(ctx);
        uint nitm;

        if (libstr.strchr(QUICKS, b0) > 0) {    // quick command
            if (v >= 0x41 && v <= 0x5A) // convert to lowercase
                v += 0x20;
            if (v == 0x62)  // go back to main menu
                ectx = MENU.MAIN;
            else    // execute a quick command
                cmd.append(_quick_command(v));
            nitm = itm;
        } else if (v >= 0x30 && v <= 0x39) {    // decimal digit
            uint8 n = v - 0x30; // digit ascii to value
            if (ectx == MENU.MAIN)   // switch context to a sub-menu
                ectx = MENU(n);
            else if (ectx == MENU.DUMP)
                out.append(_dump(n));
            else if (ectx == MENU.ALLOC)
                cmd.append(_alloc(n));
            else if (ectx == MENU.CMP)
                cmd.append(_cmp(n));
            else if (ectx == MENU.FIX)
                cmd.append(_fix(n));
            else if (ectx == MENU.ULIB)
                cmd.append(_ulib(n));
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