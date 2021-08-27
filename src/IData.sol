pragma ton-solidity >= 0.49.0;

struct Std {
    string out;
    string err;
}

struct InputS {
    uint8 command;
    string[] args;
    uint flags;
}

struct IOEventS {
    uint8 iotype;
    uint16 parent;
    uint16[] indices;
    string[] paths;
}

struct ReadEventS {
    uint8 read_type;
    uint16 iid;
    uint16 val;
    uint32 pos;
}

struct SessionS {
    string login;
    uint16 uid;
    uint16 gid;
    uint16 wd;
    string cwd;
}
