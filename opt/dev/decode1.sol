pragma ton-solidity >= 0.70.0;
import "common.h";

contract decode1 is common {

    function data(TvmCell c) external pure returns (Writer out) {
        out.println("Decoding data");
        TvmSlice s = c.toSlice();
        out.print(s);
        out.print(libWriter.code_hex(s));
    }

    function msgdot(TvmCell c) external pure returns (Writer out) {
        TvmSlice s = c.toSlice();
        out.print(s);
        out.println(" ");
        Message m = s.read_Message();

        out.print(libWriter.toa(m));

        out.print("sender: ");       out.println(m.sender);
        out.print("value: ");        out.println(m.value);
        out.print("currencies: ");   out.println(m.currencies());
        out.print("pubkey: ");       out.println(m.pubkey());
        out.print("isInternal: ");   out.println(m.isInternal);
        out.print("isExternal: ");   out.println(m.isExternal);
        out.print("isTickTock: ");   out.println(m.isTickTock);
        out.print("createdAt: ");    out.println(m.createdAt);
        //out.print("data: ");//        out.println(m.data());
        out.print("hasStateInit: "); out.println(m.hasStateInit);
    }
    function body(TvmCell c) external pure returns (Writer out) {
        TvmSlice s = c.toSlice();
        out.print(s);
        out.print(" ");
        Message m = s.read_Message();
        s = m.body;
        out.println("");
        out.print("Body: ");
        out.print(s);
        out.print(libWriter.code_hex(s));
        Body bb = m.read_body();
        out.println("");
        out.print(libWriter.toa(bb));
        out.println("");
        out.print("Guessing... ");
        out.print(m.guess_params());

        if (m.isInternal && !m.isTickTock) {
        } else if (m.mtype == libMessage.EXT_IN_MSG_INFO) {
            if (bb.ec > 0) {
                uint8 e = bb.ec;
                string em = e == 1 ? "Signature 1" : e == 2 ? "Signature 2" : e == 3 ? "pubkey" : e == 4 ? "fid" : e == 5 ? "mdg body header" : "unknown";
                out.println(em + " off");
            } else {
                ExtInHeader ii = m.read_header_ExtIn();
                out.println("");
                out.print(libWriter.toa(ii));
            }
        } else if (m.mtype == libMessage.EXT_OUT_MSG_INFO) {
        }
        out.print(" ");
        out.print(s);
        out.print(libWriter.code_hex(s));
        out.println("");
    }
    function message(TvmCell c) external pure returns (Writer out) {
        TvmSlice s = c.toSlice();
        out.print(s);
        out.println(" ");
        Message m = s.read_Message();
        out.print(libWriter.toa(m));

        s = m.body;
        out.println("");
        out.print("Body: ");
        Body bb = m.read_body();
        out.print(libWriter.toa(bb));

        uint cx;
        if (m.isInternal && !m.isTickTock) {
            cx = s.loadUint(32);
            out.print(" function ID: ", cx);
            if (cx == 0x051EAAB7) {
                // divination: (address, uint32)
                MsgAddressInt a = s.read_MsgAddressInt();
                out.print(" dest: ");
                out.print(a);
                cx = s.loadUint(32);
                out.print(" value: ", cx);
            }
        } else if (m.mtype == libMessage.EXT_IN_MSG_INFO) {
            ExtInHeader ii = m.read_header_ExtIn();
            out.println("");
            out.print(libWriter.toa(ii));
        } else if (m.mtype == libMessage.EXT_OUT_MSG_INFO) {
        }
        out.print(s);
        out.print(libWriter.code_hex(s));
        out.println("");
    }

    function stat(TvmCell c) external pure returns (Writer out) {
        out.println("Decoding stat");
        TvmSlice s = c.toSlice();
        out.print(s);
        out.print(libWriter.code_hex(s));
        out.psstat(s, 0, 0, 4);
    }
}
struct Message {
    uint2 mtype;
    TvmSlice info;
    bool bodyInRef;
    TvmSlice stateInit;
    TvmSlice body;
    address sender;
    bool isInternal;
    bool isExternal;
    bool isTickTock;
    uint64 value;
    uint32 createdAt;
    TvmCell mdata;
    bool hasStateInit;
}

