pragma ton-solidity >= 0.62.0;
enum job_status { UNDEF, NEW, RUNNING, STOPPED, DONE }
struct job_cmd {
    string cmd;
    string sarg;
    string argv;
    string exec_line;
    string[] pargs;
    string flags;
    uint16 n_args;
    uint8 ec;
    string last;
    string opterr;
    string redir_in;
    string redir_out;
}
struct job_spec {
    uint8 jid;
    uint16 pid;
    job_status status;
    string exec_line;
    job_cmd[] commands;
}
struct job_list {
    uint8 cur_job;
    job_spec[] jobs;
}