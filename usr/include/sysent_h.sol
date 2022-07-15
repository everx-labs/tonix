pragma ton-solidity >= 0.62.0;

struct s_sysent {   // system call table
    uint16 sy_call; // implementing function
    uint8 sy_narg;  // number of arguments
}

