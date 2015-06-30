/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef PRINTFRADIOMSGS_H
#define PRINTFRADIOMSGS_H

#ifdef PRINTFUART_ENABLED
#include "PrintfUART.h"
#endif

enum {
    AM_PRINTFRADIOMSG = 40
};

//#ifndef PRINTFRADIO_DATA_LENGTH
#define PRINTFRADIO_DATA_LENGTH  (TOSH_DATA_LENGTH-6) // minus sizeof(srcAddr+dataSize+printfNbr)

typedef struct PrintfRadioMsg {
    uint16_t srcAddr;
    uint16_t dataSize;
    uint16_t printfNbr;
    char data[PRINTFRADIO_DATA_LENGTH];
} PrintfRadioMsg;


void PrintfRadioMsg_print(PrintfRadioMsg *prMsgPtr)
{
#ifdef PRINTFUART_ENABLED
    printfUART("PrintfRadioMsg: <srcAddr= %u, size= %u, data= %s\n",
               prMsgPtr->srcAddr, prMsgPtr->dataSize, prMsgPtr->data);
#endif
}

#endif
