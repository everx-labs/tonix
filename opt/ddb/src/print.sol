pragma ton-solidity >= 0.64.0;
import "lex.h";
import "lstr.sol";
struct dbputchar_arg {
	uint8 da_nbufr;
	uint8 da_remain;
    uint da_pbufr;
	byte da_pnext;
}
contract print is lex_const, lstr {
    bool ddb_use_printf = false;
    //SYSCTL_INT(_debug, OID_AUTO, ddb_use_printf, CTLFLAG_RW, ddb_use_printf, 0, "use printf for all ddb output");
    uint8 db_radix;
    uint8 db_indent;
    bytes out;

    function printf(string fmt, string arg) internal returns (uint8) {
        return _printf(fmt, [arg]);
    }
    function printf(string fmt, byte c) internal returns (uint8) {
        return _printf(fmt, [bytes(c)]);
    }
    function db_printf(string fmt) internal returns (uint8) {
        string[] empty;
        return _printf(fmt, empty);
    }
    function db_printf(string fmt, string arg) internal returns (uint8) {
        return _printf(fmt, [arg]);
    }
    function db_printf(string fmt, bytes8 arg) internal returns (uint8) {
        return _printf(fmt, [null_term(bytes(arg))]);
    }
    function db_printf(string fmt, string arg1, string arg2) internal returns (uint8) {
        return _printf(fmt, [arg1, arg2]);
    }
    function db_printf(string fmt, uint arg) internal returns (uint8) {
        return _printf(fmt, [toa(arg)]);
    }
    function db_printf(string fmt, uint arg1, uint arg2) internal returns (uint8) {
        return _printf(fmt, [toa(arg1), toa(arg2)]);
    }
    function db_printf(string fmt, uint arg1, uint arg2, uint arg3) internal returns (uint8) {
        return _printf(fmt, [toa(arg1), toa(arg2), toa(arg3)]);
    }
    function _printf(string fmt, string[] args) internal returns (uint8) {
    	dbputchar_arg dca;
//    	va_list	listp;
    	uint8 retval;
//    	dca.da_pbufr = 0;
//        TvmBuilder b;
	    //dca.da_pbufr = b;
	    //dca.da_pnext = t0;
	    //dca.da_nbufr = _sizeof(b);
	    //dca.da_remain = _sizeof(b);
//	    *dca.da_pnext = '\0';
//        va_start(listp, fmt);
//    	retval = kvprintf (fmt, db_putchar, dca, db_radix, listp);
    	retval = kvprintf(fmt, 0, dca, db_radix, args);
//    	va_end(listp);
    	return retval;
    }
    /*function kvprintf(string fmt, uint32 fn, dbputchar_arg dca, uint8 radix, va_list listp) internal returns (uint8) {
        for (string s: args) {
            out.append(translate(fmt, "%s", s));
        }
    }*/
    function kvprintf(string fmt, uint32 , dbputchar_arg , uint8 , string[] args) internal returns (uint8) {
        for (string s: args) {
            out.append(translate(fmt, "%s", s));
        }
    }
    function db_iprintf(string ) internal {
//    	dbputchar_arg dca;
    	uint i;
//    	va_list listp;
    	for (i = db_indent; i >= 8; i -= 8)
    		db_printf("\t");
    	while (--i >= 0)
    		db_printf(" ");
//    	dca.da_pbufr = 0;
//    	va_start(listp, fmt);
//    	kvprintf (fmt, db_putchar, dca, db_radix, listp);
//    	va_end(listp);
    }
}