pragma ton-solidity >= 0.71.0;
import "common.h";
import "libgen.sol";
import "libparse.sol";

contract lgen is common {

    using libprint for string[];

    function var_types(a_type[] tc, uint8[] ii) internal pure returns (a_type[] tta) {
        for (uint8 i: ii)
            tta.push(tc[i]);
    }

    function var_type_names(a_type[] tc, uint8[] ii) internal pure returns (string[] tnam) {
        for (uint i = 0; i < ii.length; i++)
            tnam.push(tc[ii[i]].name);
    }

    function do_gen(uint n) external view returns (string[] res) {
        uint32 a = uint32(n & 0xFFFFFFFF);
        (a_type[] tc, mapping (uint8 => uint8[]) vars, mapping (uint8 => string[]) vnames) = abi.decode(_ram[a], (a_type[], mapping (uint8 => uint8[]), mapping (uint8 => string[])));
        return _gen_lib("rt", 68, 0, tc, vars, vnames);
    }
    function gen_json(a_type[] tc, mapping (uint8 => uint8[]) vars, mapping (uint8 => string[]) vnames) external pure returns (string[] res) {
        string[] lines;
        for (uint8 id = 0; id < tc.length; id++) {
            (uint attr, string name) = tc[id].unpack();
            if (attr == STRUCT) {
                string[] tns = _strcat(var_type_names(tc, vars[id]), "{\"type\":\"", "\"");
                string[] vns = _strcat(vnames[id], "\"name\":\"", "\"}");
                lines.print_lists(tns, vns, ", ", ", ", "{\"name\":\"" + name + "\", \"fields\": [", "] }");
            }
        }
        res.print_list(lines, ",\n", "{\"modules\": [", "] }");
    }

    function gen_lib(string mname, uint8 maj, uint8 min, a_type[] tc, mapping (uint8 => uint8[]) vars, mapping (uint8 => string[]) vnames) external pure returns (string[] res) {
        return _gen_lib(mname, maj, min, tc, vars, vnames);
    }

    function _gen_lib(string mname, uint8 maj, uint8 min, a_type[] tc, mapping (uint8 => uint8[]) vars, mapping (uint8 => string[]) vnames) internal pure returns (string[] res) {
        res.println("pragma ton-solidity >= 0." + format("{}.{}", maj, min) + ";\n");
        for (uint8 id = 0; id < tc.length; id++) {
            (uint attr, string name) = tc[id].unpack();
            if (attr >= STRUCT) {
                if (attr == ENUM)
                    res.print_list(vnames[id], ", ", "\nenum " + name + " { ", " }");
                else if (attr == STRUCT)
                    res.print_table([var_type_names(tc, vars[id]), vnames[id]], " ", "    ", ";", "struct " + name + " {", "}");

                a_type[] va = var_types(tc, vars[id]);

                string tname = attr == ARRAY ? libgen.fix_arr_name(name) : attr == MAP ? libgen.fix_map_name(name) : name;
                res.println("using lib" + tname + " for " + name + (attr == STRUCT ? " global" : "") + ";");
                res.println("\nlibrary lib" + tname + " {");
                (string[] body, string[] nested) = libgen.gen_toString(tc[id], vnames[id], va);
                res.print_function("function toString(" + name + " val) internal returns (string out) {", body, nested);
                res.println("}\n");
            }
        }
        string[] ctx = ["\ncontract " + mname + " {\n"];
        ctx.push("}");
        res.print_lines(ctx);
    }
}
