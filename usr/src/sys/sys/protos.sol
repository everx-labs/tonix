pragma ton-solidity >= 0.60.0;

/*interface peer {
    struct uma_cell_slab {
    uint16 ucs_link;      // slabs in zone
    uint16 ucs_freecount; // How many are free?
    uint8 ucs_flags;      // Page flags
    uint8 ucs_domain;     // Backing NUMA domain.
    uint16 ucs_free;      // Free bitmask, flexible.
    TvmCell ucs_data;
}

    function store_state(uma_keg[] kegs, uma_bucket_zone[] bucket_zones, uma_zone[] zones, uma_slab[] slabs, uma_bucket[] buckets, uint32 uma_kmem_total, uint32 uma_kmem_limit, string log, string trace, string err, bytes[] pg, bytes[] sb, bytes[] bk, TvmCell[] cl, uma_domain k0, uma_cache cache) external;
}

interface uma_zone_client {
    function add_zone(uma_zone zone) external;
    function update_zone(uma_zone zone) external;
}

interface uma_zone_host {
    function uma_zcreate(string name, uint16 size, uint16 ctor, uint16 dtor, uint16 uminit, uint16 fini, uint16 align, uint32 flags) external returns (uma_zone zone);
    function uma_zsecond_create(string name, uint16 ctor, uint16 dtor, uint16 zinit, uint16 zfini, uma_zone primary) external returns (uma_zone zone);
    function uma_prealloc(uint16 zone_id, uint16 nitems) external returns (uma_zone zone);
}

interface file_peer {
    function import_data(TvmCell[] cells) external;
    function store_data(TvmCell[] cells) external;
    function cache_data(TvmCell[] cells) external;
    function export_data(uint32 range, address addr) external view;
}

import "infini.sol";

/*struct u_model {
    uint16 size;
    uint16 alloc_type;
    uint16 major_version;
    uint16 minor_version;
    uint32 updated_at;
    uint32 location;
}

struct u_bio {
    uint16 size;
    uint16 ordinal;
    uint48 serial;
    bytes10 name;
    uint32 deployed_at;
    address addr;
}

struct u_proto {
    uint16 size;
    uint16 version;
    bytes10 name;
    address addr;
    uint32 updated_at;
    uint32 location;
}*/

contract protos {

    uint8 constant PROTOZONE_SIZE = 49;
    uint8 constant BIOZONE_SIZE = 59;
    uint8 constant MODELZONE_SIZE = 16;

    uint8 constant uma_align_cache = 64 - 1;

    function upgrade(TvmCell c) external {
        tvm.accept();
        tvm.setcode(c);
        tvm.setCurrentCode(c);
        onCodeUpgrade();
    }

    function onCodeUpgrade() internal {
    }

    function reset_storage() external accept {
        tvm.resetStorage();
    }

    modifier accept {
        tvm.accept();
        _;
    }
}
