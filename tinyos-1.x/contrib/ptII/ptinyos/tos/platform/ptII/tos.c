// $Id: tos.c,v 1.1 2005/04/19 01:16:14 celaine Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

int signaled = 0;

long long rate_checkpoint_time;
double rate_value;

struct timeval startTime;
struct timeval thisTime;

void handle_signal(int sig) __attribute__ ((C, spontaneous)) {
  if ((sig == SIGINT || sig == SIGSTOP) && signaled == 0) {
    char ftime[128];
    printTime(ftime, 128);
    printf("Exiting on SIGINT at %s.\n", ftime);
    // yeah, yeah, this is actually a race condition, but one so rare and
    // unimportant enough (causes SEGFAULT on quit) that we can ignore it.
    signaled = 1;
    exit(0);
  }
}

void init_signals(void) {
  struct sigaction action;
  action.sa_handler = handle_signal;
  sigemptyset(&action.sa_mask);
  action.sa_flags = 0;
  sigaction(SIGINT, &action, NULL);
  signal(SIGPIPE, SIG_IGN);
}

/* There's itoa in the avr-libc, so emulate it here */
char *itoa(int val, char *s, int radix) {
  switch (radix)
    {
    case 8: sprintf(s, "%o", val); return s;
    case 10: sprintf(s, "%d", val); return s;
    case 16: sprintf(s, "%x", val); return s;
    default: abort(); // If you want something else, rewrite this.
    }
}

double get_rate_value() {
  return rate_value;
}

void set_rate_value(double rate) {
  rate_value = rate;
}

void rate_checkpoint() {
  rate_checkpoint_time = tos_state.tos_time;
  gettimeofday(&startTime, NULL);
}


void rate_based_wait() {
  long long rtElapsed;
  long long diffVal;
  long long secondVal;
  gettimeofday(&thisTime, NULL);
  rtElapsed = thisTime.tv_usec - startTime.tv_usec;
  secondVal = thisTime.tv_sec - startTime.tv_sec;
  secondVal *= (long long) 1000000;
  rtElapsed += secondVal;
  rtElapsed *= (long long)4;
  rtElapsed = (long long)((double)rtElapsed * rate_value);
  if ((rtElapsed + 10000) <  (tos_state.tos_time - rate_checkpoint_time)) {
    diffVal = (tos_state.tos_time - rate_checkpoint_time) - rtElapsed;
    diffVal /= 4;
    usleep(diffVal);
  }
}

