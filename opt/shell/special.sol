pragma ton-solidity >= 0.61.1;

// special: break : continue . eval exec exit export readonly return set shift times trap unset

import "libshellenv.sol";

contract special {
    function main(shell_env e_in) external pure returns (shell_env e) {
        string c;// = p.p_comm;
        e = _process_command(e_in, c);
    }

    function _process_command(shell_env e_in, string c) internal pure returns (shell_env e) {
        e = e_in;
        if (c == ":") // This utility shall only expand command arguments. It is used when a command is needed, as in the then condition of an if command, but nothing is to be done by the command.
            return e;
        else if (c == "break") // If n is specified, the break utility shall exit from the nth enclosing for, while, or until loop. If n is not specified, break shall behave as if n was specified as 1. Execution shall continue with the command immediately following the exited loop. The value of n is a positive decimal integer. If n is greater than the number of enclosing loops, the outermost enclosing loop shall be exited. If there is no enclosing loop, the behavior is unspecified.
            return e;
        else if (c == "continue") // If n is specified, the continue utility shall return to the top of the nth enclosing for, while, or until loop. If n is not specified, continue shall behave as if n was specified as 1. Returning to the top of the loop involves repeating the condition list of a while or until loop or performing the next assignment of a for loop, and re-executing the loop if appropriate.
            return e;
        else if (c == ".") // The shell shall execute commands from the file in the current environment. If file does not contain a <slash>, the shell shall use the search path specified by PATH to find the directory containing file. Unlike normal command search, however, the file searched for by the dot utility need not be executable. If no readable file is found, a non-interactive shell shall abort; an interactive shell shall write a diagnostic message to standard error, but this condition shall not be considered a syntax error.
            return e;
        else if (c == "eval") // The eval utility shall construct a command by concatenating arguments together, separating each with a <space> character. The constructed command shall be read and executed by the shell.
            return e;
        else if (c == "exec") // The exec utility shall open, close, and/or copy file descriptors as specified by any redirections as part of the command.
        //    If exec is specified without command or arguments, and any file descriptors with numbers greater than 2 are opened with associated redirection statements, it is unspecified whether those file descriptors remain open when the shell invokes another utility. Scripts concerned that child shells could misuse open file descriptors can always close them explicitly, as shown in one of the following examples.
        //  If exec is specified with command, it shall replace the shell with command without creating a new process. If arguments are specified, they shall be arguments to command. Redirection affects the current shell execution environment.
            return e;
        else if (c == "exit") // The exit utility shall cause the shell to exit from its current execution environment with the exit status specified by the unsigned decimal integer n. If the current execution environment is a subshell environment, the shell shall exit from the subshell environment with the specified exit status and continue in the environment from which that subshell environment was invoked; otherwise, the shell utility shall terminate with the specified exit status. If n is specified, but its value is not between 0 and 255 inclusively, the exit status is undefined.
        //    A trap on EXIT shall be executed before the shell terminates, except when the exit utility is invoked in that trap itself, in which case the shell shall exit immediately.
            return e;
        else if (c == "export") // The shell shall give the export attribute to the variables corresponding to the specified names, which shall cause them to be in the environment of subsequently executed commands. If the name of a variable is followed by = word, then the value of that variable shall be set to word.
        // The export special built-in shall support XBD Utility Syntax Guidelines.
        // When -p is specified, export shall write to the standard output the names and values of all exported variables, in the following format:
        // "export %s=%s\n", <name>, <value>
            return e;
        else if (c == "readonly") // The variables whose names are specified shall be given the readonly attribute. The values of variables with the readonly attribute cannot be changed by subsequent assignment, nor can those variables be unset by the unset utility. If the name of a variable is followed by = word, then the value of that variable shall be set to word.
            return e;
        else if (c == "return") // The return utility shall cause the shell to stop executing the current function or dot script. If the shell is not currently executing a function or dot script, the results are unspecified.
            return e;
        else if (c == "set") // If no options or arguments are specified, set shall write the names and values of all shell variables in the collation sequence of the current locale. Each name shall start on a separate line, using the format:
        // "%s=%s\n", <name>, <value>
            return e;
        else if (c == "shift") // The positional parameters shall be shifted. Positional parameter 1 shall be assigned the value of parameter (1+n), parameter 2 shall be assigned the value of parameter (2+n), and so on. The parameters represented by the numbers "$#" down to "$#-n+1" shall be unset, and the parameter '#' is updated to reflect the new number of positional parameters.
        //    The value n shall be an unsigned decimal integer less than or equal to the value of the special parameter '#'. If n is not given, it shall be assumed to be 1. If n is 0, the positional and special parameters are not changed.
            return e;
        else if (c == "times") // The times utility shall write the accumulated user and system times for the shell and for all of its child processes, in the following POSIX locale format:
        // "%dm%fs %dm%fs\n%dm%fs %dm%fs\n", <shell user minutes>,
        // <shell user seconds>, <shell system minutes>,
        // <shell system seconds>, <children user minutes>,
        // <children user seconds>, <children system minutes>,
        // <children system seconds>
            return e;
        else if (c == "trap") // If the first operand is an unsigned decimal integer, the shell shall treat all operands as conditions, and shall reset each condition to the default value. Otherwise, if there are operands, the first is treated as an action and the remaining as conditions.
            // If action is '-', the shell shall reset each condition to the default value. If action is null ( "" ), the shell shall ignore each specified condition if it arises. Otherwise, the argument action shall be read and executed by the shell when one of the corresponding conditions arises. The action of trap shall override a previous action (either default action or one explicitly set). The value of "$?" after the trap action completes shall be the value it had before trap was invoked.
            return e;
        else if (c == "unset")  // Each variable or function specified by name shall be unset.
            // If -v is specified, name refers to a variable name and the shell shall unset it and remove it from the environment. Read-only variables cannot be unset.
            // If -f is specified, name refers to a function and the shell shall unset the function definition.
            // If neither -f nor -v is specified, name refers to a variable; if a variable by that name does not exist, it is unspecified whether a function by that name, if any, shall be unset.
            // Unsetting a variable or function that was not previously set shall not be considered an error and does not cause the shell to abort.
            return e;
    }
}