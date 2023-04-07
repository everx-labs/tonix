pragma ton-solidity >= 0.66.0;

struct linker_symval {
    string name;
    uint32 value;
    uint8 size;
}
struct common_symbol {
    uint16 link; // common_symbol
    string name;
    uint32 addr;
}
struct linker_file {
    uint8 refs;	        // reference count
    uint8 userrefs;	    // kldload(2) count
    uint8 flags;
    string filename;    // file which was loaded
    string pathname;    // file name with full path
    uint16 id;          // unique id
    uint32 addr;        // load address
    uint32 size;        // size of file
    uint32 ctors_addr;  // address of .ctors/.init_array
    uint32 ctors_size;  // size of .ctors/.init_array
    uint32 dtors_addr;  // address of .dtors/.fini_array
    uint32 dtors_size;  // size of .dtors/.fini_array
    uint8 ndeps;        // number of dependencies
    uint16[] deps;      // list of dependencies
    common_symbol[] common; // list of common symbols
    module_stat[] modules;  // modules in this file
}
struct module_stat {
    uint16 version;	// set to sizeof(struct module_stat)
    string name;
    uint16 refs;
    uint16 id;
    uint32 data;
}
struct sod {	        // Shared Object Descriptor
    uint16 sod_name;	// name (relative to load address)
    uint8 sod_library;	// Searched for by library rules
    uint8 sod_major;	// major version number
    uint8 sod_minor;	// minor version number
}
struct so_map {	        // Shared Object Map
    uint32 som_addr;    // Address at which object mapped
    string som_path;    // Path to mmap'ed file
    sod	som_sod;        // Sod responsible for this map
    uint32 som_sodbase; // Base address of this sod
    uint8 som_write;    // Text is currently writable
    uint32 som_spd;	    // Private data
}
