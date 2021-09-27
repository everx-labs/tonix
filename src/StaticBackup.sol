pragma ton-solidity >= 0.49.0;

import "SharedCommandInfo.sol";

contract StaticBackup is SharedCommandInfo {

    function _init() internal override {
        uint _RHLP = _R + _H + _L + _P; // 2.6
        uint _bfntTv = _b + _f + _n + _t + _T + _v;
        _insert(account,    0, M, _d);
        _insert(basename,   1, M, _a + _s + _z);
        _insert(cat,        1, M, _A + _b + _e + _E + _n + _s + _t + _T + _u + _v);
        _insert(cd,         1, 1, _L + _P + _e);
        _insert(chgrp,      2, M, _c + _f + _v + _RHLP);
        _insert(chfn,       1, 2, _f);
        _insert(chmod,      2, M, _c + _f + _v + _R);
        _insert(chown,      2, M, _c + _f + _v + _RHLP);
        _insert(cksum,      1, M, 0);
        _insert(cmp,        2, 2, _b + _l + _s);
        _insert(colrm,      1, 3, 0);
        _insert(column,     0, M, _e + _n + _t + _x);
        _insert(cp,         2, M, _a + _d + _l + _p + _r + _s + _u + _x + _RHLP + _bfntTv);
        _insert(cut,        0, 1, _f + _s + _z);
        _insert(dd,         0, M, 0);
        _insert(df,         1, M, _a + _h + _H + _i + _k + _l + _P + _v);
        _insert(dirname,    1, M, _z);
        _insert(du,         1, M, _a + _b + _c + _D + _h + _H + _k + _l + _L + _m + _P + _s + _S + _x + _0);
        _insert(echo,       0, M, _n);
        _insert(expand,     1, M, _i + _t);
        _insert(fallocate,  1, 1, _d + _l + _n + _v + _x + _z);
        _insert(file,       1, M, _b + _E + _L + _h + _N + _v + _0);
        _insert(findmnt,    0, M, _s + _m + _k + _A + _b + _D + _f + _n + _u);
        _insert(finger,     1, M, _l + _m + _s);
        _insert(fuser,      0, 1, _a + _l + _m + _s + _u + _v);
        _insert(getent,     1, 2, 0);
        _insert(grep,       2, M, _v + _x);
        _insert(gpasswd,    1, M, _a + _d + _r + _R + _A + _M);
        _insert(groupadd,   1, M, _f +_g + _r);
        _insert(groupdel,   1, 1, _f);
        _insert(groupmod,   1, M, _g + _n);
        _insert(head,       1, M, _n + _q + _v + _z);
        _insert(help,       0, M, _d + _m + _s);
        _insert(hostname,   0, 0, _a + _f + _i + _s);
        _insert(id,         0, 1, _a + _g + _G + _n + _r + _u + _z);
        _insert(last,       0, M, _a + _d + _F + _i + _R + _w + _x);
        _insert(ln,         2, M, _r + _s + _L + _P + _bfntTv);
        _insert(login,      1, 1, _f + _h + _r);
        _insert(logout,     0, 0, 0);
        _insert(look,       1, 3, _b + _d + _f + _t);
        _insert(ls,         1, M, _a + _A + _B + _c + _C + _d + _f + _F + _g + _G + _h + _H + _i + _k + _l + _L + _m + _n + _N +
            _o + _p + _q + _Q + _r + _R + _s + _S + _t + _u + _U + _v + _x + _X + _1);
        _insert(lsblk,      0, M, _a + _b + _f + _m + _n + _O + _p);
        _insert(lslogins,   0, 1, _c + _e + _n + _r + _s + _u + _z);
        _insert(lsof,       0, M, _l + _n + _o + _R + _s + _t);
        _insert(man,        0, M, _a);
        _insert(mapfile,    1, M, _d + _n + _s + _t + _u);
        _insert(mkdir,      1, M, _m + _p + _v);
        _insert(more,       1, M, _d + _f + _l + _c + _p + _s + _u);
        _insert(mount,      0, 3, _a + _c + _f + _T + _l + _n + _r + _v + _w + _N + _B + _M);
        _insert(mountpoint, 1, 1, _d + _q + _x);
        _insert(mv,         2, M, _u + _bfntTv);
        _insert(namei,      1, M, _x + _m + _o + _l + _n + _v);
        _insert(paste,      1, M, _s + _z);
        _insert(ping,       0, M, _D + _n + _q + _v);
        _insert(ps,         0, 0, _e + _f + _F);
        _insert(pwd,        0, 0, _L + _P);
        _insert(readlink,   1, M, _f + _e + _m + _n + _q + _s + _v + _z);
        _insert(realpath,   1, M, _e + _m + _L + _P + _q + _s + _z);
        _insert(rev,        1, M, 0);
        _insert(rm,         1, M, _f + _r + _R + _d + _v);
        _insert(rmdir,      1, M, _p + _v);
        _insert(stat,       1, M, _L + _f + _t);
        _insert(tail,       1, M, _n + _q + _v + _z);
        _insert(touch,      1, M, _c + _m);
        _insert(tr,         1, M, _d + _s);
        _insert(truncate,   1, M, _c + _o + _r + _s);
        _insert(uname,      0, 0, _a + _s + _n + _r + _v + _m + _p + _i + _o);
        _insert(unexpand,   1, M, _a + _t);
        _insert(useradd,    1, M, _g + _G + _l + _m + _M + _N + _r + _U);
        _insert(userdel,    1, 1, _f + _r);
        _insert(usermod,    1, M, _a + _g + _G);
        _insert(utmpdump,   1, 1, _r + _o);
        _insert(wc,         1, M, _c + _m + _l + _L + _w);
        _insert(whatis,     0, M, _d + _l + _v);
        _insert(who,        0, 1, _a + _b + _d + _H + _l + _p + _q + _s + _t + _T + _w + _u);
        _insert(whoami,     0, 0, 0);
        _command_names = ["account", "basename", "blkdiscard", "cat", "cd", "chfn", "chgrp", "chmod", "chown","cksum", "cmp", "colrm", "column", "cp", "cut",
            "dd", "df", "dirname", "du", "echo", "env", "expand", "fallocate", "file", "findfs", "findmnt", "finger", "fsck", "fstrim", "fuser",
            "getent", "getopt", "gpasswd", "grep", "groupadd", "groupdel", "groupmod", "head", "help", "hostname", "id", "last", "ln", "login",
            "logout", "look", "losetup", "ls", "lsblk", "lslogins", "lsof", "man", "mapfile", "mkdir", "mkfs", "mknod", "more", "mount", "mountpoint",
            "mv", "namei", "newgrp", "paste", "pathchk", "ping", "ps", "pwd", "readlink", "realpath", "reboot", "rename", "rev", "rm", "rmdir",
            "script", "stat", "tail", "tar", "touch", "tr", "truncate", "udevadm", "umount", "uname", "unexpand", "useradd", "userdel", "usermod",
            "utmpdump", "wc", "whatis", "whereis", "who", "whoami"];  // 1.4
    }

    function _insert(uint8 index, uint8 min_args, uint16 max_args, uint options) private {
        _command_info[index] = CmdInfoS(min_args, max_args, options);
    }

}