struct ExtInHeader {
    optional(uint) pubkey;
    optional(uint64) time;
    optional(uint32) expireAt;
    uint32 fid;
}

struct Body {
    bool signed;
    bool hasPubkey;
    bool hasTime;
    bool hasExpire;
    uint32 fid;
    uint8 ec;
    TvmSlice params;
}

using libMessage for Message global;
library libMessage {

    uint8 constant INT_MSG_INFO     = 0; // int_msg_info$0
    uint8 constant EXT_IN_MSG_INFO  = 2; // ext_in_msg_info$10
    uint8 constant EXT_OUT_MSG_INFO = 3; // ext_out_msg_info$11
    uint8 constant ANYCAST = 1;

    uint8 constant ADDR_NON = 0;
    uint8 constant ADDR_EXT = 1;
    uint8 constant ADDR_STD = 2;
    uint8 constant ADDR_VAR = 3;

    function print_addr(uint n) internal returns (string) {
        return "addr_" + (n == ADDR_NON ? "none" : n == ADDR_EXT ? "extern" : n == ADDR_STD ? "std" : n == ADDR_VAR ? "var" : "???");
    }

    function guess_params(Message m) internal returns (string res) {
        Body bb = m.read_body();
        TvmSlice s = bb.params;
        (uint16 nbits, uint8 nrefs) = s.size();
        if (nbits + nrefs == 0)
            return "Empty";
        res.append(libWriter.print_stats(s));
        res.append(libWriter.code_hex(s));
        TvmSlice s1;
        if (nrefs > 0)
            s1 = s.preloadSlice(0, 1);
        (uint16 nbits1, ) = s1.size();
        if (nbits == 0) {
            if (nbits1 % 8 == 0) {
                string s0 = s.load(string);
                bytes bbb = bytes(s0);
                uint8 bab;
                for (bytes1 b: bbb) {
                    uint8 ub = uint8(b);
                    if (ub < 0x20 || ub > 0x7F) {
                        bab = ub;
                        break;
                    }
                }
                if (bab == 0)
                    res.append(" String??? " + s0);
                else
                    res.append(" bab " + libWriter.toa(bab));
            } else {
                s = s.loadRefAsSlice();
                (nbits, nrefs) = s.size();
            }
        }
        if (nbits == 397) {
            (address dest, uint128 value, bool bounce, bool allBalance, TvmCell payload) = s.load(address, uint128, bool, bool, TvmCell);
            res.append(format("dest: {} value: {} bounce: {} all balance: {} ", dest, value, libWriter.toa(bounce), libWriter.toa(allBalance)));
            payload;
        } else if (nbits == 404) {
            (address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) = s.load(address, uint128, bool, uint8, TvmCell);
            res.append(format("dest: {} value: {} bounce: {} flags: {} ", dest, value, libWriter.toa(bounce), flags));
            payload;
        } else if (nbits == 299) {
            (address dest, uint32 val) = s.load(address, uint32);
            res.append(format("dest: {} value: {}", dest, val));
        }
        res.append(libWriter.print_stats(s));
        res.append(libWriter.code_hex(s));
    }

    function currencies(Message m) internal returns (ExtraCurrencyCollection res) {
        if (m.mtype == INT_MSG_INFO) {
            IntMsgInfo ii = m.info.load(IntMsgInfo);
            for ((uint32 id, uint val): ii.other_currencies)
                res[id] = val;
        }
    }
    function pubkey(Message m) internal returns (uint res) {
        if (m.mtype == EXT_IN_MSG_INFO) {
            ExtInHeader h = m.read_header_ExtIn();
            if (h.pubkey.hasValue())
                return h.pubkey.get();
        }
    }

    function read_body(Message m) internal returns (Body res) {
        TvmSlice s = m.body;
        uint t = m.mtype;
        if (t == INT_MSG_INFO && !m.isTickTock)
            return s.read_Body_Int();
        else if (t == EXT_IN_MSG_INFO)
            return s.read_Body_ExtIn();
        else if (t == EXT_OUT_MSG_INFO)
            return s.read_Body_ExtOut();
    }
    function read_header_ExtIn(Message m) internal returns (ExtInHeader res) {
        TvmSlice s = m.body;
        Body bb = m.body.read_Body_ExtIn();
        s.skip(1);
        if (bb.signed) {
            s.skip(512);
            if (bb.hasPubkey && s.bits() > 256) {
                s.skip(1);
                res.pubkey.set(s.loadUint(256));
            }
        }
        if (bb.hasTime && s.bits() >= 64)
            res.time.set(uint64(s.loadUint(64)));
        if (bb.hasExpire && s.bits() >= 32)
            res.expireAt.set(uint32(s.loadUint(32)));
        uint vfid = s.bits() >= 32 ? s.loadUint(32) : 0;
        if (vfid == bb.fid)
            res.fid = uint32(vfid);
    }
}
struct MsgAddressExt {
    uint2 cnstrctr;
    uint8 len;
    uint val;
}

