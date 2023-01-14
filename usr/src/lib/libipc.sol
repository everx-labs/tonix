pragma ton-solidity >= 0.64.0;

library libipc {
    uint16 constant IPC_R		= 0x0100;	// read permission
    uint16 constant IPC_W		= 0x0080;	// write/alter permission
    uint16 constant IPC_M		= 0x1000;	// permission to change control info
    uint16 constant IPC_CREAT	= 0x0200;	// create entry if key does not exist
    uint16 constant IPC_EXCL	= 0x0400;	// fail if key exists
    uint16 constant IPC_NOWAIT	= 0x0800;	// error if request must wait
    uint8 constant IPC_PRIVATE = 0;// private key
    uint8 constant IPC_RMID = 0;   // remove identifier
    uint8 constant IPC_SET  = 1;   // set options
    uint8 constant IPC_STAT = 2;   // get options
    uint8 constant IPC_INFO = 3;   // get info

/* Macros to convert between ipc ids and array indices or sequence ids */
//#define	IPCID_TO_IX(id)		((id) & 0xffff)
//#define	IPCID_TO_SEQ(id)	(((id) >> 16) & 0xffff)
//#define	IXSEQ_TO_IPCID(ix,perm)	(((perm.seq) << 16) | (ix & 0xffff))
//int	ipcperm(s_thread, s_ipc_perm, int);
//extern void (shmfork_hook)(s_proc, s_proc);
//extern void (shmexit_hook)(s_vmspace *);
//key_t	ftok(string, int);
}
