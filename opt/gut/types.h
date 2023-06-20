pragma ton-solidity >= 0.68.0;

struct a_type {
    uint8 attr;
    string name;
}

uint8 constant NONE   = 0;
uint8 constant BOOL   = 1;
uint8 constant INT    = 2;
uint8 constant UINT   = 3;
uint8 constant BYTES  = 4;
uint8 constant STRING = 5;
uint8 constant CELL   = 6;
uint8 constant STRUCT = 7;
uint8 constant ARRAY  = 8;
uint8 constant MAP    = 9;
uint8 constant ENUM   = 10;
uint8 constant LAST   = ENUM;

function strchr(bytes s, bytes1 c) returns (uint) {
    uint i;
    for (bytes1 b: s) {
        if (b == c)
            return i + 1;
        i++;
    }
}

function strrchr(bytes s, bytes1 c) returns (uint) {
    for (uint i = s.length; i > 0; i--)
        if (s[i - 1] == c)
            return i;
}
