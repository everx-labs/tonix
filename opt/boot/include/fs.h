pragma ton-solidity >= 0.66.0;

struct stat {
	uint16 st_dev;		// inode's device
	uint16 st_ino;		// inode's number
	uint16 st_nlink;	// number of hard links
	uint16 st_mode;		// inode protection mode
	uint16 st_uid;		// user ID of the file's owner
	uint16 st_gid;		// group ID of the file's group
	uint16 st_rdev;		// device type
	uint32 st_atim;	    // time of last access
	uint32 st_mtim;	    // time of last data modification
	uint32 st_ctim;	    // time of last file status change
	uint32 st_birthtim;	// time of file creation
	uint32 st_size;		// file size, in bytes
	uint16 st_blocks;	// blocks allocated for file
	uint16 st_blksize;	// optimal blocksize for I/O
	uint16 st_gen;		// file generation number
}
struct idirent {
    uint8 ft;
    uint16 inode;
    uint8 nl;
    bytes11 name;
}
struct dinode { // 4 x 4 + 6 x 2 + 3 = 31
	uint16 di_mode;	 // IFMT, permissions; see below
    uint8 di_ino;	 // Inode no
	uint8 di_nlink;	 // File link count
	uint16 di_size;	 // File byte count
	uint32 di_mtime; // Last modified time
	uint32 di_ctime; // Last inode change time
	uint32 di_atime; // Birth time
    uint16 di_db1;
    uint16 di_db2;
	uint16 di_flags; //Status flags (chflags)
	uint8 di_blocks; //Blocks actually held
	uint8 di_gen;	 //Generation number
	uint16 di_uid;	 //File owner
	uint16 di_gid;	 //File group
    uint8 padding;   // padding to 31
}
struct file { // 1 x 2 + 5 = 7
	uint8 f_flag;		// see fcntl.h
	uint8 f_count;	    // reference count
	uint8 f_data;	    // file descriptor specific data
	uint8 f_vnode;	    // NULL or applicable vnode
	uint8 f_type;		// descriptor type
	uint16 f_offset;    // DFLAG_SEEKABLE specific fields
}
struct fdescenttbl {
	uint8 fdt_nfiles;   // number of open files allocated
	file[] fdt_ofiles;  // open files
}
struct filedesc {
    uint8 fd_files;     // open files table // fdescenttbl
	uint32 fd_map;		// bitmap of free fds
	uint8 fd_freefile;	// approx. next free file
}
struct pwd {
	dinode pwd_cdir;	// current directory
	dinode pwd_rdir;	// root directory
}