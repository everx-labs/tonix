pragma ton-solidity >= 0.68.0;

enum Modifier { OPEN, AUTOMATIC, SYNTHETIC, MANDATED }

struct Object {
    uint16 id;
    uint16 classId;
    uint32 ref;
    TvmCell data;
}

struct Class {
    uint16 id;
    string name;
    uint16 module;
    uint16 classLoader;
    Object classData;
    string superClass;
    string packageName;
    int64 serialVersionUID;
    uint16 componentType;
}

struct String {
    uint16 size;
    bytes value;
    bytes1 coder;
    uint hash; // Default to 0
    bool hashIsZero; // Default to false;
}

struct Seg {
    uint16 id;
    string name;
    uint16 cnt;
    uint32 mtotal;
    uint32 mmax;
    uint32 mfree;
    uint16 base;
    mapping (uint16 => uint16) rcnt;
    mapping (uint16 => Object) m;
}

struct NativeLibrary {
    uint16 fromClass; // Class
    string name;
    bool isBuiltin;
    uint32 handle;
    uint16 niVersion;
}
struct NativeLibraries {
    mapping (uint16 => string) libraries;
    uint16 loader; // ClassLoader
    uint16 caller; // Class     // may be null
    bool searchLibraryPath;
}

struct Package {
    uint16 id;
    string name;
    uint16 module; // Module
    uint16 nextId;
    mapping (uint16 => string) classNames;
}

struct Module {
    uint16 id;
    string name;
    uint16 loader; // ClassLoader
    uint16 mask;
    Modifier[] mods;
    uint16[] parents; // ModuleLayer
    mapping (uint16 => string) nameToModule; // Module
    string compiledVersion;
    string rawCompiledVersion;
    string targetPlatform;
}

struct ClassLoader {
    uint16 id;
    uint16 parent; // ClassLoader
    string name;
    string nid;
    Module unnamedModule; // Module
    Package[] packages;
    Class[] classes;
    NativeLibraries libs;
    bool defaultAssertionStatus;
    mapping (uint16 => bool) packageAssertionStatus;
    mapping (uint16 => bool) classAssertionStatus;
    mapping (uint16 => Object) classLoaderValueMap;
    Seg pool;
}

struct Thread {
    uint16 id;
    TvmCell obj;
}
struct Process {
    uint16 id;
    TvmCell obj;
}

struct Boot {
    uint16 id;
    Object obj;
    ClassLoader[] loaders;
    Thread[] hooks;
}

struct Runtime {
    uint16 id;
    uint16 cnt;
    uint8 procs;
    Seg[] mem;
    Boot boot;
}