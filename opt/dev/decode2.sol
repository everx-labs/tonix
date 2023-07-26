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
        Message m;
        m.msg.data = c;
        m.read();

        out.print(libWriter.toa(m));

        out.print("sender: ");       out.println(m.msg.sender);
        out.print("value: ");        out.println(m.msg.value);
        out.print("currencies: ");   out.println(m.msg.currencies);
        out.print("pubkey: ");       out.println(m.pubkey());
        out.print("isInternal: ");   out.println(m.msg.isInternal);
        out.print("isExternal: ");   out.println(m.msg.isExternal);
        out.print("isTickTock: ");   out.println(m.msg.isTickTock);
        out.print("createdAt: ");    out.println(m.msg.createdAt);
        //out.print("data: ");//        out.println(m.data());
        out.print("hasStateInit: "); out.println(m.msg.hasStateInit);
    }
    function body(TvmCell c) external pure returns (Writer out) {
        Message m;
        m.msg.data = c;
        m.read();
//        m.body.args.alloc_params();
        m.body.args.guess_params();
        out.print(libWriter.toa(m.body.args.actual));
    }

    function body_debug(TvmCell c) external pure returns (Writer out) {
        Message m;
        m.msg.data = c;
        m.read();
        out.print(libWriter.toa(m));
        Arguments args = m.body.args;
//        out.println(args.alloc_params());
        out.println("Guessing... ");
        out.println(args.guess_params());
        m.body.args = args;
        out.print(libWriter.toa(m.body.args.actual));
    }

    function message(TvmCell c) external pure returns (Writer out) {
        Message m;
        m.msg.data = c;
        m.read();
        out.print(libWriter.toa(m));
        if (m.msg.isInternal && !m.msg.isTickTock) {
        } else if (m.mtype == libMessage.EXT_IN_MSG_INFO) {
//            AbiHeader ii = m.body.header;
//            out.println("");
//            out.print(libWriter.toa(ii));
        } else if (m.mtype == libMessage.EXT_OUT_MSG_INFO) {
        }
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
struct Msg {
    address sender;
    uint64 value;
    mapping (uint32 => uint) currencies;
    uint pubkey;
    bool isInternal;
    bool isExternal;
    bool isTickTock;
    uint32 createdAt;
    TvmCell data;
    bool hasStateInit;
}
struct Message {
    uint2 mtype;
    TvmSlice info;
    TvmSlice stateInit;
    TvmSlice sbody;
    Msg msg;
    Body body;
}

struct AbiHeader {
    optional(uint) pubkey;
    optional(uint64) time;
    optional(uint32) expireAt;
}

struct Param {
    uint8 state;
    uint16 nb;
    uint8 nr;
    uint8 ty;
    string name;
    uint nval;
    string tval;
}

struct Formal {
    uint32 id;
    uint8 count;
    uint16 nb;
    uint8 nr;
    string name;
    uint8[] tys;
    string[] names;
}

struct Arguments {
    uint8 state;
    uint16 nb;
    uint8 nr;
    uint8 count;
    TvmSlice space;
    mapping (uint8 => Param) actual;
}

using libArguments for Arguments global;
library libArguments {

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

    function type_name(uint8 t) internal returns (string res) {
        return t == NONE ? "" : t == BOOL ? "bool" : t == STRING ? "string" : t == CELL ? "TvmCell" :
                t == UINT8 ? "uint8" : t == UINT32 ? "uint32" : t == UINT128 ? "uint128" : t == ADDRESS ? "address" : "unknown";
    }

    function min(Arguments a) internal {
        uint8 res;
        for ((, Param p): a.actual) {
            if (res == 0)
                res = p.state;
            else if (res < p.state)
                res = p.state;
        }
        a.state = res;
    }

    uint16[] constant TNB = [uint16(0), 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 32, 128, 0, 0, 0, 0, 0, 0, 267, 0];
    uint8[] constant TNR =  [uint8(0),  0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0,  0,   0, 0, 0, 0, 0, 0, 0,   0, 0];
    function type_size(uint8 t) internal returns (uint16 nb, uint8 nr) {
        return (TNB[t], TNR[t]);
    }

    function with_space(TvmSlice s) internal returns (Arguments res) {
        (, uint anb, uint anr) = s.dataSize(2000);
        mapping (uint8 => Param) actual;
        for (Formal fml: KA) {
            (uint32 id, uint8 count, uint16 nb, uint8 nr, string name, uint8[] tys, string[] names) = fml.unpack();
            if (anb == nb && anr == nr) {
                actual[0] = Param(2, 0, 0, STRING, id >> 31 > 0 ? "call" : "event", id, name);
                for (uint j = 0; j < count; j++)
                    actual[uint8(j) + 1] = Param(1, nb, nr, tys[j], names[j], 0, "");
                return Arguments(2, nb, nr, count, s, actual);
            }
        }
    }

    Formal[] constant KA = [
Formal(  85895863, 2, 299, 0, "send",               [ADDRESS, UINT32], ["dest", "value"]),
Formal( 320701133, 5, 397, 2, "submitTransaction",  [ADDRESS, UINT128, BOOL, BOOL, CELL], ["dest", "value", "bounce", "allBalance", "payload"]),
Formal( 320701133, 5, 404, 2, "sendTransaction",    [ADDRESS, UINT128, BOOL, UINT8, CELL],  ["dest", "value", "bounce", "flags", "payload"]),
Formal(1278697887, 1,  80, 1, "nFrame",             [STRING], ["label"])
    ];

    function guess_params(Arguments a) internal returns (string res) {
        TvmSlice s = a.space;
        if (s.empty())
            return "Success";
        for ((uint8 k, Param v): a.actual) {
            if (k == 0)
                continue;
//            res.append("Trying " + libWriter.toa(v) + "... ");
            (, uint16 vnb, uint8 vnr, uint8 vty, , , ) = v.unpack();
            if (s.bits() == 0 && s.refs() > 0 && vnr == 0)
                s = s.loadRefAsSlice();

            if (s.hasNBitsAndRefs(uint10(vnb), uint2(vnr))) {
                uint nval;
                string tval;
                if (vty == ADDRESS) {
                    MsgAddressInt ai = s.read_MsgAddressInt();
                    nval = ai.addr;
                    tval = libWriter.toa(ai.workchain_id) + ":" + libWriter.toa(nval, libWriter.RADIX_HEX);
                } else if (vty == STRING) {
                    tval = s.load(string);
                } else if (vty == CELL) {
                    TvmCell c = s.load(TvmCell);
                    nval = tvm.hash(c);
                    //tval = "0x" + libWriter.toa(nval, libWriter.RADIX_HEX);
                    optional(string) stv = c.toSlice().loadQ(string);
                    tval = stv.hasValue() ? stv.get() : "<cell>";
                } else {
                    uint cap = vnb > 256 ? 256 : vnb;
                    nval = s.loadUint(uint9(cap));
                    tval = vty == BOOL ? (nval > 0 ? "true" : "false") : libWriter.toa(nval);
                }
                a.actual[k].nval = nval;
                a.actual[k].tval = tval;
                a.actual[k].state++;
//                a.fillArg(k, nval, tval);
//                res.append(format("Arg #{}: {} {}\n", k, nval, tval));
            } else
                res.append(format("Failed to read argument #{}: need {}/{}, got {}/{}\n", k, vnb, vnr, s.bits(), s.refs()));
        }
    }
}
struct Body {
    bool signed;
    bool hasPubkey;
    bool hasTime;
    bool hasExpire;
    uint32 fid;
    uint8 ec;
    TvmSlice params;
    AbiHeader header;
    Arguments args;
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

    function read(Message m) internal {
        TvmBuilder b;
        TvmSlice s = m.msg.data.toSlice();
        uint t = s.loadUint(1);
        if (t > 0)
            t = 2 * t + s.loadUint(1);
        m.mtype = uint2(t);
        if (t == libMessage.INT_MSG_INFO) {
            IntMsgInfo ii = s.read_IntMsgInfo();
            m.msg.sender = address.makeAddrStd(ii.src.workchain_id, ii.src.addr);
            m.msg.isInternal = true;
            m.msg.value = ii.value;
            m.msg.createdAt = ii.created_at;
            b.store(ii);
        } else if (t == libMessage.EXT_IN_MSG_INFO) {
            b.store(s.read_ExtInMsgInfo());
            m.msg.isExternal = true;
        } else if (t == libMessage.EXT_OUT_MSG_INFO) {
            ExtOutMsgInfo ii = s.read_ExtOutMsgInfo();
            b.store(ii);
            m.msg.isExternal = true;
            m.msg.createdAt = ii.created_at;
        }
        m.info = b.toSlice();
        m.msg.hasStateInit = s.loadUint(1) > 0;
        if (m.msg.hasStateInit) {
            t = s.loadUint(1);
            if (t > 0)
                s = s.loadRefAsSlice();
            StateInit sti = s.read_StateInit();
            m.stateInit = abi.encode(sti).toSlice();
        }
        bool bodyInRef = s.loadUint(1) > 0;
        m.sbody = bodyInRef ? s.loadRefAsSlice() : s;
        s = m.sbody;
        Body bres;
        (uint16 nbits, ) = s.size();
        if (t == INT_MSG_INFO && !m.msg.isTickTock) {
            bres.fid = uint32(s.loadUint(32));
        } else if (t == EXT_IN_MSG_INFO) {
            bres = s.read_Body_ExtIn();
        } else if (t == EXT_OUT_MSG_INFO) {
            if (nbits >= 32) {
                bres.fid = uint32(s.loadUint(32));
                nbits -= 32;
            } else
                bres.ec = 1;
        }
        AbiHeader hres;

        s = m.sbody;
        if (t == libMessage.EXT_IN_MSG_INFO)
            s.skip(1);
        if (bres.signed) {
            s.skip(512);
            if (bres.hasPubkey && s.bits() > 256) {
                s.skip(1);
                hres.pubkey.set(s.loadUint(256));
            }
        }
        if (bres.hasTime && s.bits() >= 64)
            hres.time.set(uint64(s.loadUint(64)));
        if (bres.hasExpire && s.bits() >= 32)
            hres.expireAt.set(uint32(s.loadUint(32)));
        s.loadUint(32);

        bres.params = s;
        bres.header = hres;
        //bres.args.space = s;
        bres.args = libArguments.with_space(s);
        //bres.args.alloc_params();

        m.body = bres;
    }

    function print_addr(uint n) internal returns (string) {
        return "addr_" + (n == ADDR_NON ? "none" : n == ADDR_EXT ? "extern" : n == ADDR_STD ? "std" : n == ADDR_VAR ? "var" : "???");
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
            AbiHeader h = m.body.header;
            if (h.pubkey.hasValue())
                return h.pubkey.get();
        }
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

    function read_Body_ExtIn(TvmSlice s) internal returns (Body res) {
        (uint16 nbits, ) = s.size();
        uint cx = s.loadUint(1);
        nbits--;
        res.signed = cx > 0;
        if (cx == 1) {
            if (nbits > 512) {
                s.skip(512);
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
        (uint2 mtype, TvmSlice info, TvmSlice stateInit, TvmSlice sbody, Msg mesg, Body body) = m.unpack();
        stateInit;
        res.append(toa(mesg.data) + " ");
        if (mtype == libMessage.INT_MSG_INFO)
            res.append("Internal message " + toa(info.load(IntMsgInfo)));
        else if (mtype == libMessage.EXT_IN_MSG_INFO)
            res.append("External inbound message " + toa(info.load(ExtInMsgInfo)));
        else if (mtype == libMessage.EXT_OUT_MSG_INFO)
            res.append("External outbound message " + toa(info.load(ExtOutMsgInfo)));
        res.append(toa(mesg));
        res.append("\n" + print_stats(sbody) + " body ");
        res.append(toa(body));
    }

    function toa(Msg n) internal returns (string res) {
        (address sender, uint64 value, mapping (uint32 => uint) currencies, uint pubkey, bool isInternal, bool isExternal, bool isTickTock, uint32 createdAt, , bool hasStateInit) = n.unpack();
        res.append(format("sender: {} value: {} currencies: {} pubkey: {} isInternal: {} isExternal: {} isTickTock: {} createdAt: {} hasStateInit: {} ",
            sender, value, toa(currencies), pubkey, toa(isInternal), toa(isExternal), toa(isTickTock), createdAt, toa(hasStateInit)));
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
        (bool signed, bool hasPubkey, bool hasTime, bool hasExpire, uint32 fid, uint8 ec, TvmSlice params, AbiHeader header, Arguments args) = n.unpack();
        if (ec > 0) res.append(format("!!! Error {}\n", ec));
        if (signed) res.append("[Signed] ");
        if (hasPubkey) res.append("[Key] ");
        if (hasTime) res.append("[Time] ");
        if (hasExpire) res.append("[Expire] ");
        res.append(format(" ID {} (0x{:x}) ", fid, fid));
        res.append("params: " + print_stats(params) + " ");
        res.append("abi header: " + toa(header) + " ");
        res.append("args: " + toa(args) + " ");
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

    function toa(Param n) internal returns (string res) {
        (uint8 state, uint16 nb, uint8 nr, uint8 ty, string name, uint nval, string tval) = n.unpack();
        if (state >= 2)
//            res.append(type_name(ty) + " " + name + ": " + tval);
            res.append(name + ": " + tval);
        else if (state >= 1)
            res.append(libArguments.type_name(ty) + " " + name);
        else
            res.append(format("state: {} nb: {} nr: {} ty: {} name: {} nval: {} tval: {} ", state, nb, nr, ty, name, nval, tval));
    }

    function toa(mapping (uint8 => Param) n) internal returns (string res) {
        for ((uint8 k, Param v): n)
            res.append((k > 1 ? ", " : "") + toa(v) + (k == 0 ? "(" : ""));
        res.append(res.empty() ? "(?" : "");
        return res + ")";
    }

    function toa(Arguments n) internal returns (string res) {
        (uint8 state, uint16 nb, uint8 nr, uint8 count, TvmSlice space, mapping (uint8 => Param) actual) = n.unpack();
        res.append(format("state: {} nb: {} nr: {} count: {} ", state, nb, nr, count));
        res.append(" Space: " + print_stats(space));
        res.append(" Actual arguments: " + toa(actual));
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


//    function fillArg(Arguments a, uint8 n, uint nval, string tval) internal {
//        a.actual[n].nval = nval;
//        a.actual[n].tval = tval;
//        a.actual[n].state++;
//    }
//    function withArgs(Arguments a, uint8[] tys, string[] names) internal {
//        uint8 len = uint8(tys.length);
//        uint16 tnb;
//        uint8 tnr;
//        a.actual[0] = Param(2, 0, 0, STRING, "call", 0, names[0]);
//        for (uint i = 0; i < len; i++) {
//            uint8 ty = tys[i];
//            (uint16 nb, uint8 nr) = type_size(ty);
//            tnb += nb;
//            tnr += nr;
//            a.actual[uint8(i) + 1] = Param(1, nb, nr, ty, names[i + 1], 0, "");
//        }
//        a.count += len;
//    }
//    function alloc_params(Arguments a) internal returns (string res) {
//        (, uint anb, uint anr) = a.space.dataSize(2000);
//        a.nb = uint16(anb);
//        a.nr = uint8(anr);
//
//        for (uint i = 0; i < 5; i++) {
//            if (anb == KNB[i] && anr == KNR[i]) {
//                res.append("Found at " + libWriter.toa(i) + " ");
//                a.withArgs(AT[i], AN[i]);
//            }
//        }
//        a.min();
//        res.append("Allocated " + libWriter.toa(a));
//    }
//    uint16[] constant KNB = [0, 299, 397, 404, 80];
//    uint8[] constant  KNR = [0,   0,   2,   2,  1];
//    uint8[][] constant AT = [[NONE], [ADDRESS, UINT32], [ADDRESS, UINT128, BOOL, BOOL, CELL], [ADDRESS, UINT128, BOOL, UINT8, CELL], [STRING]];
//    string[][] constant AN = [[""], ["send", "dest", "value"],
//        ["submitTransaction", "dest", "value", "bounce", "allBalance", "payload"],
//        ["sendTransaction", "dest", "value", "bounce", "flags", "payload"],
//        ["nFrame", "label"]];
//    string[][] constant AN = [[""], ["dest", "value"],
//        ["dest", "value", "bounce", "allBalance", "payload"],
//        ["dest", "value", "bounce", "flags", "payload"],
//        ["label"]];
