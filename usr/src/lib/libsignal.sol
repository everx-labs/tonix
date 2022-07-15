pragma ton-solidity >= 0.62.0;

import "libstring.sol";

library libsignal {
    uint8 constant SIGHUP   = 1;
    uint8 constant SIGINT   = 2;
    uint8 constant SIGQUIT  = 3;
    uint8 constant SIGILL   = 4;
    uint8 constant SIGTRAP  = 5;
    uint8 constant SIGABRT  = 6;
    uint8 constant SIGBUS   = 7;
    uint8 constant SIGFPE   = 8;
    uint8 constant SIGKILL  = 9;
    uint8 constant SIGUSR1  = 10;
    uint8 constant SIGSEGV  = 11;
    uint8 constant SIGUSR2  = 12;
    uint8 constant SIGPIPE  = 13;
    uint8 constant SIGALRM  = 14;
    uint8 constant SIGTERM  = 15;
    uint8 constant SIGSTKFLT = 16;
    uint8 constant SIGCHLD  = 17;
    uint8 constant SIGCONT  = 18;
    uint8 constant SIGSTOP  = 19;
    uint8 constant SIGTSTP  = 20;
    uint8 constant SIGTTIN  = 21;
    uint8 constant SIGTTOU  = 22;
    uint8 constant SIGURG   = 23;
    uint8 constant SIGXCPU  = 24;
    uint8 constant SIGXFSZ  = 25;
    uint8 constant SIGVTALRM = 26;
    uint8 constant SIGPROF  = 27;
    uint8 constant SIGWINCH = 28;
    uint8 constant SIGIO    = 29;
    uint8 constant SIGPWR   = 30;
    uint8 constant SIGSYS   = 31;
    uint8 constant SIGRTMIN = 34;
    uint8 constant SIGRTMAX = 64;
  /*uint8 constant SIGRTMIN+1             = 35;
  uint8 constant SIGRTMIN+2             = 36;
  uint8 constant SIGRTMIN+3             = 37;
  uint8 constant SIGRTMIN+4             = 38;
  uint8 constant SIGRTMIN+5             = 39;
  uint8 constant SIGRTMIN+6             = 40;
  uint8 constant SIGRTMIN+7             = 41;
  uint8 constant SIGRTMIN+8             = 42;
  uint8 constant SIGRTMIN+9             = 43;
  uint8 constant SIGRTMIN+10            = 44;
  uint8 constant SIGRTMIN+11            = 45;
  uint8 constant SIGRTMIN+12            = 46;
  uint8 constant SIGRTMIN+13            = 47;
  uint8 constant SIGRTMIN+14            = 48;
  uint8 constant SIGRTMIN+15            = 49;
  uint8 constant SIGRTMAX-14            = 50;
  uint8 constant SIGRTMAX-13            = 51;
  uint8 constant SIGRTMAX-12            = 52;
  uint8 constant SIGRTMAX-11            = 53;
  uint8 constant SIGRTMAX-10            = 54;
  uint8 constant SIGRTMAX-9             = 55;
  uint8 constant SIGRTMAX-8             = 56;
  uint8 constant SIGRTMAX-7             = 57;
  uint8 constant SIGRTMAX-6             = 58;
  uint8 constant SIGRTMAX-5             = 59;
  uint8 constant SIGRTMAX-4             = 60;
  uint8 constant SIGRTMAX-3             = 61;
  uint8 constant SIGRTMAX-2             = 62;
  uint8 constant SIGRTMAX-1             = 63;*/

    string constant ESIGINV = "invalid signal specification";
    function get_no(string sval, string[] sigspec) internal returns (bool success, uint8 no, string name) {
        if (sval.empty())
            return (true, SIGTERM, "TERM");
        for (uint i = 0; i < sigspec.length; i++)
            if (sval == sigspec[i])
                return (true, uint8(i), sval);
        return (false, 0, ESIGINV);
    }

    function get_name(uint8 nval, string[] sigspec) internal returns (bool success, uint8 no, string name) {
        if (nval == 0)
            return (true, SIGTERM, "TERM");
        if (nval > SIGRTMAX)
            return (false, 0, ESIGINV);
        name = nval > SIGRTMAX - 15 ? "RTMAX-" + str.toa(SIGRTMAX - 15 + nval) : nval > SIGRTMIN ? "RTMIN+" + str.toa(nval - SIGRTMIN) : sigspec[nval];
        return (true, nval, name);
    }

    function validate(uint8 nval, string sval, string[] sigspec) internal returns (bool success, uint8 no, string name) {
        if (nval == 0)
            return get_no(sval, sigspec);
        if (sval.empty())
            return get_name(nval, sigspec);
        (bool f1, uint8 n1, string s1) = get_no(sval, sigspec);
        if (!f1)
            return (f1, n1, s1);
        (bool f2, uint8 n2, string s2) = get_name(nval, sigspec);
        if (!f2)
            return (f2, n2, s2);
        if (n1 != n2)
            return (false, n2, s2);
        if (s1 != s2)
            return (false, n2, s2);
        return (true, n1, s1);
    }


}