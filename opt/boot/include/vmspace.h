pragma ton-solidity >= 0.66.0;
struct vm_map_entry {
	uint16 left;	// left child or previous entry // vm_map_entry
	uint16 right;	// right child or next entry // vm_map_entry
	uint32 start;		// start address
	uint32 end; 		// end address
	uint32 next_read;	// vaddr of the next sequential read
	uint32 max_free;	// max free space in subtree
    uint16 object;	// object I point to // vm_map_object
	uint32 offset;		// offset into object
	uint32 eflags;		// map entry flags
	uint32 protection;	// protection code
    uint32 max_protection;	// maximum protection
	uint32 inheritance;	// inheritance
	uint8 read_ahead;	// pages in the read-ahead window
	uint8 wired_count;	// can be paged if = 0
	uint16 cred;		    // tmp storage for creator ref // ucred
}
struct vm_map {
	uint16[] header;	// List of entries // vm_map_entry
	uint8 nentries;		// Number of entries
	uint32 size;		// virtual size
	uint16 timestamp;	// Version number
	uint8 system_map;	// Am I a system map?
	uint16 flags;		// flags for this vm_map
	uint16 root;	    // Root of a binary search tree
	uint16 pmap;		// Physical map // pmap_t
	uint32 anon_loc;
	uint8 busy;
}
struct vmspace {
	uint32 vm_map;	    // VM address map // vm_map
	uint32 vm_swrss;	// resident set size before last swap
	uint32 vm_tsize;	// text size (pages) XXX
	uint32 vm_dsize;	// data size (pages) XXX
	uint32 vm_ssize;	// stack size (pages)
	uint32 vm_taddr;	// user virtual address of text
	uint32 vm_daddr;	// user virtual address of data
	uint32 vm_maxsaddr;	// user VA at max stack growth
	uint32 vm_stacktop; // top of the stack, may not be page-aligned
	uint32 vm_shp_base; // shared page address
	uint16 vm_pmap;	    // private physical map // pmap
}