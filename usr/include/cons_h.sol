pragma ton-solidity >= 0.64.0;

struct s_consdev_ops {
	uint32 cn_probe; // cn_probe_t probe hardware and fill in consdev info
	uint32 cn_init;	 // cn_init_t turn on as console
	uint32 cn_term;	 // cn_term_t turn off as console
	uint32 cn_getc;	 // cn_getc_t kernel getchar interface
	uint32 cn_putc;	 // cn_putc_t kernel putchar interface
	uint32 cn_grab;	 // cn_grab_t grab console for exclusive kernel use
	uint32 cn_ungrab; // cn_ungrab_t ungrab console
	uint32 cn_resume; // cn_init_t set up console after sleep, optional
}

struct consdev_ops {
    function (s_consdev) internal cn_probe;
    function (s_consdev) internal cn_init;
    function (s_consdev) internal cn_term;
    function (s_consdev) internal returns (byte) cn_getc;
    function (s_consdev, byte) internal cn_putc;
    function (s_consdev) internal cn_grab;
    function (s_consdev) internal cn_ungrab;
    function (s_consdev) internal cn_resume;
}

struct s_consdev {
	consdev_ops cn_ops;	// consdev_ops console device operations.
	uint8 cn_pri;	// pecking order; the higher the better
	uint32 cn_arg;	 // drivers method argument
	uint8 cn_flags; // capabilities of this console
	string cn_name;  //[SPECNAMELEN + 1];	// console (device) name
}

struct s_cn_device {
	uint32 cnd_next; // STAILQ_ENTRY(cn_device)
	s_consdev cnd_cn;
}
