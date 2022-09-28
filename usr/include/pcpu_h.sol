pragma ton-solidity >= 0.64.0;

// This structure maps out the global data that needs to be kept on a per-cpu basis.  The members are accessed via the PCPU_GET/SET/PTR
// macros defined in <machine/pcpu.h>.  Machine dependent fields are defined in the PCPU_MD_FIELDS macro defined in <machine/pcpu.h>.
struct pcpu {
	struct thread	*pc_curthread;		/* Current thread */
	struct thread	*pc_idlethread;		/* Idle thread */
	struct thread	*pc_fpcurthread;	/* Fp state owner */
	struct thread	*pc_deadthread;		/* Zombie thread or NULL */
	struct pcb	*pc_curpcb;		/* Current pcb */
	void		*pc_sched;		/* Scheduler state */
	uint64	pc_switchtime;		/* cpu_ticks() at last csw */
	int		pc_switchticks;		/* `ticks' at last csw */
	uint8		pc_cpuid;		/* This cpu number */
	STAILQ_ENTRY(pcpu) pc_allcpu;
	long		pc_cp_time[CPUSTATES];	/* statclock ticks */
	device_t	*pc_device;		/* CPU device handle */
	void		*pc_netisr;		/* netisr SWI cookie */
	uint8		pc_domain;		/* Memory domain. */
	uint	pc_dynamic;		/* Dynamic per-cpu data area */
	uint64	pc_early_dummy_counter;	/* Startup time counter(9) */
	uint	pc_zpcpu_offset;	/* Offset into zpcpu allocs */
}