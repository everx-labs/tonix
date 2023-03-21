pragma ton-solidity >= 0.67.0;
library libflags {
    function tou(string s) internal returns (uint val) {
        optional (int) p = stoi(s);
        if (p.hasValue())
            return uint(p.get());
    }

    function set(mapping (uint8 => string) flags, bytes1 o) internal returns (bool) {
        return flags.exists(uint8(o));
    }
    function flags_set(mapping (uint8 => string) flags, bytes optstring) internal returns (bool f1, bool f2, bool f3, bool f4) {
        uint len = optstring.length;
        f1 = len > 0 && flags.exists(uint8(optstring[0]));
        f2 = len > 1 && flags.exists(uint8(optstring[1]));
        f3 = len > 2 && flags.exists(uint8(optstring[2]));
        f4 = len > 3 && flags.exists(uint8(optstring[3]));
    }
    function option_values(mapping (uint8 => string) flags, bytes optstring) internal returns (string s1, string s2, string s3, string s4) {
        uint len = optstring.length;
        s1 = len > 0 ? flags[uint8(optstring[0])] : "";
        s2 = len > 1 ? flags[uint8(optstring[1])] : "";
        s3 = len > 2 ? flags[uint8(optstring[2])] : "";
        s4 = len > 3 ? flags[uint8(optstring[3])] : "";
    }
    function option_values_uint(mapping (uint8 => string) flags, bytes optstring) internal returns (uint u1, uint u2, uint u3, uint u4) {
        uint len = optstring.length;
        (string s1, string s2, string s3, string s4) = option_values(flags, optstring);
        u1 = len > 0 ? tou(s1) : 0;
        u2 = len > 1 ? tou(s2) : 0;
        u3 = len > 2 ? tou(s3) : 0;
        u4 = len > 3 ? tou(s4) : 0;
    }
}