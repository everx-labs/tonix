pragma ton-solidity >= 0.64.0;

import "input.sol";
//* Access unaligned data items on aligned (longword) boundaries.
contract access is input {
    // table for sign-extending
    uint32[] db_extend = [0, 0xFFFFFF80, 0xFFFF8000, 0xFF800000 ];

    function db_get_value(uint32 addr, uint8 size, bool is_signed) internal returns (uint8) {
    	bytes data;//[sizeof(uint64_t)];
    	uint8	value;
    	if (db_read_bytes(addr, size, data) != 0) {
    		db_printf("*** error reading from address %llx ***\n", addr);
//    		kdb_reenter();
    	}
    	value = 0;
//    #if _BYTE_ORDER == _BIG_ENDIAN
    	for (uint i = 0; i < size; i++)
//    #else	/* _LITTLE_ENDIAN */
//    	for (i = size - 1; i >= 0; i--)
//    #endif
    	    value = (value << 8) + (data[i] & 0xFF);

    	if (size < 4) {
    	    if (is_signed && (value & db_extend[size]) != 0)
    		    value |= db_extend[size];
    	}
    	return value;
    }

    function db_put_value(uint32 addr, uint8 size, uint8 value) internal {
    	bytes		data;//[sizeof(int)];
//    #if _BYTE_ORDER == _BIG_ENDIAN
    	for (uint i = size - 1; i >= 0; i--)
//    #else	/* _LITTLE_ENDIAN */
//    	for (i = 0; i < size; i++)
//    #endif
    	{
    	    data[i] = value & 0xFF;
    	    value >>= 8;
    	}
    	if (db_write_bytes(addr, size, data) != 0) {
    		db_printf("*** error writing to address %llx ***\n", addr);
//    		kdb_reenter();
    	}
    }

    // Read bytes from kernel address space for debugger.
    function db_read_bytes(uint8 addr, uint8 size) internal returns (uint8 ret, bytes data) {
//    	const char *src;
//    	jmp_buf prev_jb = kdb_jmpbuf(jb);
//    	ret = setjmp(jb);
    	if (ret == 0) {
    		bytes src;// = addr;
//    		while (size-- > 0)
            data = src;
//    			data.append(src;
    	}
//    	kdb_jmpbuf(prev_jb);
    }

    // Write bytes to kernel address space for debugger.
    function db_write_bytes(uint8 addr, uint8 size, bytes data) internal returns (uint8 ret) {
//    	char *dst;
//    	jmp_buf prev_jb = kdb_jmpbuf(jb);
//    	ret = setjmp(jb);
    	if (ret == 0) {
    		bytes dst;// = (char *)addr;
//    		while (size-- > 0)
//    			*dst++ = *data++;
            dst = data;
    	}
//    	kdb_jmpbuf(prev_jb);
    }

}
