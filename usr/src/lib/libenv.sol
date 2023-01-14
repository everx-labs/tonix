pragma ton-solidity >= 0.62.0;

import "vars.sol";

library libenv {

    using libstring for string;
    using vars for string[];
    using libenv for string[];

    //  obtains the current value of the environment	variable, name
    function get(string[] e, string name) internal returns (string) {
        return vars.val(name, e);
    }

    function geti(string[] e, string name) internal returns (uint16) {
        string val = get(e, name);
        return str.toi(val);
//        string val = get(name, e);
//        return sgr.toi();
    }

    // inserts or resets the environment variable name in the current environment list.
    // If the variable name does not exist in the list, it is inserted with the given value. If the
    // variable does exist, the argument overwrite is tested; if overwrite is zero, the variable is
    // not reset, otherwise it is reset to the given value.
    function set(string[] e, string name, string value, bool overwrite) internal {
        string val = get(e, name);
        string token = name + "=" + value;
        if (val.empty() || overwrite)
            e.put(token);
    }

    //takes an argument of the form ``name=value'' and puts it directly into the current
    // environment, so altering	the argument shall change the environment. If the variable name does not exist	in the
    // list, it is inserted with the given value. If the variable name does exist, it is	reset to the given value.
    function put(string[] e, string token) internal {
        e.set_var("", token);
    }

    // deletes all instances of the variable name pointed to by name from the list.
    function unset(string[] e, string name) internal {
        e.unset_var(name);
    }

    function getbsize(string[] e) internal returns (uint16, string) {
        return (geti(e, "BLOCKSIZE"), "cells");
    }

    function getuid(string[] e) internal returns (uint16) {
        return geti(e, "UID");
    }

    function geteuid(string[] e) internal returns (uint16) {
        return geti(e, "EUID");
    }

    function getgid(string[] e) internal returns (uint16) {
        return geti(e, "GID");
    }

    function getegid(string[] e) internal returns (uint16) {
        return geti(e, "EGID");
    }

    function setuid(string[] e, uint16 uid) internal {
        e.put("UID=" + str.toa(uid));
    }

    function seteuid(string[] e, uint16 euid) internal {
        e.put("EUID=" + str.toa(euid));
    }

    function setgid(string[] e, uint16 gid) internal {
        e.put("GID=" + str.toa(gid));
    }

    function setegid(string[] e, uint16 egid) internal {
        e.put("EGID=" + str.toa(egid));
    }

    function setregid(string[] e, uint16 rgid, uint16 egid) internal {
        e.setgid(rgid);
        e.setegid(egid);
    }

    function getregid(string[] e) internal returns (uint16, uint16) {
        return (getgid(e), getegid(e));
    }

    function issetugid(string[] e) internal returns (bool) {
        return getuid(e) != geteuid(e) || getgid(e) != getegid(e);
    }

    function sethostname(string[] e, string name) internal {
        e.put("HOSTNAME=" + name);
    }

    function gethostname(string[] e) internal returns (string) {
        return get(e, "HOSTNAME");
    }

    function setusershell(string[] e, string name) internal {
        e.put("SHELL=" + name);
    }

    function getusershell(string[] e) internal returns (string) {
        return get(e, "SHELL");
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