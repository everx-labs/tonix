pragma ton-solidity >= 0.58.0;

import "vars.sol";

library env {

    using libstring for string;

    //  obtains the current value of the environment	variable, name
    function get(string name, string e) internal returns (string) {
        string pat = "[" + name + "]";
        (string[] lines, ) = e.split("\n");
        for (string line: lines) {
            uint q = str.strstr(line, pat);
            if (q > 0) {
                string s = e.val(pat + "=", "\n");
//                e.sval(pat + "=", "\n");

//                e.val(pat + "=", "\n");
//                string s = line.substr(q + pat.byteLength() - 1);
//                string s = line.substr(q + pat.byteLength() - 1);
//                s.unwrap();
//                return s;
                return str.unwrp(s);
            }
        }
    }

    function geti(string name, string e) internal returns (uint16) {
        string val = get(name, e);
        return str.toi(val);
//        string val = get(name, e);
//        return sgr.toi();
    }

    function get_old(string name, string e) internal returns (string) {
        string line = vars.get_pool_record(name, e);
        if (!line.empty()) {
            (, , string value) = vars.split_var_record(line);
            return value;
        }
    }

    // inserts or resets the environment variable name in the current environment list.
    // If the variable name does not exist in the list, it is inserted with the given value. If the
    // variable does exist, the argument overwrite is tested; if overwrite is zero, the variable is
    // not reset, otherwise it is reset to the given value.
    function set(string name, string value, bool overwrite, string e) internal returns (string) {
        string val = get(name, e);
        string token = name + "=" + value;
        if (val.empty())
            return put(token, e);
        if (!overwrite)
            return e;
        return put(token, e);
//        string cur_line = vars.get_pool_record(name, env);
//        string new_line = var_record("", name, value);
//        return vars.set_var("", name + "=" + value, e);
//        if (line.empty())
//            return env + new_line + "\n";
//        if (overwrite)
//            return env + new_line + "\n";
    }

    //takes an argument of the form ``name=value'' and puts it directly into the current
    // environment, so altering	the argument shall change the environment. If the variable name does not exist	in the
    // list, it is inserted with the given value. If the variable name does exist, it is	reset to the given value.
    function put(string token, string e) internal returns (string) {
        return vars.set_var("", token, e);
    }

    // deletes all instances of the variable name pointed to by name from the list.
    function unset(string name, string e) internal returns (string) {
        return vars.unset_var(name, e);
    }

    function getbsize(string e) internal returns (uint16, string) {
        return (geti("BLOCKSIZE", e), "cells");
    }

    function getuid(string e) internal returns (uint16) {
        return geti("UID", e);
    }

    function geteuid(string e) internal returns (uint16) {
        return geti("EUID", e);
    }

    function getgid(string e) internal returns (uint16) {
        return geti("GID", e);
    }

    function getegid(string e) internal returns (uint16) {
        return geti("EGID", e);
    }

    function setuid(uint16 uid, string e) internal returns (string) {
        return put("UID=" + str.toa(uid), e);
    }

    function seteuid(uint16 euid, string e) internal returns (string) {
        return put("EUID=" + str.toa(euid), e);
    }

    function setgid(uint16 gid, string e) internal returns (string) {
        return put("GID=" + str.toa(gid), e);
    }

    function setegid(uint16 egid, string e) internal returns (string) {
        return put("EGID=" + str.toa(egid), e);
    }

    function setregid(uint16 rgid, uint16 egid, string e) internal returns (string) {
        string res = setgid(rgid, e);
        return setegid(egid, res);
    }

    function getregid(string e) internal returns (uint16, uint16) {
        return (getgid(e), getegid(e));
    }

    function issetugid(string e) internal returns (bool) {
        return getuid(e) != geteuid(e) || getgid(e) != getegid(e);
    }

    function sethostname(string name, string e) internal returns (string) {
        return put("HOSTNAME=" + name, e);
    }

    function gethostname(string e) internal returns (string) {
        return get("HOSTNAME", e);
    }

    function setusershell(string name, string e) internal returns (string) {
        return put("SHELL=" + name, e);
    }

    function getusershell(string e) internal returns (string) {
        return get("SHELL", e);
    }

    /*function getdomainname(char *, int) internal returns (string) {

    }

    function getentropy(void *, size_t) internal returns () {

    }

    function getgrouplist(const char *, gid_t, gid_t *, int *) internal returns () {

    }

    function getloginclass(char *, size_t) internal returns () {

    }

    function getmode(const void *, mode_t) internal returns () {

    }

    function getosreldate(void) internal returns () {

    }

    function getpeereid(int, uid_t *, gid_t *) internal returns () {

    }

    function getresgid(string e) internal returns (uint16, uint16, uint16) {

    }

    function getresuid(string e) internal returns (uint16, uint16, uint16) {

    }

    function setresgid(gid_t, gid_t, gid_t) internal returns () {

    }

    function setresuid(uid_t, uid_t, uid_t) internal returns () {

    }

    function initgroups(const char *, gid_t) internal returns () {

    }

    function iruserok(unsigned long, int, const char *, const char *) internal returns () {

    }

    function iruserok_sa(const void *, int, int, const char *, const char *) internal returns () {

    }

    function reboot(int) internal returns () {

    }

    function revoke(const char *) internal returns () {

    }

    function setdomainname(const char *, int) internal returns () {

    }

    function setgroups(int, const gid_t *) internal returns () {

    }

    function sethostid(long) internal returns () {

    }


    function setlogin(const char *) internal returns () {

    }

    function setloginclass(const char *) internal returns () {

    }

    function setmode(const char *) internal returns () {

    }

    function setpgrp(pid_t, pid_t) internal returns () {

    }


    function setrgid(gid_t) internal returns () {

    }

    function setruid(uid_t) internal returns () {

    }*/
}