struct MsgAddressInt {
    uint2 cnstrctr;
    bool anycast;
    int8 workchain_id;
    uint addr;
}

struct IntMsgInfo {
    bool ihr_disabled;
    bool bounce;
    bool bounced;
    MsgAddressInt src;
    MsgAddressInt dest;
    uint64 value;
    mapping (uint32 => uint) other_currencies;
    uint64 ihr_fee;
    uint64 fwd_fee;
    uint64 created_lt;
    uint32 created_at;
}

struct ExtInMsgInfo {
    MsgAddressExt src;
    MsgAddressInt dest;
    uint64 import_fee;
}

struct ExtOutMsgInfo {
    MsgAddressInt src;
    MsgAddressExt dest;
    uint64 created_lt;
    uint32 created_at;
}
struct StateInit {
    optional(uint5) depth;
    optional(uint2) special;
    optional(TvmCell) code;
    optional(TvmCell) data;
    optional(TvmCell) lib;
}

using libTLBReader for TvmSlice;
library libTLBReader {

    function read_value(TvmSlice s) internal returns (uint64 val) {
        uint len = s.loadUint(4);
        val = uint64(s.loadUint(uint9(len * 8)));
    }

    function read_Body_Int(TvmSlice s) internal returns (Body res) {
        res.fid = uint32(s.loadUint(32));
        res.params = s;
    }
    function read_Body_ExtOut(TvmSlice s) internal returns (Body res) {
        (uint16 nbits, ) = s.size();
        if (nbits >= 32) {
            res.fid = uint32(s.loadUint(32));
            nbits -= 32;
        } else
            res.ec = 1;
        res.params = s;
    }

    function read_Body_ExtIn(TvmSlice s) internal returns (Body res) {
        (uint16 nbits, ) = s.size();
        uint cx = s.loadUint(1);
        nbits--;
        res.signed = cx > 0;
        if (cx == 1) {
            if (nbits > 512) {
                s.skip(256);
                s.skip(256);
                nbits -= 512;
            } else
                res.ec = 1;
            if (nbits % 8 == 1) {
                res.hasPubkey = true;
                nbits--;
                if (s.loadUint(1) > 0) {
                    if (nbits > 256) {
                        s.skip(256);
                        nbits -= 256;
                    } else
                        res.ec = 3;
                }
            }
        }
        uint tcx;
        if (nbits >= 64) {
            tcx = s.preload(uint64) / 1000;
            if (tcx >= 1595613585 && tcx <= 1721843985)
                res.hasTime = true;
        }
        if (res.hasTime) {
            tcx = s.loadUint(64) / 1000;
            nbits -= 64;
            if (nbits >= 32) {
                uint ecx = s.preload(uint32); // it's either expire_at or function ID
                if (tcx < ecx && ecx - tcx < 1000)
                    res.hasExpire = true;
            }
        }
        if (res.hasExpire) {
            s.skip(32);
            nbits -= 32;
        }
        if (nbits >= 32) {
            nbits -= 32;
            res.fid = uint32(s.loadUint(32));
        } else
            res.ec = 4;
        res.params = s;
    }
    function read_Message(TvmSlice s) internal returns (Message res) {
        TvmBuilder b;
        b.store(s);
        res.mdata = b.toCell();
        delete b;
        uint t = s.loadUint(1);
        if (t > 0)
            t = 2 * t + s.loadUint(1);
        res.mtype = uint2(t);
        if (t == libMessage.INT_MSG_INFO) {
            IntMsgInfo ii = s.read_IntMsgInfo();
            res.sender = address.makeAddrStd(ii.src.workchain_id, ii.src.addr);
            res.isInternal = true;
            res.value = ii.value;
            res.createdAt = ii.created_at;
            b.store(ii);
        } else if (t == libMessage.EXT_IN_MSG_INFO) {
            b.store(s.read_ExtInMsgInfo());
            res.isExternal = true;
        } else if (t == libMessage.EXT_OUT_MSG_INFO) {
            ExtOutMsgInfo ii = s.read_ExtOutMsgInfo();
            b.store(ii);
            res.isExternal = true;
            res.createdAt = ii.created_at;
        }
        res.info = b.toSlice();
        res.hasStateInit = s.loadUint(1) > 0;
        if (res.hasStateInit) {
            t = s.loadUint(1);
            if (t > 0) {
                s = s.loadRefAsSlice();
            }
            StateInit sti = s.read_StateInit();
            res.stateInit = abi.encode(sti).toSlice();
        }
        res.bodyInRef = s.loadUint(1) > 0;
        res.body = res.bodyInRef ? s.loadRefAsSlice() : s;
    }
    function read_StateInit(TvmSlice s) internal returns (StateInit res) {
        bool f = s.loadUint(1) > 0;
        if (f)
            res.depth.set(uint5(s.loadUint(5)));
        f = s.loadUint(1) > 0;
        if (f)
            res.special.set(uint2(s.loadUint(2)));
        f = s.loadUint(1) > 0;
        if (f)
            res.code.set(s.loadRef());
        f = s.loadUint(1) > 0;
        if (f)
            res.data.set(s.loadRef());
        f = s.loadUint(1) > 0;
        if (f)
            res.lib.set(s.loadRef());
    }
    function read_ExtInMsgInfo(TvmSlice s) internal returns (ExtInMsgInfo res) {
        res.src = s.read_MsgAddressExt();
        res.dest = s.read_MsgAddressInt();
        res.import_fee = s.read_value();
    }
    function read_ExtOutMsgInfo(TvmSlice s) internal returns (ExtOutMsgInfo res) {
        res.src = s.read_MsgAddressInt();
        res.dest = s.read_MsgAddressExt();
        res.created_lt = uint64(s.loadUint(64));
        res.created_at = uint32(s.loadUint(32));
    }
    function read_IntMsgInfo(TvmSlice s) internal returns (IntMsgInfo res) {
        res.ihr_disabled = s.loadUint(1) > 0;
        res.bounce = s.loadUint(1) > 0;
        res.bounced = s.loadUint(1) > 0;
        res.src = s.read_MsgAddressInt();
        res.dest = s.read_MsgAddressInt();
        res.value = s.read_value();
        while (s.loadUint(1) > 0) {
            uint cur_id = s.loadUint(32);
            uint cur_val_len = s.loadUint(32);
            res.other_currencies[uint32(cur_id)] = s.loadUint(uint9(cur_val_len * 8));
        }
        res.ihr_fee = s.read_value();
        res.fwd_fee = s.read_value();
        res.created_lt = uint64(s.loadUint(64));
        res.created_at = uint32(s.loadUint(32));
    }

    function read_MsgAddressExt(TvmSlice s) internal returns (MsgAddressExt res) {
        res.cnstrctr = uint2(s.loadUint(2));
        if (res.cnstrctr > 0) {
            res.len = uint8(s.loadUint(3));
            res.val = uint64(s.loadUint(uint9(res.len * 8)));
        }
    }
    function read_MsgAddressInt(TvmSlice s) internal returns (MsgAddressInt res) {
        res.cnstrctr = uint2(s.loadUint(2));
        res.anycast = s.loadUint(1) == libMessage.ANYCAST;
        res.workchain_id = int8(s.loadInt(8));
        res.addr = s.loadUint(256);
    }
}

