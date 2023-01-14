pragma ton-solidity >= 0.62.0;
import "sysent_h.sol";
import "proc_h.sol";
import "imgact_h.sol";
import "signal_h.sol";
library libsysent {
    uint32 constant SV_ILP32        = 0x000100;	// 32-bit executable.
    uint32 constant SV_LP64         = 0x000200;	// 64-bit executable.
    uint32 constant SV_IA32         = 0x004000;	// Intel 32-bit executable.
    uint32 constant SV_AOUT         = 0x008000;	// a.out executable.
    uint32 constant SV_SHP          = 0x010000;	// Shared page.
    uint32 constant SV_AVAIL1       = 0x020000;	// Unused
    uint32 constant SV_TIMEKEEP     = 0x040000;	// Shared page timehands.
    uint32 constant SV_ASLR         = 0x080000;	// ASLR allowed.
    uint32 constant SV_RNG_SEED_VER = 0x100000;	// random(4) reseed generation.
    uint32 constant SV_SIG_DISCIGN  = 0x200000;	// Do not discard ignored signals
    uint32 constant SV_SIG_WAITNDQ  = 0x400000;	// Wait does not dequeue SIGCHLD
    uint32 constant SV_DSO_SIG      = 0x800000;	// Signal trampoline packed in dso

    function sv_machine_arch(s_sysentvec sv, s_proc) internal returns (string) {}
    function sv_imgact_try(s_sysentvec sv, s_image_params) internal returns (uint8) {}
    function sv_copyout_auxargs(s_sysentvec sv, s_image_params, uint32) internal returns (uint8) {}
    function sv_copyout_strings(s_sysentvec sv, s_image_params, uint32) internal returns (uint8) {}
    function sv_set_syscall_retval(s_sysentvec sv, s_thread, uint32) internal {

    }
    function sv_fetch_syscall_args(s_sysentvec sv, s_thread) internal returns (uint8) {}
    function sv_schedtail(s_sysentvec sv, s_thread) internal {}
    function sv_thread_detach(s_sysentvec sv, s_thread) internal {}
    function sv_trap(s_sysentvec sv, s_thread) internal returns (uint8) {}
    function sv_sendsig(s_sysentvec sv, uint8, ksiginfo, uint32) internal {}
    function sv_set_fork_retval(s_sysentvec sv, s_thread) internal {}
    function sv_onexec_old(s_sysentvec sv, s_thread td) internal {}
    function sv_onexec(s_sysentvec sv, s_proc, s_image_params) internal returns (uint8) {}
    function sv_onexit(s_sysentvec sv, s_proc) internal {}
    function sv_ontdexit(s_sysentvec sv, s_thread td) internal {}
    function sv_setid_allowed(s_sysentvec sv, s_thread td, s_image_params imgp) internal returns (uint8) {}
}