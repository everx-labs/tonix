pragma ton-solidity >= 0.64.0;
import "cons_h.sol";
import "tty_h.sol";
import "libboot.sol";
contract kern_cons {

    // values for cn_pri - reflect our policy for console selection
    uint8 constant CN_DEAD		= 0;	// device doesn't exist
    uint8 constant CN_LOW		= 1;	// device is a last restort only
    uint8 constant CN_NORMAL	= 2;	// device exists but is nothing special
    uint8 constant CN_INTERNAL	= 3;	// "internal" bit-mapped display
    uint8 constant CN_REMOTE	= 4;	// serial interface with remote bit set

    // Values for cn_flags
    uint8 constant CN_FLAG_NODEBUG = 0x00000001;	// Not supported with debugger.
    uint8 constant CN_FLAG_NOAVAIL = 0x00000002;	// Temporarily not available.

    // Visibility of characters in cngets()
    uint8 constant GETS_NOECHO	= 0;	    // Disable echoing of characters
    uint8 constant GETS_ECHO	= 1;	    // Enable echoing of characters
    uint8 constant GETS_ECHOPASS	= 2;	// Print a * for every character

    uint8 constant CNDEVPATHMAX =	32;
    uint8 constant CNDEVTAB_SIZE =	4;
    s_cn_device[CNDEVTAB_SIZE] cn_devtab;
    //uint32[CNDEVTAB_SIZE] cn_devtab;
    s_cn_device[] cn_devlist;
//    uint32[] cn_devlist;
    uint32 cons_avail_mask = 0;	// Bit mask. Each registered low level console which is currently unavailable for inpit (i.e., if it is in graphics mode) will have this bit cleared.

    s_consdev cons_consdev;
//    s_consdev[] cons_set;
    bool kdb_active;
    uint32[] cons_set;

    uint32 boothowto;
    mapping (uint32 => TvmCell) _mem;
    bool cn_mute;
    bytes consbuf;			// buffer used by `consmsgbuf'
//    s_callout conscallout;	// callout for outputting to constty
//    s_msgbuf consmsgbuf;	// message buffer for console tty
    bool console_pausing;	// pause after each line during probe
    string constant console_pausestr = "<pause; press any key to proceed to next line or '.' to end pause mode>";
    uint32 constty;	// s_tty	// pointer to console "window" tty
    uint32 constant NULL = 0;
    function cninit() internal {
	    s_consdev best_cn;
        s_consdev cn;
//        s_consdev[] list;
	    // Check if we should mute the console (for security reasons perhaps) It can be changes dynamically using sysctl kern.consmute
	    // once we are up and going.
        cn_mute = ((boothowto & (libboot.RB_MUTE |libboot.RB_SINGLE |libboot.RB_VERBOSE |libboot.RB_ASKNAME)) == libboot.RB_MUTE);
    	// Bring up the kbd layer just in time for cnprobe.  Console drivers have a dependency on kbd being ready, so this fits nicely between the
    	// machdep callers of cninit() and MI probing/initialization of consoles here.
//	    kbdinit();
	    // Find the first console with the highest priority.

//	    SET_FOREACH(list, cons_set) {
        for (uint32 p: cons_set) {
            cn = _mem[p].toSlice().decode(s_consdev);
	    	cnremove(cn);
	    	// Skip cons_consdev
	    	//if (cn.cn_ops == NULL)
	    	//	continue;
	    	cn.cn_ops.cn_probe(cn);
	    	if (cn.cn_pri == CN_DEAD)
	    		continue;
	    	if (best_cn.cn_name.empty() || cn.cn_pri > best_cn.cn_pri)
	    		best_cn = cn;
	    	if ((boothowto & libboot.RB_MULTIPLE) > 0) {
	    		// Initialize console, and attach to it.
	    		cn.cn_ops.cn_init(cn);
	    		cnadd(cn);
	    	}
	    }
	    if (best_cn.cn_name.empty())
	    	return;
	    if ((boothowto & libboot.RB_MULTIPLE) == 0) {
	    	best_cn.cn_ops.cn_init(best_cn);
	    	cnadd(best_cn);
	    }
//	    if (boothowto & RB_PAUSE)
//	    	console_pausing = true;
	    // Make the best console the preferred console.
	    cnselect(best_cn);
    }
    function cninit_finish() internal {
	    console_pausing = false;
    }
    function cnadd(s_consdev cn) internal returns (uint8) {
        s_cn_device cnd;
        for (s_cn_device cndd: cn_devlist)
	    	if (cndd.cnd_cn.cn_name == cn.cn_name)
	    		return 0;
	    for (uint i = 0; i < CNDEVTAB_SIZE; i++) {
	    	cnd = cn_devtab[i];
	    	if (cnd.cnd_cn.cn_name.empty())
	    		break;
	    }
//	    if (cnd.cnd_cn != NULL)
//	    	return ENOMEM;
	    cnd.cnd_cn = cn;
	    if (cn.cn_name.substr(0, 1) == '\x00') {
	    	/* XXX: it is unclear if/where this print might output */
//	    	printf("WARNING: console at %p has no name\n", cn);
	    }
        cn_devlist.push(cnd);
	    //STAILQ_INSERT_TAIL(&cn_devlist, cnd, cnd_next);
//        if (cn_devlist.length == 1)
//            ttyconsdev_select(cnd.cnd_cn.cn_name);
	    //if (STAILQ_FIRST(&cn_devlist) == cnd)
	    	//ttyconsdev_select(cnd.cnd_cn.cn_name);
    	// Add device to the active mask
	    cnavailable(cn, (cn.cn_flags & CN_FLAG_NOAVAIL) == 0);
	    return 0;
    }
    function cnavailable(s_consdev cn, bool available) internal {
    	uint i;
    	for (i = 0; i < CNDEVTAB_SIZE; i++) {
    		if (cn_devtab[i].cnd_cn.cn_name == cn.cn_name)
    			break;
    	}
    	if (available) {
    		if (i < CNDEVTAB_SIZE)
    			cons_avail_mask |= uint32(1 << i);
    		cn.cn_flags &= ~CN_FLAG_NOAVAIL;
    	} else {
    		if (i < CNDEVTAB_SIZE)
    			cons_avail_mask &= uint32(~(1 << i));
    		cn.cn_flags |= CN_FLAG_NOAVAIL;
    	}
    }
    function cnremove(s_consdev cn) internal {
        for (s_cn_device cnd: cn_devlist) {
    		if (cnd.cnd_cn.cn_name != cn.cn_name)
    			continue;
//            if (cn_devlist.length == 1)
//                ttyconsdev_select(0);
//    		if (STAILQ_FIRST(&cn_devlist) == cnd)
//    			ttyconsdev_select(NULL);
            delete cnd;
//    		STAILQ_REMOVE(&cn_devlist, cnd, cn_device, cnd_next);
    		delete cnd.cnd_cn;// = NULL;
    		// Remove this device from available mask.
    		for (uint i = 0; i < CNDEVTAB_SIZE; i++)
    			if (cn.cn_name == cn_devtab[i].cnd_cn.cn_name) {
    				cons_avail_mask &= uint32(~(1 << i));
    				break;
    			}
	    }

    }
    function cnselect(s_consdev cn) internal view {
        for (s_cn_device cnd: cn_devlist) {
		    if (cnd.cnd_cn.cn_name != cn.cn_name)
		    	continue;
		    if (cnd.cnd_cn.cn_name == cn_devlist[0].cnd_cn.cn_name)
		    	return;
//		    STAILQ_REMOVE(&cn_devlist, cnd, cn_device, cnd_next);
//		    STAILQ_INSERT_HEAD(&cn_devlist, cnd, cnd_next);
//		    ttyconsdev_select(cnd.cnd_cn.cn_name);
		    return;
	    }

    }
    function cngrab() internal {
        for (s_cn_device cnd: cn_devlist) {
    		s_consdev cn = cnd.cnd_cn;
    		if (!kdb_active || (cn.cn_flags & CN_FLAG_NODEBUG) == 0)
    			cn.cn_ops.cn_grab(cn);
    	}
    }
    function cnungrab() internal {
        for (s_cn_device cnd: cn_devlist) {
    		s_consdev cn = cnd.cnd_cn;
    		if (!kdb_active || (cn.cn_flags & CN_FLAG_NODEBUG) == 0)
    			cn.cn_ops.cn_ungrab(cn);
    	}
    }
    function cnresume() internal {
        for (s_cn_device cnd: cn_devlist) {
    		s_consdev cn = cnd.cnd_cn;
//    		if (cn.cn_ops.cn_resume != NULL)
    			cn.cn_ops.cn_resume(cn);
    	}
    }
    function cncheckc() internal returns (byte c) {
    	if (cn_mute)
    		return 0xFF;
        for (s_cn_device cnd: cn_devlist) {
    		s_consdev cn = cnd.cnd_cn;
    		if (!kdb_active || (cn.cn_flags & CN_FLAG_NODEBUG) == 0) {
    			c = cn.cn_ops.cn_getc(cn);
    			if (c != 0xFF)
    				return c;
    		}
    	}
    	return 0xFF;
    }
    function cngetc() internal returns (byte c) {
    	if (cn_mute)
    		return 0xFF;
    	while ((c = cncheckc()) == 0xFF) {}
//    		cpu_spinwait();
    	if (c == '\r')
    		c = '\n';		/* console input is always ICRNL */
    }
    function cngets(uint16 size, uint8 visible) internal returns (bytes res) {
	    uint16 lp;
        uint16 end;
	    byte c;
	    cngrab();
	    lp = 0;
	    end = size - 1;
	    for (;;) {
	    	c = cngetc() & 0x7F;
	    	if (c == '\n' || c == '\r') {
	    		cnputc(c);
	    		res.append(bytes('\x00'));
	    		cnungrab();
	    		return res;
            } else if (c == '\b' || c == 0x7F) {
	    		if (lp > 0) {
	    			if (visible > 0)
	    				cnputs("\b \b");
	    			lp--;
	    		}
	    		continue;
            } else if (c == 0x00)
	    		continue;
	    	else
	    		if (lp < end) {
	    		    if (visible == GETS_NOECHO) {
                    } else if (visible == GETS_ECHOPASS)
	    				cnputc('*');
                    else
	    				cnputc(c);
                    res.append(bytes(c));
	    			lp++;
	    		}
    	}
    }

    function cnputc(byte c) internal {
	    if (cn_mute || c == 0x00)
	    	return;
        for (s_cn_device cnd: cn_devlist) {
	    	s_consdev cn = cnd.cnd_cn;
	    	if (!kdb_active || (cn.cn_flags & CN_FLAG_NODEBUG) == 0) {
	    		if (c == '\n')
	    			cn.cn_ops.cn_putc(cn, '\r');
	    		cn.cn_ops.cn_putc(cn, c);
	    	}
	    }
	    if (console_pausing && c == '\n' && !kdb_active) {
//	    	for (cp = console_pausestr; *cp != '\0'; cp++)
            for (byte b: console_pausestr)
                if (b == 0)
                    break;
                else
	    		    cnputc(b);
	    	cngrab();
	    	if (cngetc() == '.')
	    		console_pausing = false;
	    	cnungrab();
	    	cnputc('\r');
//	    	for (cp = console_pausestr; *cp != '\0'; cp++)
//	    		cnputc(' ');
            for (byte b: console_pausestr)
                if (b == 0)
                    break;
                else
	    		    cnputc(b);
	    	cnputc('\r');
	    }

    }
    function cnputs(bytes p) internal {
	    cnputsn(p, uint16(p.length));
    }
    function cnputsn(bytes p, uint16 n) internal {
//    	bool unlock_reqd = false;
    	for (uint i = 0; i < n; i++)
    		cnputc(p[i]);
    }
    function cnunavailable() internal view returns (bool) {
	    return cons_avail_mask == 0;
    }
//    function constty_set(s_tty tp) internal returns (uint8) {
//	    int size = consmsgbuf_size;
//	    void *buf = NULL;
//	    if (constty == tp)
//	    	return 0;
//	    if (constty != NULL)
//	    	return EBUSY;
//
//	    if (consbuf == NULL) {
////	    	buf = malloc(size, M_TTYCONS, M_WAITOK);
//	    }
//	    if (constty != NULL) {
////	    	free(buf, M_TTYCONS);
//	    	return EBUSY;
//	    }
//	    if (consbuf == NULL) {
//	    	consbuf = buf;
//	    	msgbuf_init(consmsgbuf, buf, size);
//	    } //else
//	    //	free(buf, M_TTYCONS);
//	    constty = tp;
////	    constty_timeout(tp);
//	    return 0;
//    }
//    function constty_clear(s_tty tp) internal returns (uint8) {
//	    byte c;
//	    if (constty != tp)
//	    	return ENXIO;
////	    callout_stop(&conscallout);
////	    constty = NULL;
////	    while ((c = msgbuf_getchar(consmsgbuf)) != -1)
//	    	cnputc(c);
	    // We never free consbuf because it can still be in use
//	    return 0;
//    }

    /*static void constty_timeout(void *arg) {
    	s_tty *tp = arg;
    	int c;
    	while ((c = msgbuf_getchar(&consmsgbuf)) != -1) {
    		if (tty_putchar(tp, c) < 0) {
    			constty_clear(tp);
    			return;
    		}
    	}
    	//callout_reset_sbt(conscallout, SBT_1S / constty_wakeups_per_second, 0, constty_timeout, tp, C_PREL(1));
    }*/

}