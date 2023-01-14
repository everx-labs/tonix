pragma ton-solidity >= 0.64.0;

struct s_cv {
    uint32 cv_wchan;
    string cv_description;
    uint8 cv_waiters;
}
