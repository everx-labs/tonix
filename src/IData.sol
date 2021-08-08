pragma ton-solidity >= 0.48.0;

struct Std {
    string out;
    string err;
}

struct InputS {
    uint8 process_command;
    string[] args;
    uint flags;
    string target;
}

struct INodeEventS {
    uint8 intype;
    uint16 iid;
    uint16 val;
    uint16 val2;
    uint32 attr;
}

struct IOEventS {
    uint8 iotype;
    uint16 iid;
    uint16 val;
    string path;
    string text;
}

struct ReadEventS {
    uint8 read_type;
    uint16 iid;
    uint16 val;
    uint32 pos;
}

struct SessionS {
    uint16 uid;
    uint16 gid;
    uint16 wd;
}
