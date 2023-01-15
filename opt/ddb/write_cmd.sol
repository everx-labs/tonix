contract write_cmd {
    function db_write_cmd(uint32 eaddress, bool have_addr, uint8 count, byte modif) internal {
    	uint8 size;
    	bool wrote_one = false;
    	uint32 addr = eaddress;
        byte c = modif[0];
    	if (c == 'b')
            size = 1;
    	else if (c == 'h')
            size = 2;
    	else if (c == 'l' || c == '\0x00')
            size = 4;
        else {
    	    db_error("Unknown size\n");
    		return;
        }
        (bool f, uint8 new_value) = db_expression();
        while (f) {
    	    uint8 old_value = db_get_value(addr, size, false);
    	    db_printsym(addr, DB_STGY_ANY);
    	    db_printf("\t\t%#8lr\t=\t%#8lr\n", old_value, new_value);
    	    db_put_value(addr, size, new_value);
    	    addr += size;
    	    wrote_one = true;
            (f, new_value) = db_expression();
    	}
    	if (!wrote_one)
    	    db_error("Nothing written.\n");
    	db_next = addr;
    	db_prev = addr - size;
    	db_skip_to_eol();
    }
}