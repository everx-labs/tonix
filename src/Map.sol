pragma ton-solidity >= 0.49.0;

import "Base.sol";
import "String.sol";

abstract contract Map is Base, String {

    function _read_entry(string s) internal pure returns (string[] fields) {
        if (!s.empty())
            return _split(s, "\t");
    }

    function _lookup_pair_value(string name, string text) internal pure returns (string) {
        for (string s: _get_lines(text)) {
            uint16 p = _strchr(s, "\t");
            string key = s.substr(0, p - 1);
            string value = s.substr(p, uint16(s.byteLength()) - p);
            if (key == name)
                return value;
            if (value == name)
                return key;
        }
    }

    function _match_value_at_index(uint16 key_index, string key, uint16 value_index, string text) internal pure returns (string) {
        if (key_index > 0 && value_index > 0)
            for (string s: _get_lines(text)) {
                string[] fields = _read_entry(s);
                if (fields[key_index - 1] == key)
                    return fields[value_index - 1];
            }
    }

    function _lookup_record(uint16 field, string key, string text) internal pure returns (string[]) {
        for (string s: _get_lines(text)) {
            string[] fields = _read_entry(s);
            if (fields[field] == key)
                return fields;
        }
    }

    function _lookup_field(string s, string text) internal pure returns (uint16) {
        string[] fields = _read_entry(text);
        for (uint i = 0; i < fields.length; i++)
            if (fields[i] == s)
                return uint16(i + 1);
    }

}
