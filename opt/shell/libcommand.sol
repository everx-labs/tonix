pragma ton-solidity >= 0.62.0;

import "job_h.sol";
import "libstring.sol";
import "libtable.sol";
import "vars.sol";

// Instructions describing what kind of thing to do for a redirection.
enum r_instruction { r_output_direction, r_input_direction, r_inputa_direction, r_appending_to, r_reading_until, r_reading_string,
  r_duplicating_input, r_duplicating_output, r_deblank_reading_until, r_close_this, r_err_and_out, r_input_output, r_output_force,
  r_duplicating_input_word, r_duplicating_output_word, r_move_input, r_move_output, r_move_input_word, r_move_output_word, r_append_err_and_out }

enum command_type { cm_for, cm_case, cm_while, cm_if, cm_simple, cm_select, cm_connection, cm_function_def, cm_until, cm_group, 
    cm_arith, cm_cond, cm_arith_for, cm_subshell, cm_coproc }

// Structure describing a redirection.  If REDIRECTOR is negative, the parser (or translator in redir.c) encountered an out-of-range file descriptor.
struct s_redirect {
    uint8 redirector;	// Descriptor or varname to be redirected.
    uint16 rflags;      // Private flags for this redirection
    uint16 flags;       // Flag value for `open'.
    r_instruction insn; // What to do with the information.
    uint8 redirectee;	// File descriptor or filename
}

// What a command looks like
struct s_command {
    command_type c_type;   // FOR CASE WHILE IF CONNECTION or SIMPLE.
    uint16 flags;          // Flags controlling execution environment.
    uint16 line;           // line number the command starts on
    s_redirect[] redirects; // Special redirects for FOR CASE, etc.
    simple_com value;
}

struct word_desc {
    string word;  // Zero terminated string.
    uint32 flags; // Flags associated with this word.
}

// The "simple" command.  Just a collection of words and redirects.
struct simple_com {
    uint16 flags;       // See description of CMD flags.
    uint16 line;        // line number the command starts on
    word_desc[] words;  // The program name, the arguments, variable assignments, etc.
    s_redirect[] redirects; // Redirections to perform.
}

