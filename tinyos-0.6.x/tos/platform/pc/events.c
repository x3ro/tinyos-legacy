/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2001 and The Regents of the University 
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
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: events.c
 * AUTHOR: pal
 *   DESC: Implementation of default event behaviors.
 */


#include <stdlib.h>
#include "dbg.h"
#include "events.h"
#include "tos.h"
#include "super.h"

void event_default_cleanup(event_t* event) {
  free(event->data);
}

void event_total_cleanup(event_t* event) {
  free(event->data);
  dbg(DBG_MEM, ("freeing event data: 0x%x\n", (unsigned int)event->data));
  event->data = NULL;
  free(event);
  dbg(DBG_MEM, ("freeing event: 0x%x\n", (unsigned int)event));
}
