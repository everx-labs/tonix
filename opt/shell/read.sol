pragma ton-solidity >= 0.62.0;

import "pbuiltin.sol";

contract read is pbuiltin {

    function _main(shell_env e_in, job_cmd cc) internal pure override returns (uint8 rc, shell_env e) {
        e = e_in;
        string[] page = e.environ[sh.VARIABLE];

        bool assign_to_array = cc.flag_set("a");
//        bool use_delimiter = p.flag_set("d");
        bool echo_input = !cc.flag_set("s");
        string delimiter = " ";
        string sattrs = assign_to_array ? "-a" : "--";
        string input;
        s_of f = e.stdin();//p.fdopen(0, "r");
        string[] params = cc.params();
        if (!f.ferror())
            input = f.gets_s(0);
        else
            rc = EXIT_FAILURE;
        if (assign_to_array) {
            string array_name = "REPLY";
            (string[] fields, ) = input.split(delimiter);
            page.set_var(sattrs, array_name + "=" + libstring.join_fields(fields, " "));
        } else {
            uint n_args = params.length;
            string srem = input;
            for (uint i = 0; i < n_args - 1; i++) {
                (string shead, string stail) = srem.csplit(delimiter);
                page.set_var(sattrs, params[i] + "=" + shead);
                if (i + 2 < n_args)
                    srem = stail;
                else
                    page.set_var(sattrs, params[i + 1] + "=" + stail);
            }
        }
        e.environ[sh.VARIABLE] = page;
        if (echo_input)
            e.puts(input);
    }

    function _builtin_help() internal pure override returns (BuiltinHelp bh) {
        return BuiltinHelp(
_name(),
"[-ers] [-a array] [-d delim] [-i text] [-n nchars] [-N nchars] [-p prompt] [-t timeout] [-u fd] [name ...]",
"Read a line from the standard input and split it into fields.",
"Reads a single line from the standard input, or from file descriptor FD if the -u option is supplied. The line is split\n\
into fields as with word splitting, and the first word is assigned to the first NAME, the second word to the second NAME,\n\
and so on, with any leftover words assigned to the last NAME.  Only the characters found in $IFS are recognized as word\n\
delimiters.\nIf no NAMEs are supplied, the line read is stored in the REPLY variable.",
"-a array  assign the words read to sequential indices of the array variable ARRAY, starting at zero\n\
-d delim  continue until the first character of DELIM is read, rather than newline\n\
-e        use Readline to obtain the line\n\
-i text   use TEXT as the initial text for Readline\n\
-n nchars return after reading NCHARS characters rather than waiting for a newline, but honor a delimiter if fewer than NCHARS\n\
          characters are read before the delimiter\n\
-N nchars return only after reading exactly NCHARS characters, unless EOF is encountered or read times out, ignoring any delimiter\n\
-p prompt output the string PROMPT without a trailing newline before attempting to read\n\
-r        do not allow backslashes to escape any characters\n\
-s        do not echo input coming from a terminal\n\
-u fd     read from file descriptor FD instead of the standard input",
"",
"The return code is zero, unless end-of-file is encountered, read times out (in which case it's greater than 128), a variable assignment\n\
error occurs, or an invalid file descriptor is supplied as the argument to -u.");
    }
    function _name() internal pure override returns (string) {
        return "read";
    }
}