library libcommand {

    using libstring for string;
// Possible values for the `flags' field of a WORD_DESC.
    uint32 constant W_HASDOLLAR     = 1 << 0;	// Dollar sign present.
    uint32 constant W_QUOTED        = 1 << 1;	// Some form of quote character is present.
    uint32 constant W_ASSIGNMENT    = 1 << 2;	// This word is a variable assignment.
    uint32 constant W_SPLITSPACE    = 1 << 3;	// Split this word on " " regardless of IFS
    uint32 constant W_NOSPLIT       = 1 << 4;	// Do not perform word splitting on this word because ifs is empty string.
    uint32 constant W_NOGLOB        = 1 << 5;	// Do not perform globbing on this word.
    uint32 constant W_NOSPLIT2      = 1 << 6;	// Don't split word except for $@ expansion (using spaces) because context does not allow it.
    uint32 constant W_TILDEEXP      = 1 << 7;	// Tilde expand this assignment word
    uint32 constant W_DOLLARAT      = 1 << 8;	// $@ and its special handling -- UNUSED
    uint32 constant W_DOLLARSTAR    = 1 << 9;	// $* and its special handling -- UNUSED
    uint32 constant W_NOCOMSUB      = 1 << 10;	// Don't perform command substitution on this word
    uint32 constant W_ASSIGNRHS     = 1 << 11;	// Word is rhs of an assignment statement
    uint32 constant W_NOTILDE       = 1 << 12;	// Don't perform tilde expansion on this word
    uint32 constant W_ITILDE        = 1 << 13;	// Internal flag for word expansion
    uint32 constant W_EXPANDRHS     = 1 << 14;	// Expanding word in ${paramOPword}
    uint32 constant W_COMPASSIGN    = 1 << 15;	// Compound assignment
    uint32 constant W_ASSNBLTIN     = 1 << 16;	// word is a builtin command that takes assignments
    uint32 constant W_ASSIGNARG     = 1 << 17;	// word is assignment argument to command
    uint32 constant W_HASQUOTEDNULL = 1 << 18;	// word contains a quoted null character
    uint32 constant W_DQUOTE        = 1 << 19;	// word should be treated as if double-quoted
    uint32 constant W_NOPROCSUB     = 1 << 20;	// don't perform process substitution
    uint32 constant W_SAWQUOTEDNULL = 1 << 21;	// word contained a quoted null that was removed
    uint32 constant W_ASSIGNASSOC   = 1 << 22;	// word looks like associative array assignment
    uint32 constant W_ASSIGNARRAY   = 1 << 23;	// word looks like a compound indexed array assignment
    uint32 constant W_ARRAYIND      = 1 << 24;	// word is an array index being expanded
    uint32 constant W_ASSNGLOBAL    = 1 << 25;	// word is a global assignment to declare (declare/typeset -g)
    uint32 constant W_NOBRACE       = 1 << 26;	// Don't perform brace expansion
    uint32 constant W_COMPLETE      = 1 << 27;	// word is being expanded for completion
    uint32 constant W_CHKLOCAL      = 1 << 28;	// check for local vars on assignment
    uint32 constant W_NOASSNTILDE   = 1 << 29;	// don't do tilde expansion like an assignment statement
    uint32 constant W_FORCELOCAL    = 1 << 30;	// force assignments to be to local variables, non-fatal on assignment errors

    function add_word(simple_com cmd, string arg) internal {
        word_desc w = as_word(arg);
        cmd.words.push(w);
    }

    function as_word(string arg) internal returns (word_desc) {
        uint32 f;
        if (str.strchr(arg, '$') > 0) f |= W_HASDOLLAR;
        if (str.strchr(arg, '\'') > 0) f |= W_QUOTED;
        if (str.strchr(arg, '=') > 0) f |= W_ASSIGNMENT;
        if (str.strchr(arg, '~') > 0) f |= W_TILDEEXP;
        if (str.strstr(arg, "$@") > 0) f |= W_DOLLARAT;
        if (str.strstr(arg, "$*") > 0) f |= W_DOLLARSTAR;
        return word_desc(arg, f);
    }

    // Flags for the `pflags' argument to param_expand() and various parameter_brace_expand_xxx functions; also used for string_list_dollar_at
    uint8 constant PF_NOCOMSUB     = 0x01; // Do not perform command substitution
    uint8 constant PF_IGNUNBOUND   = 0x02; // ignore unbound vars even if -u set
    uint8 constant PF_NOSPLIT2     = 0x04; // same as W_NOSPLIT2
    uint8 constant PF_ASSIGNRHS	   = 0x08; // same as W_ASSIGNRHS
    uint8 constant PF_COMPLETE     = 0x10; // same as W_COMPLETE, sets SX_COMPLETE
    uint8 constant PF_EXPANDRHS	   = 0x20; // same as W_EXPANDRHS
    uint8 constant PF_ALLINDS      = 0x40; // array, act as if [@] was supplied

    // Possible values for subshell_environment
    uint16 constant SUBSHELL_ASYNC      = 0x01;	// subshell caused by `command &'
    uint16 constant SUBSHELL_PAREN      = 0x02;	// subshell caused by ( ... )
    uint16 constant SUBSHELL_COMSUB     = 0x04;	// subshell caused by `command` or $(command)
    uint16 constant SUBSHELL_FORK       = 0x08;	// subshell caused by executing a disk command
    uint16 constant SUBSHELL_PIPE       = 0x10;	// subshell from a pipeline element
    uint16 constant SUBSHELL_PROCSUB    = 0x20;	// subshell caused by <(command) or >(command)
    uint16 constant SUBSHELL_COPROC     = 0x40;	// subshell from a coproc pipeline
    uint16 constant SUBSHELL_RESETTRAP  = 0x80;	// subshell needs to reset trap strings on first call to trap
    uint16 constant SUBSHELL_IGNTRAP    = 0x100; // subshell should reset trapped signals from trap_handler

    // Possible values for command->flags.
    uint16 constant CMD_WANT_SUBSHELL     = 0x01;   // User wants a subshell: ( command )
    uint16 constant CMD_FORCE_SUBSHELL    = 0x02;   // Shell needs to force a subshell.
    uint16 constant CMD_INVERT_RETURN     = 0x04;   // Invert the exit value.
    uint16 constant CMD_IGNORE_RETURN     = 0x08;   // Ignore the exit value.  For set -e.
    uint16 constant CMD_NO_FUNCTIONS      = 0x10;   // Ignore functions during command lookup.
    uint16 constant CMD_INHIBIT_EXPANSION = 0x20;   // Do not expand the command words.
    uint16 constant CMD_NO_FORK	          = 0x40;   // Don't fork; just call execve
    uint16 constant CMD_TIME_PIPELINE     = 0x80;   // Time a pipeline
    uint16 constant CMD_TIME_POSIX        = 0x100;  // time -p; use POSIX.2 time output spec.
    uint16 constant CMD_AMPERSAND         = 0x200;  // command &
    uint16 constant CMD_STDIN_REDIR       = 0x400;  // async command needs implicit </dev/null
    uint16 constant CMD_COMMAND_BUILTIN   = 0x0800; // command executed by `command' builtin
    uint16 constant CMD_COPROC_SUBSHELL   = 0x1000;
    uint16 constant CMD_LASTPIPE          = 0x2000;
    uint16 constant CMD_STDPATH	          = 0x4000; // use standard path for command lookup
    uint16 constant CMD_TRY_OPTIMIZING    = 0x8000; // try to optimize this simple command

    function _cmd_type(command_type t) internal returns (string) {
        if (t == command_type.cm_simple) return "simple";
        return "unknown";
    }
    function _redir_inst(r_instruction r) internal returns (string) {
        if (r == r_instruction.r_output_direction)        return "%d> %s";
        if (r == r_instruction.r_input_direction)         return "%d< %s";
        if (r == r_instruction.r_inputa_direction)        return "&";
        if (r == r_instruction.r_appending_to)            return "%d>> %s";
//        if (r == r_instruction.r_reading_until)           return "";
        if (r == r_instruction.r_reading_string)          return "%d<<< %s";
        if (r == r_instruction.r_duplicating_input)       return "%d<&%d";
        if (r == r_instruction.r_duplicating_output)      return "%d>&%d";
//        if (r == r_instruction.r_deblank_reading_until)   return "";
        if (r == r_instruction.r_close_this)              return "%d>&-";
        if (r == r_instruction.r_err_and_out)             return "&> %s";
        if (r == r_instruction.r_input_output)            return "%d<> %s";
        if (r == r_instruction.r_output_force)            return "%d>| %s";
        if (r == r_instruction.r_duplicating_input_word)  return "%d<&%s";
        if (r == r_instruction.r_duplicating_output_word) return "%d>&%s";
        if (r == r_instruction.r_move_input)              return "%d<&%d-";
        if (r == r_instruction.r_move_output)             return "%d>&%d-";
        if (r == r_instruction.r_move_input_word)         return "%d<&%s-";
        if (r == r_instruction.r_move_output_word)        return "%d>&%s-";
        if (r == r_instruction.r_append_err_and_out)      return "&>> %s";
    }

    function as_row(s_command cmd) internal returns (string[] res) {
        (command_type c_type, uint16 flags, uint16 line, s_redirect[] redirects, simple_com value) = cmd.unpack();
        res = [_cmd_type(c_type), str.toa(flags), str.toa(line)];
        for (s_redirect rd: redirects)
            res.push(print_redirect(rd));
        res.push(print_simple_command(value));
    }

//    t.add_row(['[' + name + ']+', spid, libjobspec.jobstatus(status), exec_line]);

    function print_word_desc(word_desc w) internal returns (string) {
        (string word, uint32 flags) = w.unpack();
        return word + " " + str.toa(flags);
    }

    function print_simple_command(simple_com cmd) internal returns (string res) {
        (uint16 flags, uint16 line, word_desc[] words, s_redirect[] redirects) = cmd.unpack();
        string[] ss = [str.toa(flags), str.toa(line)];
        for (word_desc wd: words)
            ss.push(print_word_desc(wd));
        for (s_redirect rd: redirects)
            ss.push(print_redirect(rd));
        return libstring.join_fields(ss, " ");
    }

    function print_redirect(s_redirect rd) internal returns (string res) {
        (uint8 redirector, uint16 rflags, uint16 flags, r_instruction insn, uint8 redirectee) = rd.unpack();
        string rfm = _redir_inst(insn);
        rfm.translate("%d", str.toa(redirector));
        rfm.translate("%s", str.toa(redirectee));
        return libstring.join_fields([str.toa(rflags), str.toa(flags), rfm], " ");
    }

    function print_commands(s_command[] cmds) internal returns (string res) {
        string[][] table = [["Type", "Flags", "Line", "Redirects", "Value"]];
        for (s_command cmd: cmds)
            table.push(as_row(cmd));
        return libtable.format_rows(table, [uint(8), 8, 4, 20, 50], libtable.CENTER);
    }

}
