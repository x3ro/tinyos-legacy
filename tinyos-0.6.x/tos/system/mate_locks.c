/*									tab:4
 * mate_locks.c - Functions for maintaining locks in Mate.
 *
 * "Copyright (c) 2002 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:   Philip Levis
 * History:   created 4/18/2002
 *
 */

/*static inline void remove_from_queue(context_t* context, lock_t* lock) {
  int i, j;
  for (i = 0; i < 4; i++) {
    if (lock->list[i] == context) {
      lock->size--;
      for (j = i; j < 3; j++) {
	lock->list[j] = lock->list[j + 1];
      }
    }
  }
  }*/

static inline void lock(context_t* context, unsigned char lockNum) {
  lock_t* lock;
  lock = &(VAR(locks)[lockNum]);
#ifdef LOCK_SAFE
  //if (lock->holder != 0) {
  //  enter_error_state(context, 15);
  //  return;
  //  }
#endif
  lock->holder = context;
  context->heldSet |= (1 << lockNum);
  dbg(DBG_USR2, ("VM: (%hhi) Locking lock %i\n", context->which, (int)lockNum));
}

static inline void unlock(context_t* context, unsigned char lockNum) {
  lock_t* lock = &(VAR(locks)[lockNum]);
#ifdef LOCK_SAFE
  //  if (lock->holder != context) {
  //   enter_error_state(context, ERROR_UNLOCK_INVALID);
  //  return;
  // }
#endif
  context->heldSet &= ~(1 << lockNum);
  lock->holder = 0;
  dbg(DBG_USR2, ("VM: (%hhi) Unlocking lock %i\n", context->which, (int)lockNum));
}

void request_lock(context_t* context, lock_t* lock) {

}

char request_locks(context_t* context) {
  //context->yieldVars = 0;
  return 1;
}

