pragma ton-solidity >= 0.71.0;

import "common.h";
import "libparse.sol";

contract lpar is common {

    function cache_source(string ss) external {
        tvm.accept();
        _ram[22] = abi.encode(ss);
    }

    function parse_source(string name, string ss) external pure returns (string mname, uint8 maj, uint8 min, a_type[] tc, mapping (uint8 => uint8[]) vars, mapping (uint8 => string[]) vnames) {
        mname = name;
        (maj, min, tc, vars,  vnames) = _parse_source(ss);
    }

    function parse() external view returns (uint8 maj, uint8 min, a_type[] tc, mapping (uint8 => uint8[]) vars, mapping (uint8 => string[]) vnames) {
        string ss = abi.decode(_ram[22], string);
        (maj, min, tc, vars,  vnames) = _parse_source(ss);
    }
    function _parse_source(string ss) internal pure returns (uint8 maj, uint8 min, a_type[] tc, mapping (uint8 => uint8[]) vars, mapping (uint8 => string[]) vnames) {
        bytes[] lines = libparse.words(ss, '\n', true);
        mapping (uint => uint8) tnc;
        (tnc, tc) = libparse.scan(lines);
        (maj, min) = libparse.parse_pragma(lines);
        (vars, vnames) = libparse.parse_vars(lines, tnc);
    }
}
