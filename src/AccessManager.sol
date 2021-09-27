pragma ton-solidity >= 0.49.0;

import "Internal.sol";
import "Commands.sol";
import "ExportFS.sol";
import "Format.sol";
import "ICache.sol";

contract AccessManager is Internal, Commands, ExportFS, Format, IUserTables {

//    mapping (uint16 => ProcessInfo) public _proc;
    mapping (uint16 => UserInfo) public _users;
    mapping (uint16 => GroupInfo) public _groups;
    uint16 _reg_users_counter;
    uint16 _sys_users_counter;
    uint16 _reg_groups_counter;
    uint16 _sys_groups_counter;
    address _target_device_address;

    mapping (uint16 => Login) public _utmp;
    LoginEvent[] public _wtmp;
    mapping (uint16 => TTY) public _ttys;

    mapping (uint16 => uint16[]) public _group_members;
    mapping (uint16 => uint16[]) public _user_groups;

    mapping (uint16 => bool) public _login_defs_bool;
    mapping (uint16 => uint16) public _login_defs_uint16;
    mapping (uint16 => string) public _login_defs_string;

    mapping (uint16 => bool) public _env_bool;
    mapping (uint16 => uint16) public _env_uint16;
    mapping (uint16 => string) public _env_string;

    uint16 constant FAILLOG_ENAB    = 1;
    uint16 constant LOG_UNKFAIL_ENAB = 2;
    uint16 constant LOG_OK_LOGINS   = 3;
    uint16 constant SYSLOG_SU_ENAB  = 4;
    uint16 constant SYSLOG_SG_ENAB  = 5;
    uint16 constant SULOG_FILE      = 6;
    uint16 constant FTMP_FILE       = 7;
    uint16 constant SU_NAME         = 8;
    uint16 constant ENV_SUPATH      = 9;
    uint16 constant ENV_PATH        = 10;
    uint16 constant TTYGROUP        = 11;
    uint16 constant TTYPERM         = 12;
    uint16 constant UID_MIN         = 13; // Min/max values for automatic uid selection in useradd
    uint16 constant UID_MAX         = 14;
    uint16 constant SYS_UID_MIN     = 15;
    uint16 constant SYS_UID_MAX     = 16;
    uint16 constant GID_MIN         = 17; // Min/max values for automatic gid selection in groupadd
    uint16 constant GID_MAX         = 18;
    uint16 constant SYS_GID_MIN     = 19;
    uint16 constant SYS_GID_MAX     = 20;
    uint16 constant CHFN_RESTRICT   = 21;
    uint16 constant DEFAULT_HOME    = 22;
    uint16 constant USERGROUPS_ENAB = 23;
    uint16 constant CONSOLE_GROUPS  = 24;
    uint16 constant CREATE_HOME     = 25;

    uint8 constant E_SUCCESS       = 0; // success
    uint8 constant E_USAGE         = 2; // invalid command syntax
    uint8 constant E_BAD_ARG       = 3; // invalid argument to option
    uint8 constant E_GID_IN_USE    = 4; // specified group doesn't exist <- copy/paste error
    uint8 constant E_NOTFOUND      = 6; // specified group doesn't exist
    uint8 constant E_NAME_IN_USE   = 9; // group name already in use
    uint8 constant E_GRP_UPDATE    = 10; // can't update group file
    uint8 constant E_CLEANUP_SERVICE = 11; // can't setup cleanup service
    uint8 constant E_PAM_USERNAME  = 12; // can't determine your username for use with pam
    uint8 constant E_PAM_ERROR     = 13; // pam returned an error, see syslog facility id groupmod for the PAM error message

    function update_tables(mapping (uint16 => UserInfo) users, mapping (uint16 => GroupInfo) groups,
        uint16 reg_u, uint16 sys_u, uint16 reg_g, uint16 sys_g) external override accept {
        _users = users;
        _groups = groups;
        _reg_users_counter += reg_u;
        _sys_users_counter += sys_u;
        _reg_groups_counter += reg_g;
        _sys_groups_counter += sys_g;
    }

    function update_users(Session session, UserEvent[] ues) external view accept {
        if (!ues.empty())
            ISourceFS(_target_device_address).update_user_info{value: 0.1 ton, flag: 1}(session, ues);
    }

    function update_logins(Session session, LoginEvent le) external accept {
        (uint8 letype, uint16 user_id, uint16 tty_id, uint32 timestamp) = le.unpack();
        if (timestamp > now || session.pid > _login_defs_uint16[UID_MAX])
            return;
        if (letype == AE_LOGIN) {
            uint16 login_id = uint16(_wtmp.length);
            _wtmp.push(le);
            _utmp[login_id] = Login(user_id, tty_id, 2, now);
            _ttys[tty_id].user_id = user_id;
            _ttys[tty_id].login_id = login_id;
        } else if (letype == AE_LOGOUT) {
            (/*uint8 device_id*/, uint16 t_user_id, uint16 t_login_id) = _ttys[tty_id].unpack();
            _wtmp.push(le);
            if (t_user_id == user_id)
                delete _utmp[t_login_id];
        } else if (letype == AE_SHUTDOWN) {
            _wtmp.push(le);
            for ((uint16 u_login_id, Login u_login): _utmp) {
                (uint16 u_user_id, uint16 u_tty_id, , ) = u_login.unpack();
                _wtmp.push(LoginEvent(AE_LOGOUT, u_user_id, u_tty_id, now));
                delete _utmp[u_login_id];
            }
        }
    }

    function user_admin_op(Session session, InputS input) external view returns (string out, UserEvent ue, Err[] errors, uint16 action) {
        (uint8 c, string[] args, uint flags) = input.unpack();

        session.pid = session.pid;
        if (c == groupadd) (ue, errors) = _groupadd(flags, args);
        if (c == groupdel) (ue, errors) = _groupdel(args);
        if (c == groupmod) (ue, errors) = _groupmod(flags, args);
        if (c == useradd) (ue, errors) = _useradd(flags, args);
        if (c == userdel) (ue, errors) = _userdel(flags, args);
        if (c == usermod) (ue, errors) = _usermod(flags, args);

        out = out;
        if (!errors.empty())
            action = ACT_PRINT_ERRORS;
        else
            action = ACT_UPDATE_USERS;
    }

    function user_access_op(Session session, InputS input) external view returns (string out, LoginEvent le, Err[] errors, uint16 action) {
        (uint8 c, string[] args, uint flags) = input.unpack();
        (, uint16 uid, , ) = session.unpack();
        string login_name = !args.empty() ? args[0] : "";
        UserInfo ui;
        if (_users.exists(uid))
            ui = _users[uid];
        else
            errors.push(Err(login_data_not_found, 0, login_name));

        if (c == login) (le, errors) = _login(flags, session, args, ui);
        if (c == logout) (le, errors) = _logout(session, ui);

        out = out;
        if (!errors.empty())
            action = ACT_PRINT_ERRORS;
        else
            action = ACT_UPDATE_LOGINS;
    }

    function _login(uint flags, Session session, string[] args, UserInfo ui) private view returns (LoginEvent le, Err[] errs) {
        bool force = (flags & _f) > 0;
        bool use_hostname = (flags & _h) > 0;
        bool autologin = (flags & _r) > 0;
        string user_name;
        string host_name;
        if (!args.empty()) {
            user_name = args[0];
            if (args.length > 1 && use_hostname)
                host_name = args[1];
        }

        (uint16 ui_gid, string ui_user_name, string ui_primary_group) = ui.unpack();
        (, , uint16 s_gid, ) = session.unpack();
        if (!force && !autologin && (ui_user_name != user_name || _groups[s_gid].group_name != ui_primary_group || ui_gid != s_gid))
            errs.push(Err(EINVAL, 0, ui_primary_group));
        else
            le = LoginEvent(AE_LOGIN, session.uid, session.pid, now);
    }

    function _logout(Session session, UserInfo ui) private view returns (LoginEvent le, Err[] errs) {
        (uint16 ui_gid, , string ui_primary_group) = ui.unpack();
        (, , uint16 s_gid, ) = session.unpack();
        if (_groups[s_gid].group_name != ui_primary_group || ui_gid != s_gid)
            errs.push(Err(EINVAL, 0, ui_primary_group));
        else
            le = LoginEvent(AE_LOGOUT, session.uid, session.pid, now);
    }

    function user_stats_op(Session session, InputS input) external view returns (string out, Err[] errors, uint16 action) {
        (uint8 c, string[] args, uint flags) = input.unpack();

        if (c == finger) out = _finger(flags, args);
        if (c == last) out = _last(flags);
        if (c == lslogins) (out, errors) = _lslogins(flags, args, session);
        if (c == utmpdump) out = _utmpdump(flags);
        if (c == who) out = _who(flags);

        if (!errors.empty())
            action = ACT_PRINT_ERRORS;
    }

    function _groupadd(uint flags, string[] args) private view returns (UserEvent ue, Err[] errs) {
        bool force = (flags & _f) > 0;
        bool use_group_id = (flags & _g) > 0;
        bool is_system_group = (flags & _r) > 0;

        uint n_args = args.length;
        string target_group_name = args[n_args - 1];
        uint16 target_group_id;
        uint16 options = is_system_group ? UAO_SYSTEM : 0;
        uint16[] added_groups;

        for ((, GroupInfo gi): _groups)
            if (gi.group_name == target_group_name)
                errs.push(Err(E_NAME_IN_USE, 0, target_group_name));

        if (use_group_id && n_args > 1) {
            string group_id_s = args[0];
            (uint gid, bool success) = stoi(group_id_s);
            if (!success)
                errs.push(Err(E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            target_group_id = uint16(gid);
            if (_groups.exists(target_group_id))
                if (force)
                    target_group_id = 0;
                else
                    errs.push(Err(E_GID_IN_USE, 0, group_id_s));
        }

        if (target_group_id == 0)
            target_group_id = is_system_group ? _sys_groups_counter : _reg_groups_counter;

        if (errs.empty())
            ue = UserEvent(UA_ADD_GROUP, target_group_id, target_group_id, options, target_group_name, target_group_name, added_groups);
    }

    function _groupdel(string[] args) private view returns (UserEvent ue, Err[] errs) {
        string victim_group_name = args[0];
        uint16 victim_group_id;
        uint16 options;
        uint16[] removed_groups;

        for ((uint16 group_id, GroupInfo gi): _groups)
            if (gi.group_name == victim_group_name) {
                victim_group_id = group_id;
                removed_groups.push(victim_group_id);
            }

        if (victim_group_id == 0)
            errs.push(Err(E_NOTFOUND, 0, victim_group_name)); // specified group doesn't exist

        for ((, UserInfo ui): _users)
            if (ui.primary_group == victim_group_name)
                errs.push(Err(8, 0, ui.user_name)); // can't remove user's primary group
        if (errs.empty() && !removed_groups.empty())
            ue = UserEvent(UA_DELETE_GROUP, victim_group_id, victim_group_id, options, victim_group_name, victim_group_name, removed_groups);
    }

    function _userdel(uint flags, string[] args) private view returns (UserEvent ue, Err[] errs) {
        bool force = (flags & _f) > 0;
        bool remove_home_dir = (flags & _r) > 0;

        string victim_user_name = args[0];
        uint16 victim_user_id;
        uint16 victim_group_id;
        uint16[] removed_groups;
        bool remove_empty_user_group = _login_def_flag(USERGROUPS_ENAB);

        uint16 options = remove_home_dir ? UAO_REMOVE_HOME_DIR : 0;
        options |= remove_empty_user_group ? UAO_REMOVE_EMPTY_GROUPS : 0;

        for ((uint16 user_id, UserInfo ui): _users)
            if (ui.user_name == victim_user_name) {
                victim_user_id = user_id;
                victim_group_id = ui.gid;
                break;
            }

        if (victim_user_id == 0)
            errs.push(Err(E_NOTFOUND, 0, victim_user_name)); // specified user doesn't exist

        // TODO: check for a running process
        for ((uint16 gid, GroupInfo gi): _groups)
            if (gi.group_name == victim_user_name) {
                if (force)
                    removed_groups.push(gid);
//                else
//                    errs.push(Err(8, 0, victim_user_name)); // can't remove user's primary group
            }
        if (errs.empty())
            ue = UserEvent(UA_DELETE_USER, victim_user_id, victim_group_id, options, victim_user_name, victim_user_name, removed_groups);
    }

    function _useradd(uint flags, string[] args) private view returns (UserEvent ue, Err[] errs) {
        bool create_user_group_def = _login_def_flag(USERGROUPS_ENAB);
        bool create_home_dir_def = _login_def_flag(CREATE_HOME);

//        bool no_log_init = (flags & _l) > 0;
//        bool flag_create_home = (flags & _m) > 0 && (flags & _M) == 0;
        bool is_system_account = (flags & _r) > 0;
        bool create_home_flag = (flags & _m) > 0;
        bool do_not_create_home_flag = (flags & _M) > 0;
        bool create_user_group_flag = (flags & _U) > 0;
        bool do_not_create_user_group_flag = (flags & _N) > 0;

        bool use_user_id = (flags & _u) > 0;
        bool use_group_id = (flags & _g) > 0;
        bool supp_groups_list = (flags & _G) > 0;

        bool create_home_dir = (create_home_dir_def || create_home_flag) && !do_not_create_home_flag;
        bool create_user_group = (create_user_group_def || create_user_group_flag) && !do_not_create_user_group_flag;

        uint n_args = args.length;
        string user_name = args[n_args - 1];
        uint16 group_id;
        uint16 user_id;
        uint16 options = is_system_account ? UAO_SYSTEM : 0;
        options |= create_home_dir ? UAO_CREATE_HOME_DIR : 0;
        options |= create_user_group ? UAO_CREATE_USER_GROUP : 0;

        uint16[] new_group_ids;

        for ((, UserInfo u): _users)
            if (u.user_name == user_name)
                errs.push(Err(E_NAME_IN_USE, 0, user_name));

        if (use_group_id && n_args > 1) {
            string group_id_s = args[0];
            (uint gid, bool success) = stoi(group_id_s);
            if (!success)
                errs.push(Err(E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            group_id = uint16(gid);
            if (!_groups.exists(group_id))
                errs.push(Err(E_NOTFOUND, 0, group_id_s)); // specified group doesn't exist
            else
                new_group_ids = [group_id];
        } else if (use_user_id && n_args > 1) {
            string user_id_s = args[0];
            (uint uid, bool success) = stoi(user_id_s);
            if (!success)
                errs.push(Err(E_BAD_ARG, 0, user_id_s)); // invalid argument to option
            user_id = uint16(uid);
            if (_users.exists(user_id))
                errs.push(Err(E_GID_IN_USE, 0, user_id_s)); // UID already in use (and no -o)
        } else if (supp_groups_list && n_args > 1) {
            string supp_string = args[0];
            string[] supp_list = _split(supp_string, ",");
            for (string s: supp_list) {
                uint16 gid_found = 0;
                for ((uint16 gid, GroupInfo gi): _groups)
                    if (gi.group_name == s)
                        gid_found = gid;
                if (gid_found > 0)
                    new_group_ids.push(gid_found);
                else
                    errs.push(Err(E_NOTFOUND, 0, s));
            }
        }

        if (user_id == 0)
            user_id = is_system_account ? _sys_users_counter : _reg_users_counter;

        if (create_user_group) {
            if (group_id == 0)
                group_id = is_system_account ? _sys_groups_counter : _reg_groups_counter;
        } else {
            if (group_id == 0)
                group_id = is_system_account ? _login_defs_uint16[SYS_GID_MIN] : _login_defs_uint16[GID_MIN];
        }

        if (errs.empty())
            ue = UserEvent(UA_ADD_USER, user_id, group_id, options, user_name, user_name, new_group_ids);
    }

    function _groupmod(uint flags, string[] args) private view returns (UserEvent ue, Err[] errs) {
        bool use_group_id = (flags & _g) > 0;
        bool use_new_name = (flags & _n) > 0;

        uint n_args = args.length;
        string target_group_name = args[n_args - 1];
        uint16 target_group_id;
        uint16 options;
        uint16 new_group_id;
        uint16[] new_group_ids;
        string new_group_name;
        for ((uint16 gid, GroupInfo gi): _groups)
            if (gi.group_name == target_group_name) {
                target_group_id = gid;
                break;
            }

        if (target_group_id == 0)
            errs.push(Err(E_NOTFOUND, 0, target_group_name)); // specified group doesn't exist

        if (use_group_id && n_args > 1) {
            string group_id_s = args[0];
            (uint gid, bool success) = stoi(group_id_s);
            if (!success)
                errs.push(Err(E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            uint16 n_gid = uint16(gid);
            if (_groups.exists(n_gid))
                errs.push(Err(E_GID_IN_USE, 0, group_id_s)); // specified group doesn't exist
            else
                new_group_id = n_gid;
        } else if (use_new_name && n_args > 1) {
            new_group_name = args[0];
            for ((, GroupInfo gi): _groups)
                if (gi.group_name == new_group_name)
                    errs.push(Err(E_NAME_IN_USE, 0, new_group_name));
        }
        if (errs.empty())
            ue = UserEvent(use_group_id ? UA_CHANGE_GROUP_ID : UA_RENAME_GROUP, target_group_id, new_group_id, options, target_group_name, use_new_name ? new_group_name : target_group_name, new_group_ids);
    }

    function _usermod(uint flags, string[] args) private view returns (UserEvent ue, Err[] errs) {
//        bool append_to_supp_groups = (flags & _a) > 0;
        bool change_primary_group = (flags & _g) > 0;
        bool supp_groups_list = (flags & _G) > 0;

        uint n_args = args.length;
        string user_name = args[n_args - 1];
        uint16 user_id;
        uint16 options;
        uint16 group_id;
        string group_name;
        uint16[] group_list;

        for ((uint16 uid, UserInfo ui): _users)
            if (ui.user_name == user_name) {
                user_id = uid;
                break;
            }

        if (user_id == 0)
            errs.push(Err(E_NOTFOUND, 0, user_name)); // specified user doesn't exist

        if (change_primary_group && n_args > 1) {
            string group_id_s = args[0];
            (uint gid, bool success) = stoi(group_id_s);
            if (!success)
                errs.push(Err(E_BAD_ARG, 0, group_id_s)); // invalid argument to option
            group_id = uint16(gid);
            if (!_groups.exists(group_id))
                errs.push(Err(E_NOTFOUND, 0, group_id_s)); // specified group doesn't exist
            group_name = _groups[group_id].group_name;
        } else if (supp_groups_list && n_args > 1) {
            string supp_string = args[0];
            string[] supp_list = _split(supp_string, ",");
            for (string s: supp_list) {
                uint16 gid_found = 0;
                for ((uint16 gid, GroupInfo gi): _groups)
                    if (gi.group_name == s)
                        gid_found = gid;
                if (gid_found > 0)
                    group_list.push(gid_found);
                else
                    errs.push(Err(E_NOTFOUND, 0, s));
            }
        }
        if (errs.empty())
            ue = UserEvent(UA_UPDATE_USER, user_id, group_id, options, user_name, group_name, group_list);
    }

    function _finger(uint flags, string[] args) internal view returns (string out) {
        bool flag_multi_line = (flags & _l) > 0;
//        bool no_names_matching = (flags & _m) > 0;
        bool flag_short_format = (flags & _s) > 0;
        bool short_format = flag_short_format && !flag_multi_line;
        string user_name = args[0];
        string[][] table;
        if (short_format)
            table = [["Login", "Tty", "Idle", "Login Time"]];

        for ((, UserInfo user_info): _users)
            if (user_info.user_name == user_name)
                table.push(short_format ? [user_name, "*", "*", "No logins"] : ["Login: " + user_name, "Directory: /home/" + user_name]);

        out = _format_table(table, " ", "\n", ALIGN_CENTER);
    }

    function _last(uint flags) internal view returns (string out) {
//        bool host_names = (flags & _a) > 0;
//        bool translate_address = (flags & _d) > 0;
//        bool full_dates = (flags & _F) > 0;
//        bool numeric_addresses = (flags & _i) > 0;
//        bool no_host_names = (flags & _R) > 0;
//        bool full_domain_names = (flags & _w) > 0;
        bool shutdown_entries = (flags & _x) > 0;

        string[][] table;

        Column[] columns_format = [
            Column(true, 15, ALIGN_LEFT), // Name
            Column(true, 7, ALIGN_LEFT),
            Column(true, 30, ALIGN_LEFT),
            Column(true, 30, ALIGN_LEFT)];

        mapping (uint16 => uint32) log_ts;
        for (LoginEvent le: _wtmp) {
            (uint8 letype, uint16 user_id, uint16 tty_id, uint32 timestamp) = le.unpack();
            string ui_user_name = _users[user_id].user_name;
            if (letype == AE_LOGIN)
                log_ts[tty_id] = timestamp;
            if (letype == AE_LOGOUT) {
                uint32 login_ts = log_ts[tty_id];
                table.push([
                    ui_user_name,
                    format("{}", tty_id),
                    _ts(login_ts),
                    _ts(timestamp)]);
            }
            if (letype != AE_SHUTDOWN || shutdown_entries)
                table.push([
                    ui_user_name,
                    format("{}", tty_id),
                    format("{}", user_id),
                    _ts(timestamp)]);
        }

        if (!table.empty())
            out = _format_table_ext(columns_format, table, " ", "\n");
        out.append("wtmp begins Mon Mar 22 23:44:55 2021\n");
    }

    function _lslogins(uint flags, string[] args, Session session) internal view returns (string out, Err[] errors) {
        bool print_system = (flags & _s) > 0 || (flags & _u) == 0;
        bool print_user = (flags & _u) > 0 || (flags & _s) == 0;
        string field_separator;
        if ((flags & _c) > 0)
            field_separator = ":";
        field_separator = _if(field_separator, (flags & _n) > 0, "\n");
        field_separator = _if(field_separator, (flags & _r) > 0, " ");
        field_separator = _if(field_separator, (flags & _z) > 0, "\x00");
        if (field_separator.byteLength() > 1)
            return ("Mutually exclusive options\n", [Err(0, mutually_exclusive_options, "")]);
        bool formatted_table = field_separator.empty();
        bool print_all = (print_system || print_user) && args.empty();

        if (formatted_table)
            field_separator = " ";

        string[][] table;
        if (formatted_table)
            table = [["UID", "USER", "GID", "GROUP"]];
        Column[] columns_format = print_all ? [
                Column(print_all, 5, ALIGN_LEFT),
                Column(print_all, 10, ALIGN_LEFT),
                Column(print_all, 5, ALIGN_LEFT),
                Column(print_all, 10, ALIGN_LEFT)] :
               [Column(!print_all, 15, ALIGN_LEFT),
                Column(!print_all, 20, ALIGN_LEFT)];

        if (args.empty() && session.uid < GUEST_USER) {
            for ((uint16 uid, UserInfo user_info): _users) {
                (uint16 gid, string s_owner, string s_group) = user_info.unpack();
                    table.push([format("{}", uid), s_owner, format("{}", gid), s_group]);
            }
        } else {
            string user_name = args[0];
            for ((uint16 uid, UserInfo user_info): _users)
                if (user_info.user_name == user_name) {
                    (uint16 gid, , string s_group) = user_info.unpack();
                    string home_dir = "/home/" + user_name;
                    table = [
                        ["Username:", user_name],
                        ["UID:", format("{}", uid)],
                        ["Home directory:", home_dir],
                        ["Primary group:", s_group],
                        ["GID:", format("{}", gid)]];
                    break;
                }
        }
        out = _format_table_ext(columns_format, table, field_separator, "\n");
    }

    function _utmpdump(uint flags) internal view returns (string out) {
        bool write_back = (flags & _r) > 0;
//        bool write_to_file = (flags & _o) > 0;
        string[][] table;
        Column[] columns_format = [
            Column(true, 5, ALIGN_LEFT),
            Column(true, 7, ALIGN_LEFT),
            Column(true, 7, ALIGN_LEFT),
            Column(!write_back, 5, ALIGN_LEFT),
            Column(true, 30, ALIGN_LEFT)];

        if (write_back)
            for (LoginEvent le: _wtmp) {
                (uint8 letype, uint16 user_id, uint16 tty_id, uint32 timestamp) = le.unpack();
                table.push([format("{}", letype), format("{}", user_id), format("{}", tty_id), _ts(timestamp)]);
            }
        else
            for ((uint16 l_id, Login l): _utmp) {
                (uint16 user_id, uint16 tty_id, uint16 process_id, uint32 login_time) = l.unpack();
                table.push([format("{}", l_id), format("{}", user_id), format("{}", tty_id), format("{}", process_id), _ts(login_time)]);
            }
        if (!table.empty())
            out = _format_table_ext(columns_format, table, " ", "\n");
    }

    function _who(uint flags) internal view returns (string out) {
//        bool all_fields = (flags & _a) > 0;
        bool last_boot_time = (flags & _b) > 0;
//        bool dead_processes = (flags & _d) > 0;
        bool print_headings = (flags & _H) > 0;
        bool system_login_proc = (flags & _l) > 0;
//        bool init_spawned_proc = (flags & _p) > 0;
        bool all_logged_on = (flags & _q) > 0;
        bool default_format = (flags & _s) > 0;
  //      bool last_clock_change = (flags & _t) > 0;
        bool user_message_status = (flags & _T + _w) > 0;
        bool users_logged_in = (flags & _u) > 0;

        if (all_logged_on) {
            uint count;
            for ((, Login l): _utmp) {
                uint16 user_id = l.user_id;
                if (system_login_proc && user_id > _login_defs_uint16[SYS_UID_MAX])
                    continue;
                out.append(_users[user_id].user_name + "\t");
                count++;
            }
            out.append(format("\n# users = {}\n", count));
            return out;
        }

        string[][] table;
        if (print_headings)
            table = [["NAME", "S", "LINE", "TIME", "PID"]];

        if (last_boot_time)
            table.push(["reboot", " ", "~", _ts(_last_boot_time), "1"]);
        Column[] columns_format = [
            Column(true, 15, ALIGN_LEFT), // Name
            Column(user_message_status, 1, ALIGN_LEFT),
            Column(true, 7, ALIGN_LEFT),
            Column(true, 30, ALIGN_LEFT),
            Column(!default_format || users_logged_in, 5, ALIGN_RIGHT)];
        for ((, Login l): _utmp) {
            (uint16 user_id, uint16 tty_id, uint16 process_id, uint32 login_time) = l.unpack();
            if (system_login_proc && user_id > _login_defs_uint16[SYS_UID_MAX])
                continue;
            (, string ui_user_name, ) = _users[user_id].unpack();
            table.push([ui_user_name, "+", format("{}", tty_id), _ts(login_time), format("{}", process_id)]);
        }


        if (!table.empty())
            out = _format_table_ext(columns_format, table, " ", "\n");
    }

    function _init() internal override {
        _export_fs = _get_fs(1, "uadmfs", ["etc"]);

        _init_login_defs();
        _init_groups();
        _init_users();
        _sb_exports.push(_get_export_sb(ROOT_DIR + 3 + 2, 3, "/etc"));
        _target_device_address = address.makeAddrStd(0, 0x41e30674f62ca6b5859e2941488957af5e01c71b886ddd57458aec47315490d5);
    }

    function _login_def_flag(uint16 key) internal view returns (bool) {
        return _login_defs_bool[key];
    }

    function _login_def_value(uint16 key) internal view returns (uint16) {
        return _login_defs_uint16[key];
    }

    function _login_def_string(uint16 key) internal view returns (string) {
        return _login_defs_string[key];
    }

    function _add_data_file(string name, string[] contents) internal {
        uint16 counter = _export_fs.ic++;
        _export_fs.inodes[counter] = _get_any_node(FT_REG_FILE, SUPER_USER, SUPER_USER_GROUP, name, contents);
    }

    function _init_login_defs() internal {
        // /etc/login.defs
        _login_defs_bool[FAILLOG_ENAB] = true;
        _login_defs_bool[LOG_UNKFAIL_ENAB] = true;
        _login_defs_bool[LOG_OK_LOGINS] = true;
        _login_defs_bool[SYSLOG_SU_ENAB] = true;
        _login_defs_bool[SYSLOG_SG_ENAB] = true;
        _login_defs_string[SULOG_FILE] = "/var/log/sulog";
        _login_defs_string[FTMP_FILE] = "/var/log/btmp";
        _login_defs_string[SU_NAME] = "su";
        _login_defs_string[ENV_SUPATH] = "PATH=/bin";
        _login_defs_string[ENV_PATH] = "PATH=/bin";
        _login_defs_string[TTYGROUP] = "tty";
        _login_defs_uint16[TTYPERM] = S_IRUSR + S_IWUSR;
        _login_defs_string[CHFN_RESTRICT] = "rwh";
        _login_defs_bool[DEFAULT_HOME] = true;
        _login_defs_bool[USERGROUPS_ENAB] = true;
        _login_defs_string[CONSOLE_GROUPS] = "floppy:audio:cdrom";
        _add_data_file("login.defs", [
            "FAILLOG_ENAB\tyes",
            "LOG_UNKFAIL_ENAB\tyes",
            "LOG_OK_LOGINS\tyes",
            "SYSLOG_SU_ENAB\tyes",
            "SYSLOG_SG_ENAB\tyes",
            "SULOG_FILE\t/var/log/sulog",
            "FTMP_FILE\t/var/log/btmp",
            "SU_NAME\tsu",
            "ENV_SUPATH\tPATH=/bin",
            "ENV_PATH\tPATH=/bin",
            "TTYGROUP\ttty",
            "TTYPERM\t384",
            "UID_MIN\t1000",
            "UID_MAX\t20000",
            "SYS_UID_MIN\t100",
            "SYS_UID_MAX\t999",
            "GID_MIN\t1000",
            "GID_MAX\t20000",
            "SYS_GID_MIN\t100",
            "SYS_GID_MAX\t999",
            "CHFN_RESTRICT\trwh",
            "DEFAULT_HOME\tyes",
            "USERGROUPS_ENAB\tyes",
            "CONSOLE_GROUPS\tfloppy,audio,cdrom"]);
    }

    function _init_users() internal {
        _login_defs_uint16[UID_MIN] = 1000; // Min/max values for automatic gid selection in groupadd
        _login_defs_uint16[UID_MAX] = 20000;
        _login_defs_uint16[SYS_UID_MIN] = 100;
        _login_defs_uint16[SYS_UID_MAX] = 999;
        _reg_users_counter = _login_defs_uint16[UID_MIN];
        _sys_users_counter = _login_defs_uint16[SYS_UID_MIN];

        _users[SUPER_USER] = UserInfo(SUPER_USER_GROUP, "root", "root");
        _users[_reg_users_counter++] = UserInfo(_reg_groups_counter - 1, "boris", "staff");
        _users[_reg_users_counter++] = UserInfo(_reg_groups_counter - 1, "ivan", "staff");
        _users[GUEST_USER] = UserInfo(GUEST_USER_GROUP, "guest", "guest");
        _add_data_file("passwd", [
            "root\t0\t0\troot\t/root",
            "boris\t1000\t1000\tstaff\t/home/boris",
            "ivan\t1001\t1000\tstaff\t/home/ivan",
            "guest\t10000\t10000\tguest\t/home/guest"]);
    }

    function _init_groups() internal {
        _login_defs_uint16[GID_MIN] = 1000; // Min/max values for automatic gid selection in groupadd
        _login_defs_uint16[GID_MAX] = 20000;
        _login_defs_uint16[SYS_GID_MIN] = 100;
        _login_defs_uint16[SYS_GID_MAX] = 999;
        _reg_groups_counter = _login_defs_uint16[GID_MIN];
        _sys_groups_counter = _login_defs_uint16[SYS_GID_MIN];

        _groups[SUPER_USER_GROUP] = GroupInfo("root", true);
        _groups[_reg_groups_counter++] = GroupInfo("staff", false);
        _groups[GUEST_USER_GROUP] = GroupInfo("guest", false);
        _add_data_file("group", [
            "root\t0",
            "staff\t1000",
            "guest\t10000"]);
    }

}
