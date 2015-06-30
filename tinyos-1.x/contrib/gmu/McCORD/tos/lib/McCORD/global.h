/**
 * Copyright (c) 2008 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

#ifndef __GLOBAL_H__
#define __GLOBAL_H_

enum {
#ifdef PLATFORM_PC
    // Base waits for a while in case other nodes are not booted up yet.
    BASE_BOOT_TIME = 10240, // in milliseconds.
#else
    // For non-simulation, we use a shorter time rather than
    // changing the code structure.
    BASE_BOOT_TIME = 16, // in milliseconds.
#endif
};

void __printEvent(const char * msg) {
#ifdef PLATFORM_PC
   char ftime[128];
   printTime(ftime, 128);
   dbg(DBG_USR1, "%s at %s\n", msg, ftime);
#endif
}

void __receivePage(uint16_t pageId) {
#ifdef PLATFORM_PC
   char ftime[128];
   printTime(ftime, 128);
   dbg(DBG_USR1, "Received whole PAGE %d at %s\n", pageId, ftime);
#endif
}

#ifdef PLATFORM_PC
static uint16_t __gCoreNodes = 0;
static uint16_t __gCompleteNodes = 0;
static uint16_t __gCompleteCoreNodes = 0;
static uint16_t __gFinishedNodes = 0;
#endif

void __reportCore(bool isCoreNode) {
#ifdef PLATFORM_PC
    if (isCoreNode) __gCoreNodes++;
#endif
}

void __receiveAll(bool isCoreNode) {  // Received all pages
#ifdef PLATFORM_PC
    char ftime[128];
    printTime(ftime, 128);

    if (isCoreNode) {
        dbg(DBG_USR1, "Received ALL at %s #%u, Core #%u of %u\n", ftime,
            __gCompleteNodes, __gCompleteCoreNodes, __gCoreNodes);
        __gCompleteNodes++;
        __gCompleteCoreNodes++;
    } else {
        dbg(DBG_USR1, "Received ALL at %s #%u\n", ftime,
            __gCompleteNodes);
        __gCompleteNodes++;
    }
#endif
}
 
void __finish() {  // Received all pages.
#ifdef PLATFORM_PC
    char ftime[128];
    printTime(ftime, 128);

    dbg(DBG_USR1, "FINISHED at %s #%u\n", ftime,
        __gFinishedNodes);
    __gFinishedNodes++;

    if (__gFinishedNodes == tos_state.num_nodes) {
        exit(0);
    }
#endif
}

#endif
