pragma ton-solidity >= 0.63.0;
import "kobj_h.sol";
//import "liberr.sol";
import "libmalloc.sol";
library libkobj {
//static MALLOC_DEFINE(M_KOBJ, "kobj", "Kernel object structures");

    uint8 constant KOBJ_CACHE_SIZE = 255;
    uint16 constant kobj_next_id = 1;

    uint8 constant ENXIO    = 6; // Device not configured
    uint8 constant ENOMEM   = 12; // Cannot allocate memory

    // This method structure is used to initialise new caches. Since the desc pointer is NULL, it is guaranteed never to match any read descriptors.
    //optional (kobj_method_t) constant null_method;
    //const struct kobj_method null_method = { 0, 0, };

    function kobj_null_method() internal returns (kobj_method_t) {
    }
    function f_kobj_next_id(uint16 kid) internal returns (uint16) {
        return kid + 1;
    }
    function kobj_error_method() internal returns (uint8) {
        return ENXIO;
    }

    function kobj_class_compile_common(kobj_class_t cls, kobj_ops ops) internal {
        // Don't do anything if we are already compiled.
//      if (!cls.ops.cache.empty())
        if (cls.ops > 0)
            return;
        // First register any methods which need it.
        for (kobj_method_t m: cls.methods) {
            if (m.desc.id == 0)
                //m.desc.id = kobj_next_id++;
                m.desc.id = f_kobj_next_id(kobj_next_id);
        }
        // Then initialise the ops table.
        for (uint i = 0; i < KOBJ_CACHE_SIZE; i++)
            ops.cache[i] = kobj_null_method(); //null_method;
        ops.cls = cls.name;
//           cls.ops = ops;
    }

    function kobj_class_compile1(kobj_class_t cls, uint16) internal returns (uint8){
        uint32 p;// = libmalloc.malloc(libmalloc._sizeof(libmalloc.KOBJ_OPS), libmalloc.M_KOBJ, mflags);
        if (p == 0)
            return ENOMEM;
//      if (!cls.ops.cache.empty()) {
        if (cls.ops > 0) {
//          libmalloc.free(p, libmalloc.M_KOBJ);
            return 0;
        }
        kobj_ops ops;
//        ops.p = p;
        kobj_class_compile_common(cls, ops);
    }

    function kobj_class_compile(kobj_class_t cls) internal {
        uint8 error = kobj_class_compile1(cls, libmalloc.M_WAITOK);
        if (error > 0) {
    //    	KASSERT(error == 0, ("kobj_class_compile1 returned %d", error));
        }
    }

    function kobj_class_compile_static(kobj_class_t cls, kobj_ops ops) internal {
    	//  Increment refs to make sure that the ops table is not freed.
    	cls.refs++;
    	kobj_class_compile_common(cls, ops);
    }

    function kobj_lookup_method_class(kobj_class_t[] kcs, kobj_class_t kc, kobjop_desc desc) internal returns (kobj_method_t ce) {
        (uint8 ec, kobj_class_t cl) = find_kobj_class(kcs, kc.name);
//      kobj_method_t[] kms
        if (ec == 0)
        for (kobj_method_t m: cl.methods) {
            if (m.desc.id == desc.id)
  	            return m;
        }
    }

    function kobj_lookup_method_mi(kobj_class_t[] kcs, kobj_class_t cls, kobjop_desc desc) internal returns (kobj_method_t ce) {
        ce = kobj_lookup_method_class(kcs, cls, desc);
        if (ce.desc.id > 0)
            return ce;
        if (!kcs.empty()) {
        	for (kobj_class_t basep: kcs) {
                ce = kobj_lookup_method_mi(kcs, basep, desc);
                if (ce.desc.id > 0)
                    return ce;
            }
        }
    }

    function kobj_lookup_method(kobj_class_t[] kcs, kobj_class_t cls, kobj_method_t[] cep, kobjop_desc desc) internal returns (kobj_method_t ce) {
    	ce = kobj_lookup_method_mi(kcs, cls, desc);
    	if (ce.desc.id == 0)
            ce.func = desc.deflt;
    	if (cep.length > 0)
            cep = [ce];
    }

    function kobj_class_free(kobj_class_t[] , kobj_class_t cls) internal {
//        kobj_ops ops;
    	// Protect against a race between kobj_create and kobj_delete.
    	if (cls.refs == 0) {
            // For now we don't do anything to unregister any methods which are no longer used.
//            ops = cls.ops;
            delete cls.ops;
    	}
//        if (ops.p > 0)
//  	        libmalloc.free(ops.p, libmalloc.M_KOBJ);
    }

    function kobj_init_common(kobj_t obj, kobj_class_t cls) internal {
        obj.ops = cls.ops;
        cls.refs++;
    }

    function kobj_init1(kobj_t obj, kobj_class_t cls, uint16 mflags) internal returns (uint8 error) {
//    	while (cls.ops.cache.empty()) {
       	while (cls.ops == 0) {
            error = kobj_class_compile1(cls, mflags);
            if (error != 0)
                return error;
    	}
    	kobj_init_common(obj, cls);
    }

    function kobj_create(kobj_class_t cls, uint8 , uint16 mflags) internal returns (kobj_t obj){
        uint32 p;// = libmalloc.malloc(cls.size, mtype, mflags | libmalloc.M_ZERO);
    	if (p == 0)
    		return obj;
    	if (kobj_init1(obj, cls, mflags) > 0) {
//    		libmalloc.free(p, mtype);
            delete obj;
    	} else
            obj.p = p;
    }

    function kobj_init(kobj_t obj, kobj_class_t cls) internal {
    	uint8 error = kobj_init1(obj, cls, libmalloc.M_NOWAIT);
    	if (error > 0) {
//    		panic("kobj_init1 failed: error %d", error);
        }
    }

    function kobj_init_static(kobj_t obj, kobj_class_t cls) internal {
    	kobj_init_common(obj, cls);
    }

    function find_kobj_class(kobj_class_t[] kcs, bytes10 name) internal returns (uint8, kobj_class_t) {
        uint i = 0;
        for (kobj_class_t kc: kcs) {
            i++;
            if (kc.name == name)
                return (uint8(i), kc);
        }
    }
    function kobj_delete(kobj_class_t[] kcs, kobj_t obj, uint8) internal {
//    	(uint res, kobj_class_t cls) = find_kobj_class(kcs, obj.ops.cls);
    	// Consider freeing the compiled method table for the class after its last instance is deleted. As an optimisation, we
    	// should defer this for a short while to avoid thrashing.
//        if (res == 0)
//            return;
        kobj_class_t cls;
    	cls.refs--;
    	uint8 refs = cls.refs;
    	if (refs == 0)
    		kobj_class_free(kcs, cls);
    	delete obj.ops;
//    	if (mtype > 0)
 //   		delete obj;
//            libmalloc.free(obj.p, mtype);
    }
}