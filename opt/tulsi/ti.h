
pragma ton-solidity >= 0.67.0;

struct stt {
    uint8 id;
    uint8 pid;
    uint8 rsz;
    uint8 bsz;
    uint8 nl;
    uint8 nr;
    uint8 noff;
    uint8 attr;
}


struct vari {
    uint8 id;
    uint8 pid;
    uint8 nl;
    uint8 nr;
    uint8 noff;
    uint8 attr;
}

struct vard {
    uint8 vtype;
    uint8 vcnt;
    uint8 dlen;
    uint8 slen;
    string vname;
    string vdesc;
}
