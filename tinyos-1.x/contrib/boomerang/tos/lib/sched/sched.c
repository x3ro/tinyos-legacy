//$Id: sched.c,v 1.1.1.1 2007/11/05 19:11:28 jpolastre Exp $

// This file sched.c is intentionally empty.

// Except for this.  Removing sched.c causes nesc to go apeshit and elide the
// function bodies for __nesc_atomic_start and __nesc_atomic_end.  Marking them
// spontaneous, even here (apparently), does the trick.
__nesc_atomic_t __nesc_atomic_start(void) __attribute__ ((spontaneous));
void __nesc_atomic_end( __nesc_atomic_t reenable_interrupts ) __attribute__ ((spontaneous));

