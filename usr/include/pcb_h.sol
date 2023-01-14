struct Stack {
    uint8 depth;
    uint[] s;
}

struct Continuation {
    TvmSlice code;  // (the remainder of) the TVM code to be executed.
    Stack stack;    // original contents of the stack for the code to be executed.
    mapping (uint8 => uint) savelist; // values of control registers to be restored before the execution of the code.
    uint16 cp;   // TVM codepage used to interpret the TVM code from code.
    uint8 nargs; // An optional non-negative integer nargs, indicating the number of arguments expected by the continuation.
}

struct Stack_after_main_external {// (n is current stack size):
    uint128 s1;  // contract balance
    uint128 s2;  // message balance (it's always equal to zero)
    TvmCell s3;  // msg_cell
    TvmSlice s4; // msg_body_slice
    uint s5;     // transaction_id = -1
}

struct Stack_after_main_internal {
    uint128 s1;  // contract balance
    uint128 s2;  // msg_balance
    TvmCell s3;  // inbound_message
    TvmSlice s4; // msg_body_slice
    uint s5;     // transaction_id = 0
}

struct Stack_after_tick_tock {
    uint128 s1; // Gram balance b of the current account in nanograms
    uint s2; // The 256-bit address ξ of the current account inside the masterchain, represented by an unsigned Integer.
    int8 s3; // An integer equal to 0 for tick transactions and to −1 for tock transactions.
    int8 s4; // transaction_id = -2
    int8 s5; // transaction_id = -2 (contract copies this value)
    int8 s6; // An integer equal to 0 for tick transactions and to −1 for tock transactions (it's params of function onTickTock)
}

	namespace C4 {
		// length of key in dict c4
		const int KeyLength = 64;
		const int PersistenceMembersStartIndex = 1;
	}

struct s_c4 {
    uint pubkey; // public key of the current contract.
    uint64 timestamp; // used for replay protection.
    bool await; // only if contract uses await. If it is set, the 1st ref stores address and rest continuation. 1st ref (if await flag is set): address, continuation of the rest code
    TvmCell state; // tree of cells which contains state variables.
}

struct SmartContractInfo {

}
//	namespace Selector {
//		inline std::string RootCodeCell() { return "8adb35"; } // 8a-PUSHREF db35-JMPXDATA
//		inline std::string PrivateOpcode0() { return "F4A4_"; } // DICTPUSHCONST
//		inline std::string PrivateOpcode1() { return "F4A1"; } // DICTUGETJMP
//	}

struct s_c7 {
//    c7_0;   //- SmartContractInfo structure. It's a tuple. See TVM docs.
    TvmCell c7_1;  // my code
    uint c7_2;     // tvm.pubkey
    uint64 c7_3;   // timestamp () - for default replay protection
//    c7_4;          // tuple
    address c7_4_0; // external address used for emit and return (for ext msg)
    bool c7_4_1;    // bounce (for int msg)
    uint128 c7_4_2; // tons (for int msg)
    uint128 c7_4_3; // currency (for int msg)
    uint32 c7_4_4;  // flag (for int msg)
    uint32 c7_4_5;  // callbackFunctionId (for int msg)
    uint c7_5;      // msg.pubkey
    bool c7_6;      // constructor_flag - Has constructor been called?
//    c7_7;           //
    uint32 c7_8;    // answer id for await
    address c7_9;   // msg.sender
    uint c7_10;     // c7[11], c7[12] ... - state variables
}

struct pcb {
    Continuation c0; // next continuation or return continuation (similar to the subroutine return address in conventional designs).
    Continuation c1; // alternative (return) continuation; used in some (experimental) control flow primitives, allowing TVM to define and call “subroutines with two exit points”.
    Continuation c2; // exception handler. invoked whenever an exception is triggered.
    Continuation c3; // current dictionary, essentially a hashmap containing the code of all functions used in the program.
    TvmCell c4; // root of persistent data. When the code of a smart contract is invoked, c4 points to the root cell of its persistent data kept in the blockchain state. If the smart contract needs to modify this data, it changes c4 before returning.
    TvmCell c5; // output actions. its final value is considered one of the smart contract outputs.
    uint c6; //
    s_c7 c7; // root of temporary data. It is a Tuple, initialized by a reference to an empty Tuple before invoking the smart contract and discarded after its termination.
    uint c8; // 
    uint c9; // 
    uint c10;
    uint c11;
    uint c12;
    uint c13;
    uint c14;
    uint c15;
	register_t	pcb_r15;
	register_t	pcb_r14;
	register_t	pcb_r13;
	register_t	pcb_r12;
	register_t	pcb_rbp;
	register_t	pcb_rsp;
	register_t	pcb_rbx;
	register_t	pcb_rip;
	register_t	pcb_fsbase;
	register_t	pcb_gsbase;
	register_t	pcb_kgsbase;
	register_t	pcb_cr0;
	register_t	pcb_cr2;
	register_t	pcb_cr3;
	register_t	pcb_cr4;
	register_t	pcb_dr0;
	register_t	pcb_dr1;
	register_t	pcb_dr2;
	register_t	pcb_dr3;
	register_t	pcb_dr6;
	register_t	pcb_dr7;

	struct region_descriptor pcb_gdt;
	struct region_descriptor pcb_idt;
	struct region_descriptor pcb_ldt;
	uint16_t	pcb_tr;

	u_int		pcb_flags;
#define	PCB_FULL_IRET	0x01	/* full iret is required */
#define	PCB_DBREGS	0x02	/* process using debug registers */
#define	PCB_KERNFPU	0x04	/* kernel uses fpu */
#define	PCB_FPUINITDONE	0x08	/* fpu state is initialized */
#define	PCB_USERFPUINITDONE 0x10 /* fpu user state is initialized */
#define	PCB_KERNFPU_THR	0x20	/* fpu_kern_thread() */
#define	PCB_32BIT	0x40	/* process has 32 bit context (segs etc) */
#define	PCB_FPUNOSAVE	0x80	/* no save area for current FPU ctx */

	uint16_t	pcb_initial_fpucw;
