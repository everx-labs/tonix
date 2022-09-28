pragma ton-solidity >= 0.62.0;

import "imgact_h.sol";
library libimgact {

    uint8 constant IMGACT_SHELL =	0x1;
    uint8 constant IMGACT_BINMISC =	0x2;
    uint8 constant IMGP_ASLR_SHARED_PAGE =	0x1;

    function exec_alloc_args(s_image_args ) internal returns (uint8) {}
    function exec_args_add_arg(s_image_args args, string argp,  uio_seg segflg) internal returns (uint8) {}
    function exec_args_add_env(s_image_args args, string envp,  uio_seg segflg) internal returns (uint8) {}
    function exec_args_add_fname(s_image_args args, string fname,  uio_seg segflg) internal returns (uint8) {}
    function exec_args_adjust_args(s_image_args args, uint32 consume, uint32 extend) internal returns (uint8) {}
    function exec_args_get_begin_envv(s_image_args args) internal returns (string) {}
    function exec_check_permissions(s_image_params ) internal returns (uint8) {}
//  function exec_cleanup(s_thread td, struct vmspace *) internal returns () {}
    function exec_copyout_strings(s_image_params , uint32) internal returns (uint8) {}
    function exec_free_args(s_image_args ) internal {}
    function exec_map_stack(s_image_params ) internal returns (uint8) {}
    function exec_new_vmspace(s_image_params , s_sysentvec) internal returns (uint8) {}
    function exec_setregs(s_thread , s_image_params, uint32) internal returns () {}
    function exec_shell_imgact(s_image_params ) internal returns (uint8) {}
    function exec_copyin_args(s_image_args , string , uio_seg, string[] , string[]) internal returns (uint8) {}
//  function pre_execve(s_thread td, struct vmspace **oldvmspace) internal returns (uint8) {}
//  function post_execve(s_thread td, int error, struct vmspace *oldvmspace) internal returns () {}

}