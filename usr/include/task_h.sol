pragma ton-solidity >= 0.64.0;
import "bus_h.sol";
import "proc_h.sol";
struct s_task {
    uint32 ta_link;	    // STAILQ_ENTRY(task) link for queue
    uint16 ta_pending;  // count times queued
    uint8 ta_priority;  // Priority
    uint8 ta_flags;	    // Flags
    uint32 ta_func;	    // void task_fn_t(void *context, int pending); task handler
    uint32 ta_context;  // argument for handler
}

//#define	TASK_ENQUEUED		0x1
//#define	TASK_NOENQUEUE		0x2
//#define	TASK_NETWORK		0x4
//
//#define	TASK_IS_NET(ta)		((ta)->ta_flags & TASK_NETWORK)

struct s_gtask {
    uint32 ta_link;   // STAILQ_ENTRY(gtask) link for queue
    uint16 ta_flags;  // state flags
    uint8 ta_priority;// Priority
    uint32 ta_func;	  // void gtask_fn_t(void *context); task handler
    uint32 ta_context;// argument for handler
}

struct grouptask {
    s_gtask	gt_task;
    uint32 gt_taskqueue;
    uint32 gt_list; //	LIST_ENTRY(grouptask)
    uint32 gt_uniq;
    string gt_name; // [GROUPTASK_NAMELEN];
    device_t gt_dev;
    s_resource gt_irq;
    uint8 gt_cpu;
}
//#define	GROUPTASK_NAMELEN	32
enum taskqueue_callback_type {
    TASKQUEUE_CALLBACK_TYPE_INIT,
    TASKQUEUE_CALLBACK_TYPE_SHUTDOWN
}
struct gtaskqueue_busy {
    s_gtask tb_running;
    uint8 tb_seq;
    uint32 tb_link; // LIST_ENTRY(gtaskqueue_busy)
}

struct gtaskqueue {
    uint32 tq_queue; // STAILQ_HEAD(, gtask)
    uint32 tq_active; // LIST_HEAD(, gtaskqueue_busy)
    uint8 tq_seq;
    uint8 tq_callouts;
    uint32 tq_enqueue; // void (*gtaskqueue_enqueue_fn)(void *context);
    uint32 tq_context;
    string tq_name;
    s_thread[] tq_threads;
    uint8 tq_tcount;
    uint8 tq_spin;
    uint8 tq_flags;
    uint32[] tq_callbacks; // taskqueue_callback_fn [TASKQUEUE_NUM_CALLBACKS];
    uint32[] tq_cb_contexts; // [TASKQUEUE_NUM_CALLBACKS];
}
