pragma ton-solidity >= 0.48.0;

import "Base.sol";
import "String.sol";

abstract contract Map is Base, String {

    function _read_pair(string s) internal pure returns (string field1, string field2) {
        uint16 p = _strchr(s, "\t");
        field1 = s.substr(0, p - 1);
        field2 = s.substr(p, uint16(s.byteLength()) - p);
    }

    function _read_triple(string s) internal pure returns (string field1, string field2, string field3) {
        uint16 p = _strchr(s, "\t");
        uint16 q = _strrchr(s, "\t");
        field1 = s.substr(0, p - 1);
        field2 = s.substr(p, q - 1);
        field3 = s.substr(q, uint16(s.byteLength()) - q);
    }

    function _read_entry(string s) internal pure returns (string[] fields) {
        uint16 p = _strchr(s, "\t");
        uint16 len = uint16(s.byteLength());
        string field;
        string tail;

        field = s.substr(0, p - 1);
        tail = s.substr(p, len - p);
        fields.push(field);
        string[] tail_fields = _read_entry(tail);
        for (string s0: tail_fields)
            fields.push(s0);
    }

    function _lookup_value(string name, string text) internal pure returns (string) {
        string[] lines = _get_lines(text);
        for (string s: lines) {
            (string key, string value) = _read_pair(s);
            if (key == name)
                return value;
            if (value == name)
                return key;
        }
    }
}
