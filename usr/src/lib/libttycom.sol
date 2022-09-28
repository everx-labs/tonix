pragma ton-solidity >= 0.64.0;

library libttycom {
// Tty ioctl's except for those supported only for backwards compatibility with the old tty driver.

    uint8 constant TIOCEXCL =	13;	/* set exclusive use of tty */
    uint8 constant TIOCNXCL =	14;	/* reset exclusive use of tty */
    uint8 constant TIOCGPTN =	15; /* Get pts number. */
    uint8 constant TIOCFLUSH =	16; /* flush buffers */
    uint8 constant TIOCGETA =	19; /* get termios struct */
    uint8 constant TIOCSETA =	20; /* set termios struct */
    uint8 constant TIOCSETAW =	21; /* drain output, set */
    uint8 constant TIOCSETAF =	22; /* drn out, fls in, set */
    uint8 constant TIOCGETD =	26; /* get line discipline */
    uint8 constant TIOCSETD =	27; /* set line discipline */
    uint8 constant TIOCPTMASTER =	28;	/* pts master validation */
    uint8 constant TIOCGDRAINWAIT =	86; /* get ttywait timeout */
    uint8 constant TIOCSDRAINWAIT =	87; /* set ttywait timeout */
    uint8 constant TIOCTIMESTAMP =	89; /* enable/get timestamp */
    uint8 constant TIOCMGDTRWAIT =	90; /* modem: get wait on close */
    uint8 constant TIOCMSDTRWAIT =	91; /* modem: set wait on close */
    uint8 constant TIOCDRAIN =	    94; //)		/* wait till output drained */
    uint8 constant TIOCSIG =	    95; //)	/* pty: generate signal */
    uint8 constant TIOCEXT =	    96; //, int)	/* pty: external processing */
    uint8 constant TIOCSCTTY =	    97;//)		/* become controlling tty */
    uint8 constant TIOCCONS =	    98;//, int)	/* become virtual console */
    uint8 constant TIOCGSID =	    99;//, int)	/* get session id */
    uint8 constant TIOCSTAT =	    101;/* simulate ^T status message */
    uint8 constant TIOCUCNTL =	    102;/* pty: set/clr usr cntl mode */
//    uint8 constant 	UIOCCMD =(;n)	_IO('u', n)	/* usr cntl op "n" */
    uint8 constant TIOCSWINSZ =	103; /* set window size */
    uint8 constant TIOCGWINSZ =	104; /* get window size */
    uint8 constant TIOCMGET =	106;	/* get all modem bits */

    uint16 constant	TIOCM_LE =	0x001;		/* line enable */
    uint16 constant	TIOCM_DTR =	0x002;		/* data terminal ready */
    uint16 constant	TIOCM_RTS =	0x004;		/* request to send */
    uint16 constant	TIOCM_ST =	0x008;		/* secondary transmit */
    uint16 constant	TIOCM_SR =	0x010;		/* secondary receive */
    uint16 constant	TIOCM_CTS =	0x020;		/* clear to send */
    uint16 constant	TIOCM_DCD =	0x040;		/* data carrier detect */
    uint16 constant	TIOCM_RI =	0x080;		/* ring indicate */
    uint16 constant	TIOCM_DSR =	0x100;		/* data set ready */
    uint16 constant	TIOCM_CD =	TIOCM_DCD;
    uint16 constant	TIOCM_CAR =	TIOCM_DCD;
    uint16 constant	TIOCM_RNG =	TIOCM_RI;

    uint8 constant TIOCMBIC =	107;	/* bic modem bits */
    uint8 constant TIOCMBIS =	108;	/* bis modem bits */
    uint8 constant TIOCMSET =	109;	/* set all modem bits */
    uint8 constant TIOCSTART =	110;	/* start output, like ^Q */
    uint8 constant TIOCSTOP =	111;	/* stop output, like ^S */
    uint8 constant TIOCPKT =	112; /* pty: set/clear packet mode */

    uint8 constant 	TIOCPKT_DATA =		0x00;	/* data packet */
    uint8 constant 	TIOCPKT_FLUSHREAD =	0x01;	/* flush packet */
    uint8 constant 	TIOCPKT_FLUSHWRITE =	0x02;	/* flush packet */
    uint8 constant 	TIOCPKT_STOP =		0x04;	/* stop output */
    uint8 constant 	TIOCPKT_START =		0x08;	/* start output */
    uint8 constant 	TIOCPKT_NOSTOP =		0x10;	/* no more ^S, ^Q */
    uint8 constant 	TIOCPKT_DOSTOP =		0x20;	/* now do ^S ^Q */
    uint8 constant 	TIOCPKT_IOCTL =		0x40;	/* state change of pty driver */

    uint8 constant TIOCNOTTY =	113;// )		/* void tty association */
    uint8 constant TIOCSTI =	114;// , char)	/* simulate terminal input */
    uint8 constant TIOCOUTQ =	115;// , int)	/* output queue size */
    uint8 constant TIOCSPGRP =	118;// , int)	/* set pgrp of tty */
    uint8 constant TIOCGPGRP =	119;// , int)	/* get pgrp of tty */
    uint8 constant TIOCCDTR =	120;// )		/* clear data terminal ready */
    uint8 constant TIOCSDTR =	121;// )		/* set data terminal ready */
    uint8 constant TIOCCBRK =	122;// )		/* clear break bit */
    uint8 constant TIOCSBRK =	123;// )		/* set break bit */

    uint8 constant TTYDISC =		0;		/* termios tty line discipline */
    uint8 constant SLIPDISC =	4;		/* serial IP discipline */
    uint8 constant PPPDISC =		5;		/* PPP discipline */
    uint8 constant NETGRAPHDISC =	6;		/* Netgraph tty node discipline */
    uint8 constant H4DISC =		7;		/* Netgraph Bluetooth H4 discipline */
}