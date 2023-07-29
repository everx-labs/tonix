pragma ton-solidity >= 0.70.0;
import "common.h";

contract decode2 is common {

    function data(TvmCell c) external pure returns (Writer out) {
        out.println("Decoding data");
        TvmSlice s = c.toSlice();
        out.print(s);
        out.print(libWriter.code_hex(s));
    }

    function msgdot(TvmCell c) external pure returns (Writer out) {
        (Message m, Msg ms) = libTLBReader.parse_message(c);

        out.print(m);

        out.print("sender: ");       out.println(ms.sender);
        out.print("value: ");        out.println(ms.value);
        out.print("currencies: ");   out.println(ms.currencies);
        out.print("pubkey: ");       out.println(ms.pubkey());
        out.print("isInternal: ");   out.println(ms.isInternal);
        out.print("isExternal: ");   out.println(ms.isExternal);
        out.print("isTickTock: ");   out.println(ms.isTickTock);
        out.print("createdAt: ");    out.println(ms.createdAt);
        //out.print("data: ");//        out.println(m.data());
        out.print("hasStateInit: "); out.println(ms.hasStateInit);
    }
    function body(TvmCell c) external pure returns (Writer out) {
        (, Msg ms) = libTLBReader.parse_message(c);
        Formal fml = libFormal.with_id(ms.fid);
        if (fml.id > 0) {
            string[] values = fml.guess_params(ms.params);
            out.println("");
            out.print(fml.to_result(values));
        }
    }

    function body_debug(TvmCell c) external pure returns (Writer out) {
        (, Msg ms) = libTLBReader.parse_message(c);
        Formal fml = libFormal.with_id(ms.fid);
        if (fml.id == 0)
            out.println("No formals found");
        else {
            out.println(fml.as_signature());
            string[] values = fml.guess_params(ms.params);
            out.println("");
            out.print(fml.to_result(values));
        }
    }

    function message(TvmCell c) external pure returns (Writer out) {
        (Message m, ) = libTLBReader.parse_message(c);
        out.print(m);
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
    TvmSlice stateInit;
    TvmSlice sbody;
}

struct AbiHeader {
    optional(uint) pubkey;
    optional(uint64) time;
    optional(uint32) expireAt;
}

struct Msg {
    address sender;
    uint64 value;
    mapping (uint32 => uint) currencies;
    bool isInternal;
    bool isExternal;
    bool isTickTock;
    uint32 createdAt;
    TvmCell data;
    bool hasStateInit;
    AbiHeader header;
    uint32 fid;
    TvmSlice params;
}

using libMsg for Msg global;
library libMsg {
    function pubkey(Msg m) internal returns (uint res) {
        AbiHeader h = m.header;
        if (h.pubkey.hasValue())
            return h.pubkey.get();
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

    uint8 constant MSG_INT     = 0; // int_msg_info$0
    uint8 constant MSG_EXT_IN  = 2; // ext_in_msg_info$10
    uint8 constant MSG_EXT_OUT = 3; // ext_out_msg_info$11

    uint8 constant ANYCAST = 1;

    uint8 constant ADDR_NON = 0;
    uint8 constant ADDR_EXT = 1;
    uint8 constant ADDR_STD = 2;
    uint8 constant ADDR_VAR = 3;

    function read_value(TvmSlice s) internal returns (uint64 val) {
        uint len = s.loadUint(4);
        val = uint64(s.loadUint(uint9(len * 8)));
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
        res.anycast = s.loadUint(1) == ANYCAST;
        res.workchain_id = int8(s.loadInt(8));
        res.addr = s.loadUint(256);
    }

    function parse_extin_header(TvmSlice s) internal returns (AbiHeader h) {
        if (s.loadUint(1) > 0) {
            s.skip(512);
            if (s.bits() % 8 == 1 && s.loadUint(1) > 0)
                h.pubkey.set(s.loadUint(256));
        }
        if (s.hasNBits(64)) {
            uint tcx = s.preload(uint64) / 1000;
            if (tcx >= 1595613585 && tcx <= 1721843985) {
                h.time.set(uint64(tcx));
                s.skip(64);
                if (s.hasNBits(32)) {
                    uint32 ecx = uint32(s.preload(uint32)); // it's either expire_at or function ID
                    if (tcx < ecx && ecx - tcx < 1000) {
                        h.expireAt.set(ecx);
                        s.skip(32);
                    }
                }
            }
        }
    }

    function parse_message(TvmCell c) internal returns (Message m, Msg ms) {
        ms.data = c;
        TvmSlice s = c.toSlice();
        TvmBuilder b;
        uint t = s.loadUint(1);
        if (t > 0)
            t = 2 * t + s.loadUint(1);
        m.mtype = uint2(t);
        if (t == MSG_INT) {
            IntMsgInfo ii = s.read_IntMsgInfo();
            ms.sender = address.makeAddrStd(ii.src.workchain_id, ii.src.addr);
            ms.isInternal = true;
            ms.value = ii.value;
            ms.createdAt = ii.created_at;
            b.store(ii);
        } else {
            ms.isExternal = true;
            if (t == MSG_EXT_OUT) {
                ExtOutMsgInfo ii = s.read_ExtOutMsgInfo();
                ms.sender = address.makeAddrStd(ii.src.workchain_id, ii.src.addr);
                ms.createdAt = ii.created_at;
                b.store(ii);
            } else
                b.store(s.read_ExtInMsgInfo());
        }
        m.info = b.toSlice();
        ms.hasStateInit = s.loadUint(1) > 0;
        if (ms.hasStateInit) {
            t = s.loadUint(1);
            if (t > 0)
                s = s.loadRefAsSlice();
            StateInit sti = s.read_StateInit();
            m.stateInit = abi.encode(sti).toSlice();
        }
        if (s.loadUint(1) > 0)
            s = s.loadRefAsSlice();
        m.sbody = s;
        if (t == MSG_EXT_IN)
            ms.header = s.parse_extin_header() ;
        ms.fid = uint32(s.loadUint(32));
        ms.params = s;
    }

    function print_addr(uint n) internal returns (string) {
        return "addr_" + (n == ADDR_NON ? "none" : n == ADDR_EXT ? "extern" : n == ADDR_STD ? "std" : n == ADDR_VAR ? "var" : "???");
    }
}

struct Formal {
    uint8 mty;
    uint32 id;
    string name;
    uint8[] tys;
    string[] names;
}

using libFormal for Formal global;
library libFormal {
    uint8 constant NONE   = 0;
    uint8 constant BOOL   = 1;
    uint8 constant INT    = 2;
    uint8 constant UINT   = 3;
    uint8 constant BYTES  = 4;
    uint8 constant STRING = 5;
    uint8 constant CELL   = 6;
    uint8 constant STRUCT = 7;
    uint8 constant ARRAY  = 8;
    uint8 constant MAP    = 9;
    uint8 constant ENUM   = 10;
//    uint8 constant LAST   = ENUM;
    uint8 constant UINT8    = 11;
    uint8 constant UINT32   = 12;
    uint8 constant UINT128  = 13;
    uint8 constant ADDRESS  = 20;
    uint16[] constant TNB = [uint16(0), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 32, 128, 0, 0, 0, 0, 0, 0, 267, 0];
    uint8[] constant TNR =  [uint8(0),  0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0,  0,   0, 0, 0, 0, 0, 0, 0,   0, 0];

    function type_name(uint8 t) internal returns (string res) {
        return t == NONE ? "" : t == BOOL ? "bool" : t == STRING ? "string" : t == CELL ? "TvmCell" :
                t == UINT8 ? "uint8" : t == UINT32 ? "uint32" : t == UINT128 ? "uint128" : t == ADDRESS ? "address" : "unknown";
    }

    function type_size(uint8 t) internal returns (uint16 nb, uint8 nr) {
        return (TNB[t], TNR[t]);
    }

    function with_id(uint32 id) internal returns (Formal res) {
        for (Formal fml: KA)
            if (fml.id == id)
                return fml;
    }

    Formal[] constant KA = [
Formal(0,   85895863, "send",               [ADDRESS, UINT32], ["dest", "value"]),
Formal(2,  320701133, "submitTransaction",  [ADDRESS, UINT128, BOOL, BOOL, CELL], ["dest", "value", "bounce", "allBalance", "payload"]),
Formal(2, 1290691692, "sendTransaction",    [ADDRESS, UINT128, BOOL, UINT8, CELL],  ["dest", "value", "bounce", "flags", "payload"]),
Formal(3, 1278697887, "nFrame",             [STRING], ["label"])
    ];

    function guess_params(Formal f, TvmSlice s) internal returns (string[] values) {
        uint8[] tys = f.tys;
        uint count = tys.length;
        for (uint i = 0; i < count; i++) {
            uint8 vty = tys[i];
            (uint16 vnb, uint8 vnr) = type_size(vty);
            if (s.bits() == 0 && s.refs() > 0 && vnr == 0)
                s = s.loadRefAsSlice();
            if (s.hasNBitsAndRefs(uint10(vnb), uint2(vnr))) {
                uint nval;
                string tval;
                if (vty == ADDRESS) {
                    MsgAddressInt ai = s.read_MsgAddressInt();
                    tval = libWriter.toa(ai);
                } else if (vty == STRING) {
                    tval = s.load(string);
                } else if (vty == CELL) {
                    TvmCell c = s.load(TvmCell);
                    nval = tvm.hash(c);
                    tval = "<cell>";
                } else {
                    nval = s.loadUint(uint9(vnb));
                    tval = vty == BOOL ? (nval > 0 ? "true" : "false") : libWriter.toa(nval);
                }
                values.push(tval);
            }
        }
    }

    function to_result(Formal fml, string[] values) internal returns (string res) {
        for (uint i = 0; i < values.length; i++)
            res.append((i > 0 ? ", " : "(") + fml.names[i] + ": " + values[i]);
        res.append(")");
    }
    function as_signature(Formal n) internal returns (string res) {
        (, , string name, uint8[] tys, string[] names) = n.unpack();
        res.append(name + "(");
        for (uint i = 0; i < tys.length; i++)
            res.append(libFormal.type_name(tys[i]) + " " + names[i] + (i + 1 < tys.length ? ", " : ")"));
    }

    function toa(Formal n) internal returns (string res) {
        (uint8 mty, uint32 id, string name, , ) = n.unpack();
        res.append(format("mty: {} id: {} name: {}\n", mty, id, name));
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
        return a.cnstrctr > 0 ? ":" + toa(a.val, RADIX_HEX) : "-";
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
        (uint2 mtype, TvmSlice info, TvmSlice stateInit, ) = m.unpack();
        stateInit;
        if (mtype == libTLBReader.MSG_INT)
            res.append("Internal message " + toa(info.load(IntMsgInfo)));
        else if (mtype == libTLBReader.MSG_EXT_IN)
            res.append("External inbound message " + toa(info.load(ExtInMsgInfo)));
        else if (mtype == libTLBReader.MSG_EXT_OUT)
            res.append("External outbound message " + toa(info.load(ExtOutMsgInfo)));
    }

    function toa(Msg n) internal returns (string res) {
        (address sender, uint64 value, mapping (uint32 => uint) currencies, bool isInternal, bool isExternal, bool isTickTock, uint32 createdAt, , bool hasStateInit, AbiHeader header, uint32 fid, TvmSlice params) = n.unpack();
        res.append(format("sender: {} value: {} currencies: {} isInternal: {} isExternal: {} isTickTock: {} createdAt: {} hasStateInit: {} id: {} ",
            sender, value, toa(currencies), toa(isInternal), toa(isExternal), toa(isTickTock), createdAt, toa(hasStateInit), fid));
        res.append(toa(header));
        res.append(print_stats(params));
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

    function toa(AbiHeader ii) internal returns (string res) {
        (optional(uint) pubkey, optional(uint64) time, optional(uint32) expireAt) = ii.unpack();
        if (pubkey.hasValue())
            res.append(" Pubkey: " + toa(pubkey.get(), RADIX_HEX));
        if (time.hasValue())
            res.append(" time: " + toa(time.get()));
        if (expireAt.hasValue())
            res.append(" expires: " + toa(expireAt.get()));
    }

    function toa(TvmCell c) internal returns (string res) {
        res = print_stats(c.toSlice());
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
    function print(Writer w, Message n) internal {
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
