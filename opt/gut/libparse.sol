pragma ton-solidity >= 0.71.0;
import "types.h";

library libparse {
    uint8 constant EMPTY     = 1;
    uint8 constant PRAGMA    = 2;
    uint8 constant TYPE_DEF  = 3;
    uint8 constant VAR_DECL  = 4;
    uint8 constant BLOCK_END = 5;
    uint8 constant UNKNOWN   = 6;
    uint8 constant VERSION   = 1;
    bytes constant WHITESPACE = "\t\n ";
    uint8 constant ERROR = 0xFF;
    function strip_leading(bytes s, bytes cc) internal returns (bytes) {
        uint pos;
        for (bytes1 b: s) {
            if (strchr(cc, b) > 0)
                pos++;
            else
                break;
        }
        return pos > 0 ? s[pos : ] : s;
    }
    function strip_trailing(bytes s, bytes1 c) internal returns (bytes) {
        uint len = s.length;
        return len > 0 && s[len - 1] == c ? s[ : len - 1] : s;
    }
    function words(bytes s, bytes1 c, bool skip_empty) internal returns (bytes[] ww) {
        uint i;
        uint t;
        uint len = s.length;
        while (i < len) {
            if (s[i] == c) {
                if (!skip_empty || i > t) {
                    ww.push(s[t : i]);
                    t = i;
                }
                while (i < len && s[i] == c) {
                    i++;
                    t++;
                }
            }
            i++;
        }
        if (t < len)
            ww.push(s[t : ]);
    }
    function parse_line(bytes line) internal returns (uint8 lh, uint8 th) {
        uint len = line.length;
        if (len == 0)
            return (EMPTY, NONE);
        if (line == "}")
            return (BLOCK_END, NONE);
        bytes[] www = words(line, ' ', true);
        if (www.length <= 1)
            return (UNKNOWN, NONE);
        bytes w1 = www[0];
        uint q;
        if (w1 == "struct") {
            lh = TYPE_DEF;
            th = STRUCT;
        } else if (w1 == "enum") {
            lh = TYPE_DEF;
            th = ENUM;
        } else if (w1 == "pragma") {
            lh = PRAGMA;
            if (www[1] == "ton-solidity" || www[1] == "ever-solidity")
                th = VERSION;
        } else if ((q = strchr(line, ';')) > 0) {
            bytes vdecl = line[ : q - 1];
            lh = VAR_DECL;
            bytes vtype = strip_leading(vdecl[ : q - 1], WHITESPACE);
            uint vl = vtype.length;
            if ((q = strrchr(vtype, '[')) > 0)
                th = ARRAY;
            else if (vl > 7 && vtype[ : 7] == "mapping")
                th = MAP;
            else if (vl > 2 && vtype[ : 3] == "int")
                th = INT;
            else if (vl > 3 && vtype[ : 4] == "uint")
                th = UINT;
            else if (vl > 4 && vtype[ : 5] == "bytes")
                th = BYTES;
            else if (vl > 5 && vtype[ : 6] == "string")
                th = STRING;
            else if (vl > 3 && vtype[ : 4] == "bool")
                th = BOOL;
            else if (vl > 6 && vtype[ : 7] == "TvmCell")
                th = CELL;
        }
    }
    function parse_decl(bytes line) internal returns (bytes vtype, bytes vname, bytes vcom) {
        uint q;
        if ((q = strrchr(line, '/')) > 0)
            vcom = strip_leading(line[q : ], WHITESPACE);
        if ((q = strchr(line, ';')) > 0) {
            bytes vdecl = line[ : q - 1];
            if ((q = strrchr(vdecl, ' ')) > 0) {
                vname = vdecl[q : ];
                vtype = strip_leading(vdecl[ : q - 1], WHITESPACE);
            }
        }
    }
    function parse_type_def(bytes line) internal returns (bytes vtype, bytes vname, bytes vcom) {
        bytes[] www = words(line, ' ', true);
        vtype = www[0];
        if (vtype == "struct" || vtype == "enum") {
            vname = www[1];
            uint q;
            if ((q = strrchr(line, '/')) > 0)
                vcom = strip_leading(line[q : ], WHITESPACE);
        }
    }
    function scan(bytes[] lines) internal returns (mapping (uint => uint8) tnc, a_type[] tc) {
        string[] btnames = ["?", "bool", "int", "uint", "bytes", "string", "TvmCell", "struct", "array", "map", "enum"];
        for (uint8 i = 0; i < btnames.length; i++) {
            string nm = btnames[i];
            tnc.put(nm, i);
            tc.push(a_type(i == BOOL || i == CELL ? i : NONE, nm));
        }
        for (bytes line: lines) {
            (uint lh, uint th) = parse_line(line);
            bytes tname;
            if (lh == VAR_DECL)
                (tname, , ) = parse_decl(line);
            else if (lh == TYPE_DEF)
                (, tname, ) = parse_type_def(line);
            else if (lh == PRAGMA)
                tname = words(line, ' ', true)[1];
            if (!tnc.exists(tname)) {
                tnc.put(tname, tc.length);
                tc.push(a_type(uint8(th), tname));
            }
        }
    }
    function parse_vars(bytes[] lines, mapping (uint => uint8) tnc) internal returns (mapping (uint8 => uint8[]) vars, mapping (uint8 => string[]) vnames) {
        uint8 tcur;
        for (bytes line: lines) {
            (uint lh, uint th) = parse_line(line);
            if (lh == BLOCK_END) {
                delete tcur;
                continue;
            }
            if (lh == TYPE_DEF) {
                (, bytes vname, ) = parse_type_def(line);
                uint8 tid = tnc.get(vname);
                if (th == STRUCT)
                    tcur = tid;
                else if (th == ENUM) {
                    bytes[] www = words(line, ' ', true);
                    for (uint i = 3; i < www.length; i++) {
                        bytes wi = www[i];
                        if (wi == "{")
                            continue;
                        if (wi == "}")
                            break;
                        vars[tid].push(UINT);
                        vnames[tid].push(strip_trailing(wi, ','));
                    }
                }
            } else if (lh == VAR_DECL) {
                (bytes vtype, bytes vname, ) = parse_decl(line);
                uint8 tid = tnc.get(vtype);
                vars[tcur].push(tid);
                vnames[tcur].push(vname);
                if (th == ARRAY) {
                    uint8 vcnt = 1;
                    bytes[] www = words(line, ' ', true);
                    uint q = strrchr(vtype, "[");
                    if (q > 0) {
                        if (q + 1 < www[0].length) {
                            optional(int) vi = stoi(vtype[q : www[0].length - 1]);
                            if (vi.hasValue())
                                vcnt = uint8(vi.get());
                        } else
                            vcnt = 0;
                        vars[tid] = [tnc.get(vtype[ : q - 1])];
                        vnames[tid] = [vname];
                    }
                } else if (th == MAP) {
                    bytes[] wwm = words(vtype, ' ', false);
                    vars[tid] = [tnc.get(wwm[1][1 : ]), tnc.get(strip_trailing(wwm[3], ')'))];
                    vnames[tid] = ["key", "value"];
                }
            }
        }
    }
    function parse_pragma(bytes[] lines) internal returns (uint8 maj, uint8 min) {
        for (bytes line: lines) {
            bytes[] www = words(line, ' ', true);
            if (www.length > 1 && www[0] == "pragma") {
                if (www[1] == "ton-solidity" || www[1] == "ever-solidity") {
                    bytes[] wx = words(www[3], '.', true);
                    optional(int) vi = stoi(wx[1]);
                    if (vi.hasValue())
                        maj = uint8(vi.get());
                    vi = stoi(wx[2]);
                    if (vi.hasValue())
                        min = uint8(vi.get());
                }
            }
        }
    }
}
using libnamecache for mapping (uint => uint8);
library libnamecache {
    function get(mapping (uint => uint8) nc, string name) internal returns (uint8) {
        return nc[tvm.hash(name)];
    }
    function put(mapping (uint => uint8) nc, string name, uint value) internal {
        nc[tvm.hash(name)] = uint8(value);
    }
    function exists(mapping (uint => uint8) nc, string name) internal returns (bool) {
        return nc.exists(tvm.hash(name));
    }
}

