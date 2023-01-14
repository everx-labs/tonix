pragma ton-solidity >= 0.62.0;

struct s_sysentvec {
    uint8 sv_size;	    // number of entries
    s_sysent[] sv_table;// pointer to sysent
    string sv_sigcode;  // start of sigtramp code
//  int *sv_szsigcode;  // size of sigtramp code
//  int	sv_sigcodeoff;
    string sv_name;	    // name of binary type
//  int	sv_elf_core_osabi;
//  string sv_elf_core_abi_vendor;
//  int	sv_minsigstksz;	    // minimum signal stack size
//  vm_offset_t	sv_minuser;	    // VM_MIN_ADDRESS
//  vm_offset_t	sv_maxuser;	    // VM_MAXUSER_ADDRESS
//  vm_offset_t	sv_usrstack;    // USRSTACK
//  vm_offset_t	sv_psstrings;   // PS_STRINGS
//  size_t sv_psstringssz;	// PS_STRINGS size
//  u_long *sv_maxssiz;
    uint32 sv_flags;
    string[] sv_syscallnames;
//  vm_offset_t	sv_timekeep_offset;
//  vm_offset_t	sv_shared_page_base;
//  vm_offset_t	sv_shared_page_len;
//  vm_offset_t	sv_sigcode_offset;
//  void		*sv_shared_page_obj;
//  vm_offset_t	sv_vdso_offset;
}
struct s_sysent {
    uint8 sy_narg;
    uint8 sy_flags;
    uint8 sy_module;
    uint16 sy_code;
    string sy_name;
}