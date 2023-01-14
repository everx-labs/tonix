pragma ton-solidity >= 0.64.0;

struct kobj_method_t {
//    kobjop_desc_t desc;
    kobjop_desc desc;
//    TvmCell func;
    uint32 func;
}

struct kobj_class_t {
    bytes10 name;        // class name
    kobj_method_t[] methods; // method table
    uint16 size;         // object size
    uint32[] baseclasses; // base classes
    uint8 refs;          // reference count
//    kobj_ops_t ops;      // compiled method table
    uint32 ops;      // compiled method table
}

struct kobj_t {
    uint32 p;
//    kobj_ops_t ops;
    uint32 ops;
}

//struct kobj_ops_t {
struct kobj_ops {
    kobj_method_t[] cache;//[KOBJ_CACHE_SIZE];
    bytes10 cls;
//    kobj_class_t cls;
}

//struct kobjop_desc_t {
struct kobjop_desc {
    uint32 id;     // unique ID
//    TvmCell deflt; // default implementation
    uint32 deflt; // default implementation
}
