pragma ton-solidity >= 0.64.0;

struct tailq_head {
    tailq_entry tqh_first; // first element
    uint32 tqh_last;
    mapping (uint32 => tailq_entry) queue;
}

//#define	TAILQ_HEAD_INITIALIZER(head)
//	{ NULL, &(head).tqh_first, TRACEBUF_INITIALIZER }

struct tailq_entry {
    uint32 tqe_ptr;
    uint32 tqe_next; // next element
    uint32 tqe_prev; // address of previous next element
}


struct tailq_head_2 {
//    tailq_entry tqh_first; // first element
    tailq_entry_2 tqh_first; // first element
    tailq_entry_2 tqh_last;
//    uint32 tqh_last;
//    mapping (uint32 => tailq_entry_2) queue;
//    mapping (uint32 => TvmCell) queue;
//    TvmCell[] queue;
    uint8 size;
    tailq_entry_2[] queue;
}
struct tailq_entry_2 {
    uint32 tqe_ptr;
//    uint32 ptr;
//    TvmCell val;
    uint32 tqe_next; // next element
//    TvmCell tqe_next;
    uint32 tqe_prev; // address of previous next element
}
/*#define	TAILQ_CONCAT(head1, head2, field) {
    if (head2.tqh_first > 0) {
        head1.tqh_last = head2.tqh_first;
        head2.tqh_first.field.tqe_prev = head1.tqh_last;
        head1.tqh_last = head2.tqh_last;
        head2.tqh_first = 0;
        head2.tqh_last = head.tqh_first;
    }
}*/
library libqueue {
    function TAILQ_INSERT_TAIL(tailq_head qh, uint32 p) internal {
        tailq_entry elm;
        elm.tqe_next = 0;
        elm.tqe_ptr = p;
        elm.tqe_prev = qh.tqh_last;
        if (qh.tqh_last == 0) {
            qh.tqh_first = elm;
        } else {
            qh.queue[qh.tqh_last].tqe_next = p;
        }
        qh.queue[p] = elm;
        qh.tqh_last = p;
        qh.tqh_first = qh.queue[qh.tqh_first.tqe_ptr];
    }

    function TAILQ_INSERT_TAIL_2(tailq_head_2 qh, uint32 p) internal {
        tailq_entry_2 elm = tailq_entry_2(p, 0, qh.tqh_last.tqe_ptr);
//        elm.tqe_next = p;
//        elm.tqe_ptr = p;
//        elm.tqe_prev = qh.tqh_last;
        if (qh.tqh_first.tqe_ptr == 0) {
            qh.tqh_first = elm;
        } else {
            qh.tqh_last.tqe_next = p;
//            qh.queue[qh.tqh_last].tqe_next = p;
        }
        qh.tqh_last = elm;
        qh.size++;
//        qh.queue.push(elm);
//        qh.tqh_last = p;
//        qh.tqh_first = qh.queue[qh.tqh_first.tqe_ptr];
    }

    function TAILQ_INSERT_HEAD(tailq_head qh, tailq_entry elm) internal {
        if ((elm.tqe_next = qh.tqh_first.tqe_ptr) > 0)
            qh.tqh_first.tqe_prev = elm.tqe_next;
        else
            qh.tqh_last = elm.tqe_next;
        qh.tqh_first = elm;
        elm.tqe_prev = qh.tqh_first.tqe_ptr;
    }

    function TAILQ_EMPTY(tailq_head qh) internal returns (bool) {
        return qh.tqh_first.tqe_ptr == 0;
    }

    function TAILQ_FIRST(tailq_head qh) internal returns (tailq_entry) {
        return qh.tqh_first;
    }

    function TAILQ_LAST(tailq_head qh) internal returns (tailq_entry) {
        return qh.queue[qh.tqh_last];
    }

    function TAILQ_NEXT(tailq_head qh, tailq_entry elm) internal returns (tailq_entry) {
        return qh.queue[elm.tqe_next];
    }

    function TAILQ_PREV(tailq_head qh, tailq_entry elm) internal returns (tailq_entry) {
        return qh.queue[elm.tqe_prev];
    }

//    function TAILQ_FOREACH(tailq_head qh) internal returns (tailq_entry[] res) {
    function TAILQ_FOREACH(tailq_head qh) internal returns (uint32[] res) {
        tailq_entry vv = qh.tqh_first;
        uint32 p = vv.tqe_ptr;
        while (p > 0) {
//            if (qh.iter == 0 || qh.iter(vv))
            if (iter_def(vv))
                res.push(p);
            p = vv.tqe_next;
            vv = qh.queue[p];
        }
    }
    /*function TAILQ_FOREACH_2(tailq_head_2 qh) internal returns (uint32[] res) {
        tailq_entry_2 vv = qh.tqh_first;
        uint32 p = vv.tqe_ptr;
        while (p > 0) {
//            if (qh.iter == 0 || qh.iter(vv))
            if (iter_def_2(vv))
                res.push(vv.tqe_ptr);
            vv = vv.tqe_next;
//            vv = qh.queue[p];
        }
    }*/
//    function TAILQ_FOREACH_REVERSE(tailq_head qh) internal returns (tailq_entry[] res) {
    function TAILQ_FOREACH_REVERSE(tailq_head qh) internal returns (uint32[] res) {
    	for ((uint32 p, tailq_entry vv): qh.queue) {
//            if (qh.iter == 0 || qh.iter(vv))
            if (iter_def(vv))
                res.push(p);
        }
    }
    /*function TAILQ_FOREACH_FROM(var, head, field)  internal {
        for (var = (var ? var : head.tqh_first);
        var;
        var = var.field.tqe_next;
    }*/
    function iter_def(tailq_entry qe) internal returns (bool) {
        if (qe.tqe_ptr > 0)
            return true;
        return false;
    }
    /*function iter_def_2(tailq_entry_2 qe) internal returns (bool) {
        if (qe.tqe_ptr > 0)
            return true;
        return false;
    }*/
    function TAILQ_INIT(tailq_head qh) internal {
        qh.tqh_last = qh.tqh_first.tqe_ptr;
//        head.queue[head.tqh_last] = head.tqh_first;
    }
//    function TAILQ_INIT_2(tailq_head_2 qh) internal {
//        qh.tqh_last = qh.tqh_first.tqe_ptr;
//        head.queue[head.tqh_last] = head.tqh_first;
//    }
    function TAILQ_INSERT_AFTER(tailq_head qh, tailq_entry listelm, tailq_entry elm) internal {
        elm.tqe_next = listelm.tqe_next;
        if (elm.tqe_next > 0)
            qh.queue[elm.tqe_next].tqe_prev = elm.tqe_next;
        else {
            qh.tqh_last = elm.tqe_next;
        }
        listelm.tqe_next = elm.tqe_ptr;
        elm.tqe_prev = listelm.tqe_next;
    }

    function TAILQ_INSERT_BEFORE(tailq_head qh, tailq_entry listelm, tailq_entry elm) internal {
	    elm.tqe_prev = listelm.tqe_prev;
	    elm.tqe_next = listelm.tqe_ptr;
	    qh.queue[listelm.tqe_prev] = elm;
	    listelm.tqe_prev = qh.queue[elm.tqe_next].tqe_ptr;
    }

    function TAILQ_REMOVE(tailq_head qh, tailq_entry elm) internal {
        if (elm.tqe_next > 0)
            qh.queue[elm.tqe_next].tqe_prev = elm.tqe_prev;
        else {
            qh.tqh_last = elm.tqe_prev;
        }
        qh.queue[elm.tqe_prev] = qh.queue[elm.tqe_next];
    }

    function TAILQ_PRINT_HEAD(tailq_head h) internal returns (string out) {
        (tailq_entry tqh_first, uint32 tqh_last, mapping (uint32 => tailq_entry) queue) = h.unpack();
//        return format("[first: {} last: {} p_last: {}]\n", TAILQ_PRINT_ENTRY(tqh_first), TAILQ_PRINT_ENTRY(tqh_last), p_tqh_last);
        out = format("[first: {} last: {}\n", TAILQ_PRINT_ENTRY(tqh_first), tqh_last);
        for ((uint32 p, tailq_entry vv): queue)
            out.append(format("[{}] => {}\n", p, TAILQ_PRINT_ENTRY(vv)));
    }
    function TAILQ_PRINT_ENTRY(tailq_entry elm) internal returns (string out) {
        (uint32 tqe_ptr, uint32 tqe_next, uint32 tqe_prev) = elm.unpack();
        return format("({} -> [{}] -> {})\t", tqe_prev, tqe_ptr, tqe_next);
    }
    /*function TAILQ_PRINT(tailq q) internal returns (string out) {
        (tailq_head head, tailq_entry first, uint32 last, mapping (uint32 => tailq_entry) queue, ) = q.unpack();
        out = format("---\nhead: {} first: {} last: {}---\n", TAILQ_PRINT_HEAD(head), TAILQ_PRINT_ENTRY(first), last);
        for ((uint32 p, tailq_entry vv): queue) {
            out.append(format("[{}] => {}\n", p, TAILQ_PRINT_ENTRY(vv)));
        }
    }*/
}