struct Writer {
    string buf;
}
using libWriter for Writer global;
library libWriter {
    uint8 constant COUNT_NON = 0;
    uint8 constant COUNT_CUR = 1;
    uint8 constant COUNT_TOT = 2;
    uint8 constant COUNT_FUL = 3;
    uint8 constant RADIX_NON = 0;
    uint8 constant RADIX_BIN = 1;
    uint8 constant RADIX_OCT = 2;
    uint8 constant RADIX_DEC = 3;
    uint8 constant RADIX_HEX = 4;
    function toa(uint n) internal returns (string) {
        return format("{}", n);
    }
    function toa(int n) internal returns (string) {
        return format("{}", n);
    }
    function toa(bool n) internal returns (string) {
        return n ? "Yes" : "No";
    }
    function toa(uint n, uint8 radix) internal returns (string res) {
        uint rem;
        if (radix == RADIX_DEC)
            return toa(n);
        else if (radix == RADIX_HEX)
            return format("{:x}", n);
        else if (radix == RADIX_BIN) {
            while (n > 0) {
                (n, rem) = math.divmod(n, 2);
                res = (rem == 0 ? "0" : "1") + res;
            }
        } else if (radix == RADIX_OCT) {
            while (n > 0) {
                (n, rem) = math.divmod(n, 8);
                res = toa(rem) + res;
            }
        }
    }
    function toa(MsgAddressExt a) internal returns (string res) {
        return a.cnstrctr > 0 ? ":" + toa(a.val, RADIX_HEX) : " - ";
    }
    function toa(MsgAddressInt a) internal returns (string res) {
        return toa(a.workchain_id) + ":" + toa(a.addr, RADIX_HEX);
    }
    function toa(address a) internal returns (string res) {
        return toa(a.wid) + ":" + toa(a.value, RADIX_HEX);
    }
    function toa(IntMsgInfo ii) internal returns (string res) {
        (bool ihr_disabled, bool bounce, bool bounced, MsgAddressInt src, MsgAddressInt dest, uint64 value, , uint64 ihr_fee, uint64 fwd_fee, uint64 created_lt, uint32 created_at) = ii.unpack();
        res = format("ihr_disabled: {} bounce: {} bounced: {} src: {} dest: {} value: {} ihr_fee: {} fwd_fee: {} created_lt: {} created_at: {} ",
            toa(ihr_disabled), toa(bounce), toa(bounced), toa(src), toa(dest), value, ihr_fee, fwd_fee, created_lt, created_at);
    }
    function toa(ExtInMsgInfo ii) internal returns (string res) {
        (MsgAddressExt src, MsgAddressInt dest, uint64 import_fee) = ii.unpack();
        res = format("src: {} dest: {} import_fee: {} ", toa(src), toa(dest), import_fee);
    }
    function toa(ExtOutMsgInfo ii) internal returns (string res) {
        (MsgAddressInt src, MsgAddressExt dest, uint64 created_lt, uint32 created_at) = ii.unpack();
        res = format("src: {} dest: {} created_lt: {} created_at: {} ", toa(src), toa(dest), created_lt, created_at);
    }
    function toa(Message m) internal returns (string res) {
        (uint2 mtype, TvmSlice info, bool bodyInRef, TvmSlice stateInit, TvmSlice body, address sender, bool isInternal, bool isExternal, bool isTickTock, uint64 value, uint32 createdAt, , bool hasStateInit) = m.unpack();
        if (mtype == libMessage.INT_MSG_INFO)
            res.append("Internal message " + toa(info.load(IntMsgInfo)));
        else if (mtype == libMessage.EXT_IN_MSG_INFO)
            res.append("External inbound message " + toa(info.load(ExtInMsgInfo)));
        else if (mtype == libMessage.EXT_OUT_MSG_INFO)
            res.append("External outbound message " + toa(info.load(ExtOutMsgInfo)));
        res.append(format(" init: {} body: {} sender: {} isInternal: {} isExternal: {} isTickTock: {} value: {} created_at: {} ", toa(hasStateInit), toa(bodyInRef), sender,
            toa(isInternal), toa(isExternal), toa(isTickTock), value, createdAt));
        if (hasStateInit) {
            res.append(print_stats(stateInit) + " ");
            res.append(toa(stateInit.load(StateInit)));
        }
        res.append("Body: " + print_stats(body) + " ");
    }
    function toa(mapping (uint32 => uint) n) internal returns (string res) {
        for ((uint32 k, uint v): n)
            res.append(" [" + toa(k) + "] => " + toa(v));
    }

    function toa(StateInit ii) internal returns (string res) {
        (optional(uint5) depth, optional(uint2) special, optional(TvmCell) code, optional(TvmCell) data, optional(TvmCell) lib) = ii.unpack();
        res.append(format("depth: {} special: {} code: {} data: {} lib: {} ",
            toa(depth.hasValue()), toa(special.hasValue()), toa(code.hasValue()), toa(data.hasValue()), toa(lib.hasValue())));
    }

    function toa(Body n) internal returns (string res) {
        (bool signed, bool hasPubkey, bool hasTime, bool hasExpire, uint32 fid, uint8 ec, TvmSlice params) = n.unpack();
        if (ec > 0) res.append(format("!!! Error {}\n", ec));
        if (signed) res.append("[Signed] ");
        if (hasPubkey) res.append("[Key] ");
        if (hasTime) res.append("[Time] ");
        if (hasExpire) res.append("[Expire] ");
        res.append(format(" ID {} (0x{:x}) ", fid, fid));
        res.append("params: " + print_stats(params) + " ");
    }

    function toa(ExtInHeader ii) internal returns (string res) {
        (optional(uint) pubkey, optional(uint64) time, optional(uint32) expireAt, uint32 fid) = ii.unpack();
        if (pubkey.hasValue())
            res.append(" Pubkey: " + toa(pubkey.get(), RADIX_HEX));
        if (time.hasValue())
            res.append(" time: " + toa(time.get()));
        if (expireAt.hasValue())
            res.append(" expires: " + toa(expireAt.get()));
        res.append(" Function ID: " + toa(fid, RADIX_HEX));
    }

    function print(Writer w, string s) internal {
        w.buf.append(s);
    }
    function prepend(Writer w, string s) internal {
        w.buf = s + w.buf;
    }
    function println(Writer w, string s) internal {
        w.print(s + "\n");
    }
    function print(Writer w, uint n) internal {
        w.print(toa(n));
    }
    function print(Writer w, int n) internal {
        w.print(toa(n));
    }
    function println(Writer w, uint n) internal {
        w.println(toa(n));
    }
    function println(Writer w, int n) internal {
        w.println(toa(n));
    }

    function print(Writer w, mapping (uint32 => uint) n) internal {
        w.print(toa(n));
    }
    function println(Writer w, mapping (uint32 => uint) n) internal {
        w.println(toa(n));
    }
    function println(Writer w, ExtraCurrencyCollection n) internal {
        n;
        w.print("");
//        w.print(toa(n));
    }
    function print(Writer w, bool n) internal {
        w.print(toa(n));
    }
    function print(Writer w, address n) internal {
        w.print(toa(n));
    }
    function print(Writer w, MsgAddressInt n) internal {
        w.print(toa(n));
    }
    function print(Writer w, IntMsgInfo n) internal {
        w.print(toa(n));
    }
    function print(Writer w, ExtInMsgInfo n) internal {
        w.print(toa(n));
    }
    function print(Writer w, ExtOutMsgInfo n) internal {
        w.print(toa(n));
    }
    function print(Writer w, string s, uint n) internal {
        w.print(s);
        w.print(n);
    }
    function println(Writer w, bool n) internal {
        w.println(toa(n));
    }
    function println(Writer w, address n) internal {
        w.println(toa(n));
    }
    function println(Writer w, MsgAddressInt n) internal {
        w.println(toa(n));
    }
    function println(Writer w, IntMsgInfo n) internal {
        w.println(toa(n));
    }
    function println(Writer w, ExtInMsgInfo n) internal {
        w.println(toa(n));
    }
    function println(Writer w, ExtOutMsgInfo n) internal {
        w.println(toa(n));
    }
    function println(Writer w, string s, uint n) internal {
        w.print(s);
        w.println(n);
    }
    function print_count(Writer w, string sym, uint val, uint cur, uint total) internal {
        if (val != COUNT_NON) {
            w.print(sym);
            if (val == COUNT_CUR)
                w.print(cur);
            else if (val == COUNT_TOT)
                w.print(total);
            else if (val == COUNT_FUL) {
                w.print(cur);
                w.print("/", total);
            } else
                w.print("undefined");
        }
    }
    function print_count(Writer w, string sym, uint val, uint cur) internal {
        if (val >= COUNT_CUR && val <= COUNT_FUL)
            w.print(sym, cur);
    }
    function print(Writer w, TvmSlice s) internal {
        w.print(print_stats(s));
    }

    function print_stats(TvmSlice s) internal returns (string res) {
        (uint ncells, uint bit_size, uint total_refs) = s.dataSize(20000);
        if (ncells + bit_size + total_refs == 0)
            return " Empty";
        else {
            Writer w;
            (uint16 nbits, uint8 nrefs) = s.size();
            uint depth = s.depth();
            w.print_count("\u20B5", COUNT_FUL, ncells);
            w.print_count(" ", COUNT_FUL, nbits, bit_size);
            if (ncells > 1) {
                w.print_count(" \u250B", COUNT_FUL, depth);
                w.print_count(" >", COUNT_FUL, nrefs, total_refs);
            }
            return w.buf;
        }
    }

    function code_hex(TvmSlice s) internal returns (string out) {
        uint rb = s.bits();
        while (rb > 256) {
            out.append(format(" [{:X}]", s.loadUint(256)));
            rb -= 256;
        }
        if (rb > 0)
            out.append(format(" [{:X}] ", s.loadUint(uint9(rb))));
    }
    function psstat(Writer w, TvmSlice s, uint level, uint mask, uint max_depth) internal {
        w.print(s);
        if (max_depth <= level)
            return;
        uint nrefs = s.refs();
        mask |= 1 << level;
        string prefix;
        if (nrefs > 1) {
            prefix.append("\n");
            for (uint j = 0; j < level; j++)
                prefix.append((mask & 1 << j) == 0 ? " " : "\u2503");
        }
        for (uint i = 0; i < nrefs; i++) {
            if (nrefs > 1)
                w.print(prefix);
            if (i + 1 < nrefs)
                w.print("\u2523");
            else {
                w.print("\u2517");
                mask &= ~(1 << level);
            }
            w.psstat(s.loadRefAsSlice(), level + 1, mask, max_depth);
        }
    }
}
