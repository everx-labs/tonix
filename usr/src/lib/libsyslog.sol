library libsyslog {

#define	_PATH_LOG	"/var/run/log"
#define	_PATH_LOG_PRIV	"/var/run/logpriv"

// priorities/facilities are encoded into a single 32-bit quantity, where the bottom 3 bits are the priority (0-7) and the top 28 bits are the facility
// (0-big number).  Both the priorities and the facilities map roughly one-to-one to strings in the syslogd(8) source code.  This mapping is
// included in this file.
    uint8 constant LOG_EMERG	= 0; // system is unusable
    uint8 constant LOG_ALERT	= 1; // action must be taken immediately
    uint8 constant LOG_CRIT	    = 2; // critical conditions
    uint8 constant LOG_ERR	    = 3; // error conditions
    uint8 constant LOG_WARNING	= 4; // warning conditions
    uint8 constant LOG_NOTICE	= 5; // normal but significant condition
    uint8 constant LOG_INFO	    = 6; // informational
    uint8 constant LOG_DEBUG	= 7; // debug-level messages
    uint8 constant LOG_PRIMASK = 0x07;	// mask to extract priority part (internal)
    uint8 constant INTERNAL_NOPRI =	0x10; /* the "no priority" priority */
//#define	LOG_PRI(p)	((p) & LOG_PRIMASK) 				/* extract priority */
//#define	LOG_MAKEPRI(fac, pri)	((fac) | (pri))
//#define	INTERNAL_MARK	LOG_MAKEPRI((LOG_NFACILITIES<<3), 0) 				/* mark "facility" */
struct _code {
    string c_name;
    uint8 c_val;
}

static const CODE prioritynames[] = {
	{ "alert",	LOG_ALERT,	},
	{ "crit",	LOG_CRIT,	},
	{ "debug",	LOG_DEBUG,	},
	{ "emerg",	LOG_EMERG,	},
	{ "err",	LOG_ERR,	},
	{ "error",	LOG_ERR,	},
	{ "info",	LOG_INFO,	},
	{ "none",	INTERNAL_NOPRI,	},
	{ "notice",	LOG_NOTICE,	},
	{ "panic", 	LOG_EMERG,	},
	{ "warn",	LOG_WARNING,	},
	{ "warning",	LOG_WARNING,	},
	{ NULL,		-1,		}
};

    /* facility codes */
    // Facility #10 clashes in DEC UNIX, where it's defined as LOG_MEGASAFE for AdvFS event logging.                          */
    uint32 LOG_KERN     = uint32(0) << 3;	// kernel messages
    uint32 LOG_USER     = uint32(1) << 3;	// random user-level messages
    uint32 LOG_MAIL     = uint32(2) << 3;	// mail system
    uint32 LOG_DAEMON   = uint32(3) << 3;	// system daemons
    uint32 LOG_AUTH     = uint32(4) << 3;	// authorization messages
    uint32 LOG_SYSLOG   = uint32(5) << 3;	// messages generated internally by syslogd
    uint32 LOG_LPR      = uint32(6) << 3;   // line printer subsystem
    uint32 LOG_NEWS     = uint32(7) << 3;	// network news subsystem
    uint32 LOG_UUCP     = uint32(8) << 3;	// UUCP subsystem
    uint32 LOG_CRON     = uint32(9) << 3;	// clock daemon
    uint32 LOG_AUTHPRIV = uint32(10) << 3;	// authorization messages (private)
    uint32 LOG_FTP      = uint32(11) << 3;	// ftp daemon
    uint32 LOG_NTP      = uint32(12) << 3;	// NTP subsystem
    uint32 LOG_SECURITY = uint32(13) << 3; // security subsystems (firewalling, etc.)
    uint32 LOG_CONSOLE  = uint32(14) << 3; // /dev/console output
    uint32 LOG_LOCAL0   = uint32(16) << 3;	// reserved for local use
    uint32 LOG_LOCAL1   = uint32(17) << 3;	// reserved for local use
    uint32 LOG_LOCAL2   = uint32(18) << 3;	// reserved for local use
    uint32 LOG_LOCAL3   = uint32(19) << 3;	// reserved for local use
    uint32 LOG_LOCAL4   = uint32(20) << 3;	// reserved for local use
    uint32 LOG_LOCAL5   = uint32(21) << 3;	// reserved for local use
    uint32 LOG_LOCAL6   = uint32(22) << 3;	// reserved for local use
    uint32 LOG_LOCAL7   = uint32(23) << 3;	// reserved for local use
    uint8 LOG_NFACILITIES	= 24;	// current number of facilities
    uint32 LOG_FACMASK	= 0x03f8;	// mask to extract facility part
//#define	LOG_FAC(p)	(((p) & LOG_FACMASK) >> 3) 				/* facility of pri */

static const CODE facilitynames[] = {
	{ "auth",	LOG_AUTH,	},
	{ "authpriv",	LOG_AUTHPRIV,	},
	{ "console", 	LOG_CONSOLE,	},
	{ "cron", 	LOG_CRON,	},
	{ "daemon",	LOG_DAEMON,	},
	{ "ftp",	LOG_FTP,	},
	{ "kern",	LOG_KERN,	},
	{ "lpr",	LOG_LPR,	},
	{ "mail",	LOG_MAIL,	},
	{ "mark", 	INTERNAL_MARK,	},	/* INTERNAL */
	{ "news",	LOG_NEWS,	},
	{ "ntp",	LOG_NTP,	},
	{ "security",	LOG_SECURITY,	},
	{ "syslog",	LOG_SYSLOG,	},
	{ "user",	LOG_USER,	},
	{ "uucp",	LOG_UUCP,	},
	{ "local0",	LOG_LOCAL0,	},
	{ "local1",	LOG_LOCAL1,	},
	{ "local2",	LOG_LOCAL2,	},
	{ "local3",	LOG_LOCAL3,	},
	{ "local4",	LOG_LOCAL4,	},
	{ "local5",	LOG_LOCAL5,	},
	{ "local6",	LOG_LOCAL6,	},
	{ "local7",	LOG_LOCAL7,	},
	{ NULL,		-1,		}
};

//#define	LOG_PRINTF	-1	/* pseudo-priority to indicate use of printf */
/*
 * arguments to setlogmask.
 */
//#define	LOG_MASK(pri)	(1 << (pri))		/* mask for one priority */
//#define	LOG_UPTO(pri)	((1 << ((pri)+1)) - 1)	/* all priorities through pri */

    // Option flags for openlog. LOG_ODELAY no longer does anything. LOG_NDELAY is the inverse of what it used to be.
    uint8 constant LOG_PID	    = 0x01;	// log the pid with each message
    uint8 constant LOG_CONS	    = 0x02;	// log on the console if errors in sending
    uint8 constant LOG_ODELAY	= 0x04;	// delay open until first syslog() (default)
    uint8 constant LOG_NDELAY	= 0x08;	// don't delay open
    uint8 constant LOG_NOWAIT	= 0x10;	// don't wait for console forks: DEPRECATED
    uint8 constant LOG_PERROR	= 0x20;	// log to stderr as well

    function closelog() internal {}
    function openlog(string, int, int) internal {}
    function setlogmask(int) internal {}
    function syslog(int, string) internal {}
    function vsyslog(int, string) internal {}
}