pragma ton-solidity >= 0.54.0;

import "Shell.sol";

contract history is Shell {

    function _builtin_help() internal pure override returns (BuiltinHelp) {
        return BuiltinHelp(
"history",
"[-c] [-d offset] [n] or history -anrw [filename] or history -ps arg [arg...]",
"Display or manipulate the history list.",
"Display the history list with line numbers, prefixing each modified\n\
entry with a `*'.  An argument of N lists only the last N entries.",
"-c        clear the history list by deleting all of the entries\n\
-d offset delete the history entry at position OFFSET. Negative\n\
                offsets count back from the end of the history list\n\n\
-a        append history lines from this session to the history file\n\
-n        read all history lines not already read from the history file and append them to the history list\n\
-r        read the history file and append the contents to the history list\n\
-w        write the current history to the history file\n\n\
-p        perform history expansion on each ARG and display the result without storing it in the history list\n\
-s        append the ARGs to the history list as a single entry",
"If FILENAME is given, it is used as the history file.  Otherwise,\n\
if HISTFILE has a value, that is used, else ~/.bash_history.\n\n\
If the HISTTIMEFORMAT variable is set and not null, its value is used\n\
as a format string for strftime(3) to print the time stamp associated\n\
with each displayed history entry.  No time stamps are printed otherwise.",
"Returns success unless an invalid option is given or an error occurs.");
    }
}
