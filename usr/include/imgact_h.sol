pragma ton-solidity >= 0.62.0;
import "proc_h.sol";
import "sysent_h.sol";
import "ucred_h.sol";
import "imgact_h.sol";
struct s_image_args {
    string buf;	        // pointer to string buffer
    bytes bufkva;       // cookie for string buffer KVA
    string begin_argv;  // beginning of argv in buf
    string begin_envv;  // (interal use only) beginning of envv in buf, access with exec_args_get_begin_envv().
    string endp;        // current `end' pointer of arg & env strings
    string fname;       // pointer to filename of executable (system space)
    string fname_buf;   // pointer to optional malloc(M_TEMP) buffer
    uint16 stringspace;	// space left in arg & env buffer
    uint16 argc;        // count of argument strings
    uint16 envc;        // count of environment strings
    uint16 fd;          // file descriptor of the executable
}

struct s_image_params {
    s_proc proc;           // our process
//  s_vnode vp;            // pointer to vnode of file to exec
//  struct vm_object object;// The vm object for this vp
//  s_vattr attr;           // attributes of file
    string image_header;    // header of file to exec
//  unsigned long entry_addr;   // entry address of target executable
//  unsigned long reloc_base;   // load address of image
    string interpreter_name;    // name of the interpreter
    string auxargs;             // ELF Auxinfo structure pointer
//  struct sf_buf *firstpage;   // first page that we mapped
    string ps_strings;  // pointer to ps_string (user space)
    s_image_args args;  // system call arguments
    s_sysentvec sysent; // system entry vector
    string argv;        // pointer to argv (user space)
    string envv;        // pointer to envv (user space)
    string execpath;
    string execpathp;
    string freepath;
    string canary;
    uint16 canarylen;
    string pagesizes;
    uint16 pagesizeslen;
    uint16 stack_sz;
    s_ucred newcred;        // new credentials if changing
    uint8 interpreted;	    // mask of interpreters that have run
    bool credential_setid;  // true if becoming setid
    bool vmspace_destroyed; // we've blown away original vm space
    bool opened;            // we have opened executable vnode
    bool textset;
    uint32 map_flags;
    uint32 imgp_flags;
}
