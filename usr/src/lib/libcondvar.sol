pragma ton-solidity >= 0.64.0;
import "cv_h.sol";
import "proc_h.sol";
struct s_sleepqueue {
    uint32[] sq_blocked; // s_threadqueue[] [NR_SLEEPQS]; /* (c) Blocked threads. */
    uint32 sq_blockedcnt;//[NR_SLEEPQS];	/* (c) N. of blocked threads. */
    uint32 sq_hash;	// LIST_ENTRY(sleepqueue)	/* (c) Chain and free list. */
    uint32 sq_free;	// LIST_HEAD(, sleepqueue) /* (c) Free queues. */
    uint32 sq_wchan;/// Wait channel
    uint8 sq_type;	/// Queue type
}

struct s_sleepqueue_chain {
    uint32[] sc_queues;	// sc_queues; List of sleep queues.
}

library libcondvar {

    uint8 constant EAGAIN   = 35; // Resource temporarily unavailable
    uint8 constant EWOULDBLOCK = EAGAIN; // Operation would block

//    s_thread constant curthread = s_thread(0, 0, 0, 0, 0, 0, 0, 0, "", 0, 0, 0, 0, 0, 0);
//s_proc td_proc
//uint16 td_tid
//s_sigqueue td_sigqueue
//uint32 td_flags
//uint32 td_pflags
//uint16 td_dupfd
//s_ucred td_realucred
//s_ucred td_ucred
//s_plimit td_limit
//string td_name
//uint8 td_errno
//uint32 td_sigmask
//s_syscall_args td_sa
//td_sigblock_ptr;
//uint32 td_sigblock_val
//td_states td_state
//uint32 td_retval

    uint16 constant CV_WAITERS_BOUND = 0xFFFF;
    uint16 constant SLEEPQ_TYPE     = 0x0ff; // Mask of sleep queue types.
    uint16 constant SLEEPQ_SLEEP    = 0x00;  // Used by sleep/wakeup.
    uint16 constant SLEEPQ_CONDVAR  = 0x01;  // Used for a cv.
    uint16 constant SLEEPQ_PAUSE    = 0x02;  // Used by pause.
    uint16 constant SLEEPQ_SX       = 0x03;  // Used by an sx lock.
    uint16 constant SLEEPQ_LK       = 0x04;  // Used by a lockmgr.
    uint16 constant SLEEPQ_INTERRUPTIBLE = 0x100;   // Sleep is interruptible.
    uint16 constant SLEEPQ_UNFAIR   = 0x200; // Unfair wakeup order.
    uint16 constant SLEEPQ_DROP     = 0x400; // Return without lock held.

    function curthread() internal returns (s_thread) {
    }
    // Look up the sleep queue associated with a given wait channel in the hash table locking the associated sleep queue chain.  If no queue is found in
    // the table, NULL is returned.
    function sleepq_lookup(uint32 wchan) internal returns (s_sleepqueue sq) {
        s_sleepqueue_chain sc;
//      KASSERT(wchan != NULL, ("%s: invalid NULL wait channel", __func__));
//      sc = SC_LOOKUP(wchan);
//      sc = sleepq_chains
//      LIST_FOREACH(sq, sc.sc_queues, sq_hash)
        for (uint32 p: sc.sc_queues) {
            if (sq.sq_wchan == wchan)
                return sq;
        }
    }

    // Block the current thread until it is awakened from its sleep queue.
    function sleepq_wait(uint32 wchan, int8 pri) internal {
//        s_thread td = curthread();
//      MPASS(!(td.td_flags & TDF_SINTR));
        sleepq_switch(wchan, pri);
    }

    // Block the current thread until it is awakened from its sleep queue or it is interrupted by a signal.
    function sleepq_wait_sig(uint32 wchan, int8 pri) internal returns (uint8 rcatch) {
        rcatch = sleepq_catch_signals(wchan, pri);
        if (rcatch > 0)
            return rcatch;
        return sleepq_check_signals();
    }

    // Block the current thread until it is awakened from its sleep queue or it times out while waiting.
    function sleepq_timedwait(uint32 wchan, int8 pri) internal returns (uint8) {
//    	s_thread td = curthread();
//    	MPASS(!(td.td_flags & TDF_SINTR));
    	sleepq_switch(wchan, pri);
    	return sleepq_check_timeout();
    }

    // Block the current thread until it is awakened from its sleep queue, it is interrupted by a signal, or it times out waiting to be awakened.
    function sleepq_timedwait_sig(uint32 wchan, int8 pri) internal returns (uint8) {
        uint8 rcatch = sleepq_catch_signals(wchan, pri);
        // We must always call check_timeout() to clear sleeptimo.
        uint8 rvalt = sleepq_check_timeout();
        uint8 rvals = sleepq_check_signals();
        if (rcatch > 0)
            return rcatch;
        if (rvals > 0)
            return rvals;
        return rvalt;
    }

    // Returns the type of sleepqueue given a waitchannel.
    function sleepq_type(uint32 wchan) internal returns (uint8 stype) {
        s_sleepqueue sq;
//    	MPASS(wchan != NULL);
        sq = sleepq_lookup(wchan);
//    	if (sq == 0)
//    	    return -1;
        stype = sq.sq_type;
        return stype;
    }

    // Check to see if we timed out.
    function sleepq_check_timeout() internal returns (uint8 res) {
//        s_thread td = curthread();
//    	if (td.td_sleeptimo != 0) {
            //if (td.td_sleeptimo <= sbinuptime())
                res = EWOULDBLOCK;
//    	    td.td_sleeptimo = 0;
//    	}
    }

    // Check to see if we were awoken by a signal.
    function sleepq_check_signals() internal returns (uint8) {
//    	s_thread td = curthread();
//    	KASSERT((td.td_flags & TDF_SINTR) == 0, ("thread %p still in interruptible sleep?", td));
//    	return td.td_intrval;
    }

    function sleepq_catch_signals(uint32 wchan, int8 pri) internal returns (uint8 ret) {
//        s_sleepqueue_chain sc = SC_LOOKUP(wchan);
        s_sleepqueue sq;
//      MPASS(wchan != NULL);
        s_thread td = curthread();
//      ret = sleepq_check_ast_sc_locked(td, sc);
        if (ret == 0) {
            // No pending signals and no suspension requests found. Switch the thread off the cpu.
            sleepq_switch(wchan, pri);
        } else {
            // There were pending signals and this thread is still on the sleep queue, remove it from the sleep queue.
//          if (TD_ON_SLEEPQ(td)) {
                sq = sleepq_lookup(wchan);
                sleepq_remove_thread(sq, td);
//          }
//          MPASS(td.td_lock != sc.sc_lock);
        }
        return ret;
    }

//    function CV_ASSERT(cvp, lock, td) internal {
//    	KASSERT((td) != 0, ("%s: td NULL", __func__));
//    	KASSERT(TD_IS_RUNNING(td), ("%s: not TDS_RUNNING", __func__));
//    	KASSERT((cvp) != 0, ("%s: cvp NULL", __func__));
//    	KASSERT((lock) != 0, ("%s: lock NULL", __func__));
//    }

    // Initialize a condition variable.  Must be called before use.
    function cv_init(s_cv cvp, string desc) internal {
        cvp.cv_description = desc;
        cvp.cv_waiters = 0;
    }

    // Destroy a condition variable.  The condition variable must be re-initialized in order to be re-used.
    function cv_destroy(s_cv) internal {
//        s_sleepqueue sq = sleepq_lookup(cvp.cv_wchan);
//      KASSERT(sq == NULL, ("%s: associated sleep queue non-empty", __func__));
    }

    // Wait on a condition variable.  The current thread is placed on the condition variable's wait queue and suspended.  A cv_signal or cv_broadcast on the same
    // condition variable will resume the thread.  The mutex is released before sleeping and will be held on return.  It is recommended that the mutex be
    // held when cv_signal or cv_broadcast are called.
    function _cv_wait(s_cv cvp) internal {
//        s_thread td = curthread();
//      CV_ASSERT(cvp, lock, td);
        cvp.cv_waiters++;
        sleepq_add(cvp.cv_wchan, cvp.cv_description, SLEEPQ_CONDVAR, 0);
        sleepq_wait(cvp.cv_wchan, 0);
    }

    function kick_proc0() internal {}
    function sleepq_add(uint32 wchan, string wmesg, uint16 flags, uint8 queue) internal {}
    function sleepq_switch(uint32 wchan, int8 pri) internal {}
    function sleepq_remove_thread(s_sleepqueue sq, s_thread td) internal {}
    function sleepq_signal(uint32 wchan, uint16 flags, int8 pri, uint8 queue) internal returns (uint8) {}
    function sleepq_broadcast(uint32 wchan, uint16 flags, int8 pri, uint8 queue) internal returns (uint8) {}
    // Wait on a condition variable, allowing interruption by signals.  Return 0 if the thread was resumed with cv_signal or cv_broadcast, EINTR or ERESTART if
    // a signal was caught.  If ERESTART is returned the system call should be restarted if possible.
    function _cv_wait_sig(s_cv cvp) internal returns (uint8 rval) {
//        s_thread td = curthread();
//      CV_ASSERT(cvp, lock, td);
        cvp.cv_waiters++;
        sleepq_add(cvp.cv_wchan, cvp.cv_description, SLEEPQ_CONDVAR | SLEEPQ_INTERRUPTIBLE, 0);
        rval = sleepq_wait_sig(cvp.cv_wchan, 0);
        return rval;
    }

    // Signal a condition variable, wakes up one waiting thread.  Will also wakeup the swapper if the process is not in memory, so that it can bring the
    // sleeping process in.  Note that this may also result in additional threads being made runnable.  Should be called with the same mutex as was passed to
    // cv_wait held.
    function cv_signal(s_cv cvp) internal {
        if (cvp.cv_waiters == 0)
            return;
        if (cvp.cv_waiters == CV_WAITERS_BOUND && sleepq_lookup(cvp.cv_wchan).sq_type == 0) {
            cvp.cv_waiters = 0;
        } else {
            if (cvp.cv_waiters < CV_WAITERS_BOUND)
                cvp.cv_waiters--;
            if (sleepq_signal(cvp.cv_wchan, SLEEPQ_CONDVAR | SLEEPQ_DROP, 0, 0) > 0)
                kick_proc0();
        }
    }

    // Broadcast a signal to a condition variable.  Wakes up all waiting threads. Should be called with the same mutex as was passed to cv_wait held.
    function cv_broadcastpri(s_cv cvp, int8 pri) internal {
        uint8 wakeup_swapper;
        if (cvp.cv_waiters == 0)
            return;
        // XXX sleepq_broadcast pri argument changed from -1 meaning no pri to 0 meaning no pri.
        if (pri == -1)
            pri = 0;
        if (cvp.cv_waiters > 0) {
            cvp.cv_waiters = 0;
            wakeup_swapper = sleepq_broadcast(cvp.cv_wchan, SLEEPQ_CONDVAR, pri, 0);
        }
        if (wakeup_swapper > 0)
            kick_proc0();
    }
}