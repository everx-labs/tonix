pragma ton-solidity >= 0.60.0;

import "../../include/Utility.sol";
import "../sys/vn.sol";
import "../sys/uma.sol";

contract vnp is Utility {

    using vn for s_vnode;

//    function main(s_proc p_in, s_vnode[] vt_in) external pure returns (s_proc p, s_vnode[] vt) {
    function main(s_proc p_in, s_vnode[] vt_in, mapping (uint16 => Inode) inodes, mapping (uint16 => bytes) data) external pure returns (s_proc p, s_vnode[] vt) {
        p = p_in;
        vt = vt_in;
        string[] params = p.params();
        uint8 e;
        string res;
        string op;
        string ind;
        uint16 ii;
        uint len = params.length;
        uint vlen = vt.length;
        s_vnode vv;
        s_uio u;
        if (params.empty()) {
            for (s_vnode v: vt) {
                (e, res) = v.VOP_PRINT();
                p.puts(res);
            }
        } else {
            op = params[0];
            ind = len > 1 ? params[1] : "0";
            ii = ind.toi();
            if (ii < vlen)
                vv = vt[ii];
        }
//        (uint8 cn_nameiop, uint32 cn_flags, s_proc cn_proc, s_ucred cn_cred, string cn_pnbuf,
//            string cn_nameptr, uint8 cn_namelen, uint32 cn_hash) = cnp.unpack();
        s_ucred pu = p.p_ucred;
        s_of[] fdt = p.p_fd.fdt_ofiles;
        s_componentname rcn = s_componentname(nameiop.LOOKUP, 0, p, pu, "/", "/", 1, 11);
        s_vattr zero;
        s_vattr rva;
        s_vnode nv;
        s_vnode dvp;
        s_stat st;
        s_thread td;
        uint32 off;
        uint32 nlen;
        uint32 start;
        uint32 end;
        uint8 adv;
        string buf;
        uint16 buf_len;
        s_buf bp;
        uint8 waitfor;
        uint32 command;
        uint32 ddata;
        uint32 fflag;
        uint16 mode;
        uint8 name;
        uint32 retval;
        s_of fo;
        s_uio nuio;
        s_buf[] buflist;
        string fhp;

        if (op == "a") {
            for (s_vnode v: vt) {
                (e, res) = v.VOP_PRINT();
                p.puts(res);
            }
        } else if (op == "b") {
            for (s_of f: fdt) {
                nv.vget(f);
                vt.push(nv);
            }
        } else if (op == "x") {
            for ((uint16 i, Inode ino): inodes) {
                nv.vget_ino(ino, i);
//                s_buf buf;
                nv.v_data = data[i];
//                nv.VOP_BWRITE(buf);
                vt.push(nv);
            }
        }
        for (string pm: params) {
            if (pm == op || pm == ind)
                continue;
            if (op == "1")
                (e, res) = vv.VOP_READ(u, 0, pu);
            else if (op == "2")
                e = vv.VOP_WRITE(u, 0, pu);
            else if (op == "3")
                (e, nv) = vv.VOP_CREATE(rcn, zero);
            else if (op == "4")
                (e, buf, buf_len) = vv.VOP_VPTOCNP(dvp, pu);
            else if (op == "5")
                e = vv.VOP_ADVISE(start, end, adv);
            else if (op == "6")
                (e, off, nlen) = vv.VOP_ALLOCATE(off, 10);
            else if (op == "7")
                (e, rva) = vv.VOP_GETATTR(pu);
            else if (op == "8")
                e = vv.VOP_SETATTR(zero, pu);
            else if (op == "9")
                (e, st) = vv.VOP_STAT(pu, pu, td);
            else if (op == "10")
                e = vv.VOP_BWRITE(bp);
            else if (op == "11")
                e = vv.VOP_FDATASYNC(td);
            else if (op == "12")
                e = vv.VOP_INACTIVE(td);
            else if (op == "13")
                e = vv.VOP_RECLAIM(td);
            else if (op == "14")
                e = vv.VOP_FSYNC(waitfor, td);
            else if (op == "15")
                e = vv.VOP_IOCTL(command, ddata, fflag, pu, td);
            else if (op == "16")
                e = vv.VOP_LINK(dvp, rcn);
            else if (op == "17")
                (e, fo) = vv.VOP_OPEN(mode, pu, td);
            else if (op == "18")
                e = vv.VOP_CLOSE(mode, pu, td);
            else if (op == "19")
                e = vv.VOP_LOOKUP(dvp, rcn);
            else if (op == "21")
                e = vv.VOP_MKNOD(dvp, rcn, rva);
            else if (op == "22")
                e = vv.VOP_MKDIR(dvp, rcn, rva);
            else if (op == "23")
                e = vv.VOP_SYMLINK(dvp, rcn, rva, buf);
            else if (op == "24")
                e = vv.VOP_RENAME(dvp, rcn, dvp, dvp, rcn);
            else if (op == "25")
                (e, retval) = vv.VOP_PATHCONF(name);
            else if (op == "26")
                (e, buf) = vv.VOP_PRINT();
            else if (op == "27")
                (e, nuio) = vv.VOP_READDIR(u, pu);
            else if (op == "28")
                e = vv.VOP_READLINK(u, pu);
            else if (op == "29")
                e = vv.VOP_REALLOCBLKS(buflist);
            else if (op == "30")
                e = vv.VOP_REMOVE(dvp, rcn);
            else if (op == "31")
                e = vv.VOP_RMDIR(dvp, rcn);
            else if (op == "32")
                e = vv.VOP_REVOKE(mode);
            else if (op == "33")
                e = vv.VOP_STRATEGY(bp);
            else if (op == "34")
                (e, fhp) = vv.VOP_VPTOFH();
            else if (op == "35")
                e = vv.VOP_ACCESS(fflag, pu, td);

            p.puts(format("Done op: {} ec: {} ind: {}", op, e, ii));
        }
        p.puts(format("Finished. ec: {} op: {} ind: {}", e, op, ii));
        vt.push(nv);
    }
/*
	uint8 cn_nameiop;	// namei operation
	uint32 cn_flags;	// flags to namei
	s_proc cn_proc;	    // process requesting lookup
	s_ucred cn_cred;	// credentials
	string cn_pnbuf;	// pathname buffer
	string cn_nameptr;	// pointer to looked up name
	uint8 cn_namelen;	// length of looked up component
	uint32 cn_hash;	// hash value of looked up name
*/
    function _command_help() internal override pure returns (CommandHelp) {
        return CommandHelp(
"vnp",
"OPTION...",
"print vnode info",
"vnodes",
"",
"",
"Written by Boris",
"",
"",
"0.01");
    }
}