pragma ton-solidity >= 0.64.0;
import "str.sol";
import "libtable.sol";
import "filedesc_h.sol";
import "libfdt.sol";
import "xio.sol";
struct nlist {
    string n_name;  // symbol name (in memory)
    uint8 n_type;   // type defines
    uint8 n_other;  // ".type" and binding information
    uint8 n_desc;   // used by stab entries
    uint32 n_value; // address/value of the symbol
}

struct nval {
    string name;
    uint32 type_mask;
    vals value;
}

struct vals {
    bool bool_value;
    uint16 number_value;
    string string_value;
    string[] nvlist_value;
    uint8 descriptor_value;
    bytes binary_value;
    bool[] bool_array_value;
    uint16[] number_array_value;
    string[] string_array_value;
    uint32[][] nvlist_array_value;
    uint8[] descriptor_array_value;
    bytes[] binary_array_value;
}

library libnvent {
    uint16 constant NV_NAME_MAX   = 2048;
    uint8 constant NV_TYPE_NONE   = 0;
    uint8 constant NV_TYPE_NULL   = 1;
    uint8 constant NV_TYPE_BOOL   = 2;
    uint8 constant NV_TYPE_NUMBER = 3;
    uint8 constant NV_TYPE_STRING = 4;
    uint8 constant NV_TYPE_NVLIST = 5;
    uint8 constant NV_TYPE_DESCRIPTOR = 6;
    uint8 constant NV_TYPE_BINARY = 7;
    uint8 constant NV_TYPE_BOOL_ARRAY = 8;
    uint8 constant NV_TYPE_NUMBER_ARRAY = 9;
    uint8 constant NV_TYPE_STRING_ARRAY = 10;
    uint8 constant NV_TYPE_NVLIST_ARRAY = 11;
    uint8 constant NV_TYPE_DESCRIPTOR_ARRAY = 12;
    uint8 constant NV_TYPE_NVLIST_ARRAY_NEXT = 254;
    uint8 constant NV_TYPE_NVLIST_UP = 255;
    uint8 constant NV_TYPE_FIRST = NV_TYPE_NULL;
    uint8 constant NV_TYPE_LAST	 = NV_TYPE_DESCRIPTOR_ARRAY;
    uint16 constant NV_FLAG_BIG_ENDIAN	= 0x080;
    uint16 constant NV_FLAG_IN_ARRAY 	= 0x100;
//    uint16 constant HAS_NONE_VALUE = 
    uint16 constant HAS_NULL_VALUE = uint16(1) << NV_TYPE_NULL;
    uint16 constant HAS_BOOL_VALUE = uint16(1) << NV_TYPE_BOOL;
    uint16 constant HAS_NUMBER_VALUE = uint16(1) << NV_TYPE_NUMBER;
    uint16 constant HAS_STRING_VALUE = uint16(1) << NV_TYPE_STRING;
    uint16 constant HAS_NVLIST_VALUE = uint16(1) << NV_TYPE_NVLIST;
    uint16 constant HAS_DESCRIPTOR_VALUE = uint16(1) << NV_TYPE_DESCRIPTOR;
    uint16 constant HAS_BINARY_VALUE = uint16(1) << NV_TYPE_BINARY;
    uint16 constant HAS_BOOL_ARRAY_VALUE = uint16(1) << NV_TYPE_BOOL_ARRAY;
    uint16 constant HAS_NUMBER_ARRAY_VALUE = uint16(1) << NV_TYPE_NUMBER_ARRAY;
    uint16 constant HAS_STRING_ARRAY_VALUE = uint16(1) << NV_TYPE_STRING_ARRAY;
    uint16 constant HAS_NVLIST_ARRAY_VALUE = uint16(1) << NV_TYPE_NVLIST_ARRAY;
    uint16 constant HAS_DESCRIPTOR_ARRAY_VALUE = uint16(1) << NV_TYPE_DESCRIPTOR_ARRAY;
    function as_row(nval nv) internal returns (string[] res) {
        (string name, uint32 type_mask, vals value) = nv.unpack();
        return [name, str.toa(type_mask),
(type_mask & HAS_BOOL_VALUE) > 0 ? btoa(value.bool_value) : '-',
(type_mask & HAS_NUMBER_VALUE) > 0 ? str.toa(value.number_value) : '-',
(type_mask & HAS_STRING_VALUE) > 0 ? value.string_value : '-',
(type_mask & HAS_NVLIST_VALUE) > 0 ? value.string_value : '-',
(type_mask & HAS_DESCRIPTOR_VALUE) > 0 ? str.toa(value.number_value)  : '-',
(type_mask & HAS_BINARY_VALUE) > 0 ? value.binary_value  : '-',
(type_mask & HAS_STRING_ARRAY_VALUE) > 0 ? libstring.join_fields(value.string_array_value, ' ')  : '-'
/*(type_mask & HAS_BOOL_ARRAY_VALUE) > 0 ? 
(type_mask & HAS_NUMBER_ARRAY_VALUE) > 0 ? 
(type_mask & HAS_STRING_ARRAY_VALUE) > 0 ? 
(type_mask & HAS_NVLIST_ARRAY_VALUE) > 0 ? 
(type_mask & HAS_DESCRIPTOR_ARRAY_VALUE) > 0 ? 
    */ ];
    }
    function btoa(bool f) internal returns (string) {
        return f ? "true" : "false";
    }
    function string_value(nval nv) internal returns (string) {
        return nv.value.string_value;
    }
    function bool_value(nval nv) internal returns (string) {
        return nv.value.string_value;
    }

}
struct nvlist_t {
    uint24 nvl_magic;
    uint8 nvl_error;
    uint8 nvl_flags;
    uint32 nvl_datasize;
    string nvl_name;
    nvpair_t[] nvl_items;
    nvlist_header nvl_header;
}

struct nvlist_header {
    uint8 nvlh_magic;
    uint8 nvlh_version;
    uint8 nvlh_flags;
    uint64 nvlh_descriptors;
    uint64 nvlh_size;
}

struct nvpair_t {
    uint24 nvp_magic;
    string nvp_name;
    uint8 nvp_type;
    string nvp_data;
    uint16 nvp_datasize;
    uint16 nvp_nitems;	// Used only for array types.
}

struct nvpair_header {
    uint8 nvph_type;
    uint8 nvph_namesize;
    uint16 nvph_datasize;
    uint16 nvph_nitems;
}

library libnvpair {

    uint8 constant EINVAL   = 22; // Invalid argument
    uint8 constant ENAMETOOLONG = 63; // File name too long

    uint24 constant	NVPAIR_MAGIC =	0x6e7670; // "nvp"
    uint16 constant NV_NAME_MAX   = 2048;
    uint8 constant NV_TYPE_NONE   = 0;
    uint8 constant NV_TYPE_NULL   = 1;
    uint8 constant NV_TYPE_BOOL   = 2;
    uint8 constant NV_TYPE_NUMBER = 3;
    uint8 constant NV_TYPE_STRING = 4;
    uint8 constant NV_TYPE_NVLIST = 5;
    uint8 constant NV_TYPE_DESCRIPTOR = 6;
    uint8 constant NV_TYPE_BINARY = 7;
    uint8 constant NV_TYPE_BOOL_ARRAY = 8;
    uint8 constant NV_TYPE_NUMBER_ARRAY = 9;
    uint8 constant NV_TYPE_STRING_ARRAY = 10;
    uint8 constant NV_TYPE_NVLIST_ARRAY = 11;
    uint8 constant NV_TYPE_DESCRIPTOR_ARRAY = 12;
    uint8 constant NV_TYPE_NVLIST_ARRAY_NEXT = 254;
    uint8 constant NV_TYPE_NVLIST_UP = 255;
    uint8 constant NV_TYPE_FIRST = NV_TYPE_NULL;
    uint8 constant NV_TYPE_LAST	 = NV_TYPE_DESCRIPTOR_ARRAY;
    uint16 constant NV_FLAG_BIG_ENDIAN	= 0x080;
    uint16 constant NV_FLAG_IN_ARRAY 	= 0x100;

    function btoa(bool f) internal returns (string) {
        return f ? "TRUE" : "FALSE";
    }
    function as_row(nvpair_t nvp) internal returns (string[] res) {
	    (uint32 nvp_magic, string nvp_name, uint8 nvp_type, string nvp_data, uint64 nvp_datasize, uint16 nvp_nitems) = nvp.unpack();
        return [bytes(bytes4(nvp_magic)), nvp_name, nvpair_type_string(nvp_type), format("{}", nvp_datasize), str.toa(nvp_nitems), nvp_data];
    }
    function nvpair_allocv(string name, uint8 ntype, string data, uint16 datasize, uint16 nitems) internal returns (nvpair_t nvp) {
    	uint16 namelen = str.strlen(name);
        if (ntype >= NV_TYPE_FIRST && ntype <= NV_TYPE_LAST && namelen < NV_NAME_MAX) { //    		ERRNO_SET(err.ENAMETOOLONG);
            return nvpair_t(NVPAIR_MAGIC, name, ntype, data, datasize, nitems);
    	}
    }

    function nvpair_clone(nvpair_t nvp)  internal returns (nvpair_t newnvp) {
    	string name;
    	bytes data;
    	uint16 datasize;
    //	NVPAIR_ASSERT(nvp);
    	name = nvpair_name(nvp);
        uint8 t = nvpair_type(nvp);
        if (t == NV_TYPE_NULL) newnvp = nvpair_create_null(name);
        if (t == NV_TYPE_BOOL) newnvp = nvpair_create_bool(name, nvpair_get_bool(nvp));
        if (t == NV_TYPE_NUMBER) newnvp = nvpair_create_number(name, nvpair_get_number(nvp));
        if (t == NV_TYPE_STRING) newnvp = nvpair_create_string(name, nvpair_get_string(nvp));
        if (t == NV_TYPE_NVLIST) newnvp = nvpair_create_nvlist(name, nvpair_get_nvlist(nvp));
        if (t == NV_TYPE_DESCRIPTOR) newnvp = nvpair_create_descriptor(name, nvpair_get_descriptor(nvp));
        if (t == NV_TYPE_BINARY) {
            (data, datasize) = nvpair_get_binary(nvp);
        }
    }

    function create_pair(uint8 ntype, string name, string value, uint16 nitems) internal returns (uint8 ec, nvpair_t nvp) {
//        nvpair_t nvp = libnvpair.create_pair(ntype, name, value, nitems);
        if (ntype < NV_TYPE_FIRST || ntype > NV_TYPE_LAST)
            ec = EINVAL;
        else if (str.strlen(name) >= NV_NAME_MAX)
            ec = ENAMETOOLONG;
        else {
            nvp = nvpair_t(NVPAIR_MAGIC, name, ntype, value, str.strlen(value), nitems);
            uint32 size;
            if (nvp.nvp_type == NV_TYPE_NVLIST) {
                nvlist_t nvlistnew = libnvpair.nvpair_get_nvlist(nvp);
                size += nvlistnew.nvl_datasize;
                size += libnvpair.nvpair_header_size() + 1;
            } else if (nvp.nvp_type == NV_TYPE_NVLIST_ARRAY) {
                (nvlist_t[] nvlarray, uint16 nitems2) = libnvpair.nvpair_get_nvlist_array(nvp);
                if (nitems2 > 0) {
                    size += (libnvpair.nvpair_header_size() + 1) * nitems2;
                    for (uint ii = 0; ii < nitems2; ii++)
                        size += nvlarray[ii].nvl_datasize;
                }
            }
        }
    }

    function nvpair_assert(nvpair_t nvp) internal {}
    function nvpair_nvlist(nvpair_t nvp) internal returns (nvlist_t) {}
    function nvpair_next(nvpair_t nvp) internal returns (nvpair_t) {}
    function nvpair_prev(nvpair_t nvp) internal returns (nvpair_t) {}
//    function nvpair_insert(nvl_head head, nvpair_t nvp, nvlist_t nvl) internal {}
//    function nvpair_remove(nvl_head head, nvpair_t nvp, nvlist_t nvl) internal {}
    function nvpair_header_size() internal returns (uint16) {}
    function nvpair_size(nvpair_t nvp) internal returns (uint16) {}
    function nvpair_unpack(bool isbe, string ptr, uint16 leftp, nvpair_t[] nvpp) internal returns (string) {}
    function nvpair_free_structure(nvpair_t nvp) internal {}
    function nvpair_init_datasize(nvpair_t nvp) internal {}
    function nvpair_type_string(uint8 ntype) internal returns (string) {
//        if (ntype == NV_TYPE_NONE) return "NONE";
        if (ntype == NV_TYPE_NULL) return "NULL";
        if (ntype == NV_TYPE_BOOL) return "BOOL";
        if (ntype == NV_TYPE_NUMBER) return "NUMBER";
        if (ntype == NV_TYPE_STRING) return "STRING";
        if (ntype == NV_TYPE_NVLIST) return "NVLIST";
        if (ntype == NV_TYPE_DESCRIPTOR) return "DESCRIPTOR";
        if (ntype == NV_TYPE_BINARY) return "BINARY";
        if (ntype == NV_TYPE_BOOL_ARRAY) return "BOOL ARRAY";
        if (ntype == NV_TYPE_NUMBER_ARRAY) return "NUMBER ARRAY";
        if (ntype == NV_TYPE_STRING_ARRAY) return "STRING ARRAY";
        if (ntype == NV_TYPE_NVLIST_ARRAY) return "NVLIST ARRAY";
        if (ntype == NV_TYPE_DESCRIPTOR_ARRAY) return "DESCR ARRAY";
		return "<UNKNOWN>";
    }
    function nvpair_pack_header(nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_pack_null(nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_pack_bool(nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_pack_number(nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_pack_string(nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_pack_descriptor(nvpair_t nvp, string ptr, int64 fdidxp, uint16 leftp) internal returns (string) {}
    function nvpair_pack_binary(nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
//    function nvpair_pack_nvlist_up(string ptr, stringlftp) internal returns (string) {}
    function nvpair_pack_bool_array(nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_pack_number_array(nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_pack_string_array(nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_pack_descriptor_array(nvpair_t nvp, string ptr, int64 fdidxp, uint16 leftp) internal returns (string) {}
    function nvpair_pack_nvlist_array_next(string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_unpack_header(bool isbe, nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_unpack_null(bool isbe, nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_unpack_bool(bool isbe, nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_unpack_number(bool isbe, nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_unpack_string(bool isbe, nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_unpack_nvlist(bool isbe, nvpair_t nvp, string ptr, uint16 leftp, uint16 nfds, nvlist_t[] child) internal returns (string) {}
    function nvpair_unpack_descriptor(bool isbe, nvpair_t nvp, string ptr, uint16 leftp, uint8[] fds, uint16 nfds) internal returns (string) {}
    function nvpair_unpack_binary(bool isbe, nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_unpack_bool_array(bool isbe, nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_unpack_number_array(bool isbe, nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_unpack_string_array(bool isbe, nvpair_t nvp, string ptr, uint16 leftp) internal returns (string) {}
    function nvpair_unpack_descriptor_array(bool isbe, nvpair_t nvp, string ptr, uint16 leftp, uint8 fds, uint16 nfds) internal returns (string) {}
    function nvpair_unpack_nvlist_array(bool isbe, nvpair_t nvp, string ptr, uint16 leftp, nvlist_t[] firstel) internal returns (string) {}

    function nvpair_type(nvpair_t nvp) internal returns (uint8) {}
    function nvpair_name(nvpair_t nvp) internal returns (string) {

    }
    function nvpair_create_null(string name) internal returns (nvpair_t) {
        return nvpair_t(NVPAIR_MAGIC, name, NV_TYPE_NULL, "", 0, 0);
    }
    function nvpair_create_bool(string name, bool value) internal returns (nvpair_t) {
        return nvpair_t(NVPAIR_MAGIC, name, NV_TYPE_BOOL, btoa(value), 1, 0);
    }
    function nvpair_create_number(string name, uint16 value) internal returns (nvpair_t) {
        return nvpair_t(NVPAIR_MAGIC, name, NV_TYPE_NUMBER, str.toa(value), 2, 0);
    }
    function nvpair_create_string(string name, string value) internal returns (nvpair_t) {
        return nvpair_t(NVPAIR_MAGIC, name, NV_TYPE_STRING, value, str.strlen(value), 0);
    }
    function nvpair_create_stringf(string name, string valuefmt) internal returns (nvpair_t) {}
    function nvpair_create_stringv(string name, string valuefmt) internal returns (nvpair_t) {}
    function nvpair_create_nvlist(string name, nvlist_t value) internal returns (nvpair_t) {}
    function nvpair_create_descriptor(string name, uint8 value) internal returns (nvpair_t) {
        return nvpair_t(NVPAIR_MAGIC, name, NV_TYPE_DESCRIPTOR, str.toa(value), 1, 0);
    }
    function nvpair_create_binary(string name, bytes value, uint16 size) internal returns (nvpair_t) {
        return nvpair_t(NVPAIR_MAGIC, name, NV_TYPE_BINARY, value, size, 0);
    }

    function nvpair_create_bool_array(string name, bool[] value, uint16 nitems) internal returns (nvpair_t) {}
    function nvpair_create_number_array(string name, uint16[] value, uint16 nitems) internal returns (nvpair_t) {
//        string val = libstring.join_fields(value, '\n');
//        return nvpair_t(NVPAIR_MAGIC, name, NV_TYPE_NUMBER_ARRAY, val, str.strlen(val), 0);
    }
    function nvpair_create_string_array(string name, string[] value, uint16 nitems) internal returns (nvpair_t) {
        string val = libstring.join_fields(value, '\n');
//        return nvpair_allocv(name, NV_TYPE_STRING_ARRAY, val, str.strlen(val), nitems);
        return nvpair_t(NVPAIR_MAGIC, name, NV_TYPE_STRING_ARRAY, val, str.strlen(val), nitems);
    }
    function nvpair_create_nvlist_array(string name, nvlist_t[] value, uint16 nitems) internal returns (nvpair_t) {}
    function nvpair_create_descriptor_array(string name, uint8[] value, uint16 nitems) internal returns (nvpair_t) {}
    function nvpair_move_string(string name, string value) internal returns (nvpair_t) {}
    function nvpair_move_nvlist(string name, nvlist_t value) internal returns (nvpair_t) {}
    function nvpair_move_descriptor(string name, uint8 value) internal returns (nvpair_t) {}
    function nvpair_move_binary(string name, bytes value, uint16 size) internal returns (nvpair_t) {}
    function nvpair_move_bool_array(string name, bool[] value, uint16 nitems) internal returns (nvpair_t) {}
    function nvpair_move_nvlist_array(string name, nvlist_t[] value, uint16 nitems) internal returns (nvpair_t) {}
    function nvpair_move_descriptor_array(string name, uint8[] value, uint16 nitems) internal returns (nvpair_t) {}
    function nvpair_move_number_array(string name, uint16[] value, uint16 nitems) internal returns (nvpair_t) {}
    function nvpair_move_string_array(string name, string[] value, uint16 nitems) internal returns (nvpair_t) {}
    function nvpair_append_bool_array(nvpair_t nvp, bool value) internal returns (uint8) {}
    function nvpair_append_number_array(nvpair_t nvp, uint16 value) internal returns (uint8) {}
    function nvpair_append_string_array(nvpair_t nvp, string[] value) internal returns (uint8) {}
    function nvpair_append_nvlist_array(nvpair_t nvp, nvlist_t value) internal returns (uint8) {}
    function nvpair_append_descriptor_array(nvpair_t nvp, uint8 value) internal returns (uint8) {}
    function nvpair_get_bool(nvpair_t nvp) internal returns (bool) {}
    function nvpair_get_number(nvpair_t nvp) internal returns (uint16) {}
    function nvpair_get_string(nvpair_t nvp) internal returns (string) {}
    function nvpair_get_nvlist(nvpair_t nvp) internal returns (nvlist_t) {}
    function nvpair_get_descriptor(nvpair_t nvp) internal returns (uint8) {}
    function nvpair_get_binary(nvpair_t nvp) internal returns (bytes, uint16 sizep) {}
    function nvpair_get_bool_array(nvpair_t nvp) internal returns (bool[], uint16 nitemsp) {}
    function nvpair_get_number_array(nvpair_t nvp) internal returns (uint16[], uint16 nitemsp) {}
    function nvpair_get_string_array(nvpair_t nvp) internal returns (string[], uint16 nitemsp) {}
    function nvpair_get_nvlist_array(nvpair_t nvp) internal returns (nvlist_t[], uint16 nitemsp) {}
    function nvpair_get_descriptor_array(nvpair_t nvp) internal returns (uint8[], uint16 nitemsp) {}

    function nvpair_free(nvpair_t nvp) internal {
        delete nvp;
    }
}

library libnv {

    uint8 constant EEXIST   = 17; // File exists
    uint8 constant EINVAL   = 22; // Invalid argument

    uint8 constant NV_NAME_MAX   = 30;
    uint8 constant NV_TYPE_NONE   = 0;
    uint8 constant NV_TYPE_NULL   = 1;
    uint8 constant NV_TYPE_BOOL   = 2;
    uint8 constant NV_TYPE_NUMBER = 3;
    uint8 constant NV_TYPE_STRING = 4;
    uint8 constant NV_TYPE_NVLIST = 5;
    uint8 constant NV_TYPE_DESCRIPTOR = 6;
    uint8 constant NV_TYPE_BINARY = 7;
    uint8 constant NV_TYPE_BOOL_ARRAY = 8;
    uint8 constant NV_TYPE_NUMBER_ARRAY = 9;
    uint8 constant NV_TYPE_STRING_ARRAY = 10;
    uint8 constant NV_TYPE_NVLIST_ARRAY = 11;
    uint8 constant NV_TYPE_DESCRIPTOR_ARRAY = 12;
    uint8 constant NV_TYPE_NVLIST_ARRAY_NEXT = 254;
    uint8 constant NV_TYPE_NVLIST_UP = 255;
    uint8 constant NV_TYPE_FIRST = NV_TYPE_NULL;
    uint8 constant NV_TYPE_LAST	 = NV_TYPE_DESCRIPTOR_ARRAY;
    uint8 constant NV_FLAG_BIG_ENDIAN	= 0x80;
    uint8 constant NV_FLAG_IN_ARRAY 	= 0x40;

    uint32 constant NV_FLAG_PRIVATE_MASK = NV_FLAG_BIG_ENDIAN | NV_FLAG_IN_ARRAY;
    uint32 constant NV_FLAG_PUBLIC_MASK  = NV_FLAG_IGNORE_CASE | NV_FLAG_NO_UNIQUE;
    uint32 constant NV_FLAG_ALL_MASK     = NV_FLAG_PRIVATE_MASK | NV_FLAG_PUBLIC_MASK;
    uint24 constant NVLIST_MAGIC = 	0x6e766c; 	// "nvl"
    uint8 constant NVLIST_HEADER_MAGIC = 	0x6c;
    uint8 constant NVLIST_HEADER_VERSION = 0x00;
    uint24 constant	NVPAIR_MAGIC =	0x6e7670; // "nvp"
    uint8 constant NV_FLAG_IGNORE_CASE	= 0x01; // Perform case-insensitive lookups of provided names.
    uint8 constant NV_FLAG_NO_UNIQUE	= 0x02; // Names don't have to be unique.
// The nvlist_exists functions check if the given name (optionally of the given type) exists on nvlist.
// The nvlist_add functions add the given name/value pair. If a pointer is provided, nvlist_add will internally allocate memory for the
// given data (in other words it won't consume provided buffer).
// The nvlist_move functions add the given name/value pair. The functions consumes provided buffer.
// The nvlist_get functions returns value associated with the given name. If it returns a pointer, the pointer represents 
// internal buffer and should not be freed by the caller.
// The nvlist_take functions returns value associated with the given name and remove the given entry from the nvlist.
// The caller is responsible for freeing received data.
// The nvlist_free functions removes the given name/value pair from the nvlist and frees memory associated with it.

    using libfdt for s_of;
    using libnv for nvlist_t;
    using libnvpair for nvpair_t;
    using xio for s_of;
    using libtable for s_table;
    function nvlist_create(string name, uint8 flags) internal returns (nvlist_t) {
        nvpair_t[] items;
	    return nvlist_t(NVLIST_MAGIC, 0, flags, 8, name, items,
            nvlist_header(NVLIST_HEADER_MAGIC, NVLIST_HEADER_VERSION, 0, 0, 1));
    }
    function nvlist_destroy(nvlist_t nvl) internal {
        delete nvl;
    }
    function nvlist_error(nvlist_t nvl) internal returns (uint8) {
        return nvl.nvl_error;
    }

    function nvlist_set_error(nvlist_t nvl, uint8 error) internal {
        nvl.nvl_error = error;
    }

    function nvlist_empty(nvlist_t nvl) internal returns (bool) {
        return nvl.nvl_datasize == 0;
    }

    function nvlist_flags(nvlist_t nvl) internal returns (uint8) {
        return nvl.nvl_flags;
    }

    function nvlist_in_array(nvlist_t nvl) internal returns (bool) {
        return (nvl.nvl_flags & NV_FLAG_IN_ARRAY) > 0;
    }

    function nvlist_clone(nvlist_t nvl) internal returns (nvlist_t) {
        return nvl;
    }

    function nvlist_size(nvlist_t nvl) internal returns (uint64) {
        return nvl.nvl_datasize;
    }
    function nvlist_pack(nvlist_t nvl, uint16 sizep) internal returns (bytes) {}
    function nvlist_unpack(bytes buf, uint16 size, uint16 flags) internal returns (nvlist_t) {}
    //function nvlist_send(int sock, const nvlist_t *nvl) internal returns (int) {}
    //function nvlist_recv(int sock, int flags) internal returns (nvlist_t) {}
    //function nvlist_xfer(int sock, nvlist_t *nvl, int flags) internal returns (nvlist_t) {}
    //function nvlist_next(nvlist_t nvl, int *typep, void **cookiep) internal returns (string) {}
    //function nvlist_get_parent(nvlist_t nvl, void **cookiep) internal returns (nvlist_t) {}
    function nvlist_get_array_next(nvlist_t nvl) internal returns (nvlist_t) {}
    //function nvlist_get_pararr(nvlist_t nvl, void **cookiep) internal returns (nvlist_t) {}
    function nvlist_exists(nvlist_t nvl, string name) internal returns (bool) {
        for (nvpair_t p: nvl.nvl_items)
            if (p.nvp_name == name)
                return true;
        return false;
    }

    function gen(nvlist_t nvl, string name, uint8 ntype) internal returns (uint16[] res) {
        nvpair_t[] prs = nvl.nvl_items;
        bool find_all = (nvl.nvl_flags & NV_FLAG_NO_UNIQUE) > 0;
        bool any_type = ntype == NV_TYPE_NONE;
        for (uint i = 0; i < prs.length; i++) {
            nvpair_t np = prs[i];
            (, string nvp_name, uint8 nvp_type, , , ) = np.unpack();
            if (name == nvp_name && (any_type || ntype == nvp_type)) {
                res.push(uint16(i));
                if (!find_all)
                    return res;
            }
        }
    }

    function exists(nvlist_t nvl, string name) internal returns (bool) {
        for (nvpair_t p: nvl.nvl_items)
            if (p.nvp_name == name)
                return true;
        return false;
    }

    function find(nvlist_t nvl, string name, uint8 ntype) internal returns (bool res, uint) {
        bool any_type = ntype == NV_TYPE_NONE;
        for (uint i = 0; i < nvl.nvl_items.length; i++)
            if (nvl.nvl_items[i].nvp_name == name && (any_type || ntype == nvl.nvl_items[i].nvp_type))
                return (true, i);
        res = false;
    }

    function get(nvlist_t nvl, string name, uint8 ntype) internal returns (bool found, string value, uint16 nitems) {
        //uint16[] res = gen(nvl, name, ntype);
        //found = !res.empty();
        uint idx;
        (found, idx) = find(nvl, name, ntype);
        if (found) {
            nvpair_t p = nvl.nvl_items[idx];
            value = p.nvp_data;
            nitems = p.nvp_nitems;
        }
    }

    function add(nvlist_t nvl, uint8 ntype, string name, string value, uint16 nitems) internal {
        (uint8 ec, nvpair_t nvp) = libnvpair.create_pair(ntype, name, value, nitems);
        if (ec == 0) {
            (bool success, uint idx) = find(nvl, name, ntype);
            if (success && (nvl.nvl_flags & NV_FLAG_NO_UNIQUE) == 0) {
                nvl.nvl_datasize -= nvl.nvl_items[idx].nvp_datasize;
                nvl.nvl_items[idx] = nvp;
            } else
                nvl.nvl_items.push(nvp);
    	    nvl.nvl_datasize += str.strlen(value);
        } else
            nvl.nvl_error = ec;
    }

    function free(nvlist_t nvl, string name, uint8 ntype) internal {
        uint16[] res = gen(nvl, name, ntype);
        if (!res.empty()) {
            uint idx = res[0];
            nvpair_t[] items = nvl.nvl_items;
            nvpair_t p = items[idx];
            nvl.nvl_datasize -= p.nvp_datasize;
            uint nvl_len = items.length;
            for (uint i = idx; i < nvl_len - 1; i++)
                items[i] = items[i + 1];
            items.pop();
            nvl.nvl_items = items;
        } else {
            nvl.nvl_error = EINVAL;
        }
    }

    function take(nvlist_t nvl, string name, uint8 ntype) internal returns (string value, uint16 nitems) {
        uint16[] res = gen(nvl, name, ntype);
        if (!res.empty()) {
            uint idx = res[0];
            nvpair_t[] items = nvl.nvl_items;
            nvpair_t p = items[idx];
            value = p.nvp_data;
            nitems = p.nvp_nitems;
            nvl.nvl_datasize -= p.nvp_datasize;
            uint nvl_len = items.length;
            for (uint i = idx; i < nvl_len - 1; i++)
                items[i] = items[i + 1];
            items.pop();
            nvl.nvl_items = items;
        } else {
            nvl.nvl_error = EINVAL;
        }
    }

    function append(nvlist_t nvl, uint8 ntype, string name, string value) internal {
//        if (ec == 0) {
        uint16 size = str.strlen(value);
        uint8 ec;
        if (size > 0) {
            (bool success, uint idx) = find(nvl, name, NV_TYPE_NONE);
            nvpair_t nvp;
            if (success) {
                nvp = nvl.nvl_items[idx];
                if (nvp.nvp_type == ntype + 6) {
                    nvp.nvp_data.append(" " + value);
                    nvp.nvp_datasize += size;
                    nvl.nvl_items[idx] = nvp;
                } else
                    ec = EINVAL;
            } else {
                (ec, nvp) = libnvpair.create_pair(ntype, name, value, 0);
                if (ec == 0)
                    nvl.nvl_items.push(nvp);
            }
        }
        if (ec == 0)
            nvl.nvl_datasize += size;
        else
            nvl.nvl_error = ec;
    }

    function nvlist_exists_type(nvlist_t nvl, string name, uint8 ntype) internal returns (bool) {
        uint16[] res = gen(nvl, name, ntype);
        return !res.empty();
    }
    function nvlist_exists_null(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_NULL);
    }
    function nvlist_exists_bool(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_BOOL);
    }
    function nvlist_exists_number(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_NUMBER);
    }
    function nvlist_exists_string(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_STRING);
    }
    function nvlist_exists_nvlist(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_NVLIST);
    }
    function nvlist_exists_binary(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_BINARY);
    }
    function nvlist_exists_bool_array(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_BOOL_ARRAY);
    }
    function nvlist_exists_number_array(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_NUMBER_ARRAY);
    }

    function nvlist_exists_string_array(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_STRING_ARRAY);
    }

    function nvlist_exists_nvlist_array(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_NVLIST_ARRAY);
    }

    function nvlist_exists_descriptor(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_DESCRIPTOR);
    }

    function nvlist_exists_descriptor_array(nvlist_t nvl, string name) internal returns (bool) {
        return nvlist_exists_type(nvl, name, NV_TYPE_DESCRIPTOR_ARRAY);
    }

    function btoa(bool f) internal returns (string) {
        return f ? "TRUE" : "FALSE";
    }

    function base_type_string(uint8 ntype) internal returns (string res) {
        if (ntype == NV_TYPE_NULL) return "NULL";
        else if (ntype == NV_TYPE_BOOL) return "BOOL";
        else if (ntype == NV_TYPE_NUMBER) return "NUMBER";
        else if (ntype == NV_TYPE_STRING) return "STRING";
        else if (ntype == NV_TYPE_NVLIST) return "NVLIST";
        else if (ntype == NV_TYPE_DESCRIPTOR) return "DESCR";
        else if (ntype == NV_TYPE_BINARY) return "BINARY";
        else return "<UNKNOWN>";
    }
    function type_string(uint8 ntype, uint16 nitems) internal returns (string res) {
        res = base_type_string(ntype >= NV_TYPE_BOOL_ARRAY ? ntype - 6 : ntype);
        if (ntype < NV_TYPE_BOOL_ARRAY)
            return res;
        return res + '[' + (nitems > 0 ? str.toa(nitems) : '-') + ']';
    }

    function nvlist_dump(nvlist_t nvl, uint8 fd) internal {
    }
    function nvlist_as_row(nvlist_t nvl) internal returns (string[] res) {
	    (uint24 nvl_magic, uint8 nvl_error, uint8 nvl_flags, uint32 nvl_datasize, string nvl_name, nvpair_t[] nvl_items, ) = nvl.unpack();
        return [bytes(bytes3(nvl_magic)), nvl_name, str.toa(nvl_error), str.toa(nvl_flags), str.toa(nvl_datasize), str.toa(uint16(nvl_items.length))];
    }
    function nvlist_header_as_row(nvlist_header nvlh) internal returns (string[] res) {
	    (uint8 nvlh_magic, uint8 nvlh_version, uint8 nvlh_flags, uint64 nvlh_descriptors, uint64 nvlh_size) = nvlh.unpack();
        return [bytes(byte(nvlh_magic)), str.toa(nvlh_version), str.toa(nvlh_flags), format("{}", nvlh_descriptors), format("{}", nvlh_size)];
    }
    function nvpair_as_row(nvpair_t nvp) internal returns (string[] res) {
	    (uint24 nvp_magic, string nvp_name, uint8 nvp_type, string nvp_data, uint16 nvp_datasize, uint16 nvp_nitems) = nvp.unpack();
        return [bytes(bytes3(nvp_magic)), nvp_name, type_string(nvp_type, nvp_nitems), str.toa(nvp_datasize),
            nvp_type == NV_TYPE_BINARY ? nvp_data.empty() ? "<EMPTY>" : "<BINARY DATA>" : nvp_data];
    }
    function nvpair_header_as_row(nvpair_header nvph) internal returns (string[] res) {
	    (uint8 nvph_type, uint8 nvph_namesize, uint16 nvph_datasize, uint16 nvph_nitems) = nvph.unpack();
        return [type_string(nvph_type, nvph_nitems), str.toa(nvph_namesize), str.toa(nvph_datasize)];
    }
//    function nvpair_verbose(nvpair_t nvp)
    function nvlist_fdump(nvlist_t nvl, s_of fp) internal returns (s_of f) {
        f = fp;
        f.fputs(dump(nvl, 2));
    }

    function dump(nvlist_t nvl, uint16 f) internal returns (string res) {
        bool reusable = (f & 1) > 0;
        bool verbose = (f & 2) > 0;
        bool headers = (f & 4) > 0;
        bool list_info = (f & 8) > 0;
	    (, uint8 nvl_error, , uint32 nvl_datasize, string nvl_name, nvpair_t[] nvl_items, nvlist_header nvl_header) = nvl.unpack();
//        (uint8 nvlh_magic, uint8 nvlh_version, uint8 nvlh_flags, uint64 nvlh_descriptors, uint64 nvlh_size) = nvl_header.unpack();
        uint16 nitems = uint16(nvl_items.length);
        res = format("\nList {}, {} items, data size {}\n", nvl_name, nitems > 0 ? str.toa(nitems) : "no", nvl_datasize);
        if (nvl_error > 0)
            res.append("Error!" + str.toa(nvl_error) + '\n');
        string[][] table;
        if (list_info) {
            table = [["magic", "name", "error", "flags", "size", "N"]];
            table.push(nvlist_as_row(nvl));
            res.append(libtable.format_rows(table, [uint(3), 20, 6, 7, 7, 4], libtable.CENTER));
        }
        if (headers) {
            table = [["magic", "ver", "flags", "descriptors", "size"]];
            table.push(nvlist_header_as_row(nvl_header));
            res.append(libtable.format_rows(table, [uint(3), 1, 6, 11, 11], libtable.CENTER));
        }
        if (verbose) {
            s_table t = libtable.with_header(["magic", "name", "type", "size", "data"],
                [uint(3), 20, 13, 7, 50], libtable.CENTER);
            for (nvpair_t nvp: nvl_items)
                t.add_row(nvpair_as_row(nvp));
            res.append(t.compute());
        } else if (reusable) {
            for (nvpair_t nvp: nvl_items) {
                (, string nvp_name, uint8 nvp_type, string nvp_data, uint16 nvp_datasize, ) = nvp.unpack();
                res.append(nvp_name);
                if (nvp_type > NV_TYPE_NULL)
                    res.append('=');
                if (nvp_type >= NV_TYPE_BOOL_ARRAY)
                    res.append('(');
                if (nvp_type == NV_TYPE_BINARY)
                    res.append("<...> " + str.toa(nvp_datasize) + " bytes");
                else
                    res.append(nvp_data);
                if (nvp_type >= NV_TYPE_BOOL_ARRAY)
                    res.append(')');
                res.append('\n');
            }
        }
    }

    function nvlist_add_null(nvlist_t nvl, string name) internal {
        nvl.add(NV_TYPE_NULL, name, "", 0);
    }
    function nvlist_add_bool(nvlist_t nvl, string name, bool value) internal {
        nvl.add(NV_TYPE_BOOL, name, libnvpair.btoa(value), 0);
    }
    function nvlist_add_number(nvlist_t nvl, string name, uint16 value) internal {
        nvl.add(NV_TYPE_NUMBER, name, str.toa(value), 0);
    }
    function nvlist_add_string(nvlist_t nvl, string name, string value) internal {
        nvl.add(NV_TYPE_STRING, name, value, 0);
    }
    function nvlist_add_stringf(nvlist_t nvl, string name, string valuefmt) internal {}
    function nvlist_add_stringv(nvlist_t nvl, string name, string valuefmt) internal {}
    function nvlist_add_nvlist(nvlist_t nvl, string name, nvlist_t value) internal {
    }
    function nvlist_add_binary(nvlist_t nvl, string name, bytes value, uint16 size) internal {
        if (size == uint16(value.length))
            nvl.add(NV_TYPE_BINARY, name, value, 0);
    }
    function nvlist_add_bool_array(nvlist_t nvl, string name, bool[] value, uint16 nitems) internal {
        string res = libnvpair.btoa(value[0]);
        for (uint i = 0; i < nitems - 1; i++)
            res.append(" " + libnvpair.btoa(value[i - 1]));
        nvl.add(NV_TYPE_BOOL_ARRAY, name, res, nitems);
    }
    function nvlist_add_number_array(nvlist_t nvl, string name, uint16[] value, uint16 nitems) internal {
        string res = str.toa(value[0]);
        for (uint i = 0; i < nitems - 1; i++)
            res.append(" " + str.toa(value[i - 1]));
        nvl.add(NV_TYPE_NUMBER_ARRAY, name, res, nitems);
    }
    function nvlist_add_string_array(nvlist_t nvl, string name, string[] value, uint16 nitems) internal {
        nvl.add(NV_TYPE_STRING_ARRAY, name, libstring.join_fields(value, ' '), nitems);
    }
    function nvlist_add_nvlist_array(nvlist_t nvl, string name, nvlist_t[] value, uint16 nitems) internal {
    }
    function nvlist_add_descriptor(nvlist_t nvl, string name, uint8 value) internal {
        nvl.add(NV_TYPE_DESCRIPTOR, name, str.toa(value), 0);
    }
    function nvlist_add_descriptor_array(nvlist_t nvl, string name, uint8[] value, uint16 nitems) internal {
        string res = str.toa(value[0]);
        for (uint i = 0; i < nitems - 1; i++)
            res.append(" " + str.toa(value[i - 1]));
        nvl.add(NV_TYPE_DESCRIPTOR_ARRAY, name, res, nitems);
    }
    function nvlist_append_bool_array(nvlist_t nvl, string name, bool value) internal {
        nvl.append(NV_TYPE_BOOL, name, btoa(value));
//        nvl.table[name].value.bool_array_value.push(value);
    }
    function nvlist_append_number_array(nvlist_t nvl, string name, uint16 value) internal {
        nvl.append(NV_TYPE_NUMBER, name, str.toa(value));
//        nvl.table[name].value.number_array_value.push(value);
    }
    function nvlist_append_string_array(nvlist_t nvl, string name, string value) internal {
        nvl.append(NV_TYPE_STRING, name, value);
//        nvl.table[name].value.string_array_value.push(value);
    }
    function nvlist_append_nvlist_array(nvlist_t nvl, string name, nvlist_t value) internal {}
    function nvlist_append_descriptor_array(nvlist_t nvl, string name, uint8 value) internal {
        nvl.append(NV_TYPE_DESCRIPTOR, name, str.toa(value));
    }
    function nvlist_move_string(nvlist_t nvl, string name, string value) internal {}
    function nvlist_move_nvlist(nvlist_t nvl, string name, nvlist_t value) internal {}
    function nvlist_move_binary(nvlist_t nvl, string name, bytes value, uint16 size) internal {}
    function nvlist_move_bool_array(nvlist_t nvl, string name, bool[] value, uint16 nitems) internal {}
    function nvlist_move_string_array(nvlist_t nvl, string name, string[] value, uint16 nitems) internal {}
    function nvlist_move_nvlist_array(nvlist_t nvl, string name, nvlist_t[] value, uint16 nitems) internal {}
    function nvlist_move_number_array(nvlist_t nvl, string name, uint16[] value, uint16 nitems) internal {}
    function nvlist_move_descriptor(nvlist_t nvl, string name, int value) internal {}
    function nvlist_move_descriptor_array(nvlist_t nvl, string name, uint8[] value, uint16 nitems) internal {}
    function nvlist_get_bool(nvlist_t nvl, string name) internal returns (bool) {
        (bool success, string value, uint16 nitems) = get(nvl, name, NV_TYPE_BOOL);
        return success && nitems == 0 && value == "TRUE";
    }
    function nvlist_get_number(nvlist_t nvl, string name) internal returns (uint16) {
        (bool success, string value, uint16 nitems) = get(nvl, name, NV_TYPE_NUMBER);
        if (success && nitems == 0)
            return str.toi(value);
    }
    function nvlist_get_string(nvlist_t nvl, string name) internal returns (string) {
        (bool success, string value, uint16 nitems) = get(nvl, name, NV_TYPE_STRING);
        if (success && nitems == 0)
            return value;
    }
    function nvlist_get_nvlist(nvlist_t nvl, string name) internal returns (nvlist_t) {}
    function nvlist_get_binary(nvlist_t nvl, string name) internal returns (bytes, uint16) {
        (bool success, string value, uint16 nitems) = get(nvl, name, NV_TYPE_BINARY);
        if (success && nitems == 0)
            return (value, str.strlen(value));
    }
    function nvlist_get_bool_array(nvlist_t nvl, string name) internal returns (bool[] value, uint16 nitemsp) {
        (bool success, string svalue, uint16 nitems) = get(nvl, name, NV_TYPE_NUMBER_ARRAY);
        if (success) {
//        string res = get(nvl, name, NV_TYPE_BOOL_ARRAY);
            (string[] items, uint n_items) = libstring.split(svalue, ' ');
            if (n_items == nitems) {
                for (string s: items)
                    value.push(s == "TRUE");
                nitemsp = uint16(n_items);
            }
        }
    }
    function nvlist_get_number_array(nvlist_t nvl, string name) internal returns (uint16[] value, uint16 nitemsp) {
        (bool success, string svalue, uint16 nitems) = get(nvl, name, NV_TYPE_NUMBER_ARRAY);
        if (success) {
            (string[] items, uint n_items) = libstring.split(svalue, ' ');
            if (n_items == nitems) {
                for (string s: items)
                    value.push(str.toi(s));
                nitemsp = uint16(n_items);
            }
        }
        /*string res = get(nvl, name, NV_TYPE_NUMBER_ARRAY);
        (string[] items, uint n_items) = libstring.split(res, ' ');
        for (string s: items)
            value.push(str.toi(s));
        nitemsp = uint16(n_items);*/
    }
    function nvlist_get_string_array(nvlist_t nvl, string name) internal returns (string[] value, uint16 nitemsp) {
        (bool success, string svalue, uint16 nitems) = get(nvl, name, NV_TYPE_STRING_ARRAY);
        if (success) {
            (string[] items, uint n_items) = libstring.split(svalue, ' ');
            if (n_items == nitems) {
                for (string s: items)
                    value.push(s);
                nitemsp = uint16(n_items);
            }
        }
    }
    function nvlist_get_nvlist_array(nvlist_t nvl, string name) internal returns (nvlist_t[] value, uint16 nitemsp) {}
    function nvlist_get_descriptor(nvlist_t nvl, string name) internal returns (uint8) {
        (bool success, string value, uint16 nitems) = get(nvl, name, NV_TYPE_DESCRIPTOR);
        if (success && nitems == 0)
            return uint8(str.toi(value));
//        return uint8(str.toi(get(nvl, name, NV_TYPE_DESCRIPTOR)));
    }
    function nvlist_get_descriptor_array(nvlist_t nvl, string name) internal returns (uint8[] value, uint16 nitemsp) {}
    function nvlist_take_bool(nvlist_t nvl, string name) internal returns (bool) {}
    function nvlist_take_number(nvlist_t nvl, string name) internal returns (uint16) {}
    function nvlist_take_string(nvlist_t nvl, string name) internal returns (string ) {}
    function nvlist_take_nvlist(nvlist_t nvl, string name) internal returns (nvlist_t ) {}
    function nvlist_take_binary(nvlist_t nvl, string name, uint16 sizep) internal returns (bytes[]) {}
    function nvlist_take_bool_array(nvlist_t nvl, string name, uint16 nitemsp) internal returns (bool[]) {}
    function nvlist_take_number_array(nvlist_t nvl, string name, uint16 nitemsp) internal returns (uint16[]) {}
    function nvlist_take_string_array(nvlist_t nvl, string name, uint16 nitemsp) internal returns (string[]) {}
    function nvlist_take_nvlist_array(nvlist_t nvl, string name, uint16 nitemsp) internal returns (nvlist_t[] ) {}
    function nvlist_take_descriptor(nvlist_t nvl, string name) internal returns (uint8 ) {}
    function nvlist_take_descriptor_array(nvlist_t nvl, string name, uint16 nitemsp) internal returns (uint8[]	) {}
    function nvlist_free(nvlist_t nvl, string name) internal {
        nvl.free(name, NV_TYPE_NONE);
    }
    function nvlist_free_type(nvlist_t nvl, string name, uint8 ntype) internal {
        nvl.free(name, ntype);
    }
    function nvlist_free_null(nvlist_t nvl, string name) internal {}
    function nvlist_free_bool(nvlist_t nvl, string name) internal {}
    function nvlist_free_number(nvlist_t nvl, string name) internal {}
    function nvlist_free_string(nvlist_t nvl, string name) internal {}
    function nvlist_free_nvlist(nvlist_t nvl, string name) internal {}
    function nvlist_free_binary(nvlist_t nvl, string name) internal {}
    function nvlist_free_bool_array(nvlist_t nvl, string name) internal {}
    function nvlist_free_number_array(nvlist_t nvl, string name) internal {}
    function nvlist_free_string_array(nvlist_t nvl, string name) internal {}
    function nvlist_free_nvlist_array(nvlist_t nvl, string name) internal {}
    function nvlist_free_binary_array(nvlist_t nvl, string name) internal {}
    function nvlist_free_descriptor(nvlist_t nvl, string name) internal {}
    function nvlist_free_descriptor_array(nvlist_t nvl, string name) internal {}

    function nvlist_update_size(nvlist_t nvl, nvpair_t pnew, uint32 mul) internal {
        uint32 size;
        uint16 nitems;
        nvlist_t nvlistnew;
        nvlist_t[] nvlarray;
        nvlist_t parent;
        uint ii;
//      NVLIST_ASSERT(nvl);
//      NVPAIR_ASSERT(new);
//      PJDLOG_ASSERT(mul == 1 || mul == -1);
        size = libnvpair.nvpair_header_size();
        size += str.strlen(libnvpair.nvpair_name(pnew)) + 1;
        if (libnvpair.nvpair_type(pnew) == NV_TYPE_NVLIST) {
            nvlistnew = libnvpair.nvpair_get_nvlist(pnew);
            size += nvlistnew.nvl_datasize;
            size += libnvpair.nvpair_header_size() + 1;
        } else if (libnvpair.nvpair_type(pnew) == NV_TYPE_NVLIST_ARRAY) {
            (nvlarray, nitems) = libnvpair.nvpair_get_nvlist_array(pnew);
//       	PJDLOG_ASSERT(nitems > 0);
            size += (libnvpair.nvpair_header_size() + 1) * nitems;
            for (ii = 0; ii < nitems; ii++) {
//    	PJDLOG_ASSERT(nvlarray[ii].nvl_error == 0);
                size += nvlarray[ii].nvl_datasize;
            }
        } else {
            size += libnvpair.nvpair_size(pnew);
        }
        size *= mul;
        nvl.nvl_datasize += size;
        parent = nvl;
        /*while ((parent = __DECONST(nvlist_t *,
            nvlist_get_parent(parent, NULL))) != NULL) {
            parent->nvl_datasize += size;
        }*/
    }

    function nvlist_move_nvpair(nvlist_t nvl, nvpair_t nvp) internal returns (bool) {
//      NVPAIR_ASSERT(nvp);
//      PJDLOG_ASSERT(nvpair_nvlist(nvp) == NULL);
        if (nvlist_error(nvl) > 0) {
            nvp.nvpair_free();
//          	ERRNO_SET(nvlist_error(nvl));
            return false;
        }
        if ((nvl.nvl_flags & NV_FLAG_NO_UNIQUE) == 0) {
            if (nvlist_exists(nvl, nvp.nvp_name)) {
                nvp.nvpair_free();
                nvl.nvl_error = EEXIST;
//              ERRNO_SET(nvl->nvl_error);
                return false;
            }
        }
        nvl.nvl_items.push(nvp);
        nvl.nvlist_update_size(nvp, 1);
        return true;
    }

    function nvlist_add_nvpair(nvlist_t nvl, nvpair_t nvp) internal {
//    	NVPAIR_ASSERT(nvp);
        if (nvl.nvl_error > 0) {
    //  ERRNO_SET(nvlist_error(nvl));
            return;
    	}
        if ((nvl.nvl_flags & NV_FLAG_NO_UNIQUE) == 0) {
            if (nvlist_exists(nvl, nvp.nvp_name)) {
                nvl.nvl_error = EEXIST;
  //    	    ERRNO_SET(nvlist_error(nvl));
                return;
        	}
        }
        nvpair_t newnvp = libnvpair.nvpair_clone(nvp);
        nvl.nvlist_update_size(newnvp, 1);
//      if (newnvp == 0) {
//          nvl.nvl_error = err.ENOMEM;//ERRNO_OR_DEFAULT(err.ENOMEM);
//          ERRNO_SET(nvlist_error(nvl));
//          return;
//      }
//    	nvpair_insert(nvl->nvl_head, newnvp, nvl);
    }

}
/*library libnlist {
    // Defines for n_type.
    uint8 constant N_UNDF	= 0x00;	// undefined
    uint8 constant N_ABS	= 0x02;	// absolute address
    uint8 constant N_TEXT	= 0x04;	// text segment
    uint8 constant N_DATA	= 0x06;	// data segment
    uint8 constant N_BSS	= 0x08;	// bss segment
    uint8 constant N_INDR	= 0x0a;	// alias definition
    uint8 constant N_SIZE	= 0x0c;	// pseudo type, defines a symbol's size
    uint8 constant N_COMM	= 0x12;	// common reference
    uint8 constant N_SETA	= 0x14;	// Absolute set element symbol
    uint8 constant N_SETT   = 0x16;	// Text set element symbol
    uint8 constant N_SETD   = 0x18;	// Data set element symbol
    uint8 constant N_SETB   = 0x1a;	// Bss set element symbol
    uint8 constant N_SETV   = 0x1c;	// Pointer to set vector in data area.
    uint8 constant N_FN	    = 0x1e;	// file name (N_EXT on)
    uint8 constant N_WARN	= 0x1e;	// warning message (N_EXT off)
    uint8 constant N_EXT	= 0x01;	// external (global) bit, OR'ed in
    uint8 constant N_TYPE	= 0x1e;	// mask for all the type bits
    uint8 constant N_STAB	= 0xe0;	// mask for debugger symbols -- stab(5)
    uint8 constant AUX_OBJECT  = 1;	// data object
    uint8 constant AUX_FUNC	   = 2;	// function
    uint8 constant BIND_LOCAL  = 0;	// not used
    uint8 constant BIND_GLOBAL = 1;	// not used
    uint8 constant BIND_WEAK   = 2;	// weak binding
    string constant	N_FORMAT   = "%08x";	// namelist value format

    function add(nlist[] nl, uint8 n_type, uint8 n_other, uint8 n_desc, string[] names, uint32[] values) internal {
        for (uint i = 0; i < names.length; i++) {
            nl.push(nlist(names[i], n_type, n_other, n_desc, values[i]));
        }
    }
    function dump(nlist[] nl) internal returns (string) {
        string[][] table = [["name", "typedef", "typeinf", "desc", "val"]];
        for (nlist n: nl)
            table.push(as_row(n));
        return libtable.format_rows(table, [uint(20), 6, 6, 6, 20], libtable.CENTER);
    }
    function as_row(nlist nl) internal returns (string[]) {
        (string n_name, uint8 n_type, uint8 n_other, uint8 n_desc, uint32 n_value) = nl.unpack();
        return [n_name, str.toa(n_type), str.toa(n_other), str.toa(n_desc), str.toa(n_value)];
    }
}*/