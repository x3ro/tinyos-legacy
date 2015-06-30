/*									tab:4*/
/* Bug report to: Lin Gu <lingu@cs.virginia.edu> */

module PeekerM
{
  provides {
    interface StdControl;
    interface Peek;
  }
  uses {
    interface SendMsg as SendPeekMsg;
    interface StdControl as SubControl;
  }
}

implementation
{
#define PK_MSG_LEN 24

  typedef struct
  {
    uint16_t n2;
    uint16_t nReal2, n3, n4;
    char cFiller;
  } PeekMsg;

  result_t output(uint16_t addr, uint16_t nLen);

  TOS_Msg msgPeek;
  PeekMsg *ppm;
  uint16_t *pnPos, *pnEnd, *pnBegin, nSeq;
  char *pcPos, *pcEnd, *pcBegin;

  command result_t StdControl.init() {
    ppm = (PeekMsg *)(msgPeek.data);
    pnBegin = (uint16_t *)(((char *)ppm)+3);
    pcBegin = (char *)pnBegin;
    pnPos = pnBegin;
    pcPos = (char *)pnPos;
    pnEnd = (uint16_t *)(((char *)pnBegin) + (PK_MSG_LEN-2));
    pcEnd = (char *)pnEnd;
    nSeq = 0;

    call SubControl.init();

    dbg(DBG_BOOT, "PeekerM: init\n");

    return SUCCESS;
  }

  command result_t StdControl.start() {
    call SubControl.start();

    return SUCCESS;
  }

  command result_t StdControl.stop() {
    call SubControl.stop();

    return SUCCESS;
  }

  command result_t Peek.printInt2(uint16_t data) {
    ppm->n2 = data;
    output(TOS_UART_ADDR, 2);

    return SUCCESS;
  }

  command result_t Peek.print4Int(uint16_t n1, uint16_t n2, uint16_t n3, uint16_t n4)
    {
      ppm->n2 = n1;
      ppm->nReal2 = n2;
      ppm->n3 = n3;
      ppm->n4 = n4;

      output(TOS_UART_ADDR, 9);

      return SUCCESS;
    } // print4Int

  command result_t Peek.bcastInt2(uint16_t data) {
    ppm->n2 = data;
    output(TOS_BCAST_ADDR, 2);

    return SUCCESS;
  }

  command result_t Peek.lazyBcastInt2(uint16_t data) {
    *pnPos = data;

    if ((++pnPos) == pnEnd)
      {
	pnPos = pnBegin;
	ppm->n2 = nSeq;
	*pnEnd = nSeq;
	output(TOS_BCAST_ADDR, PK_MSG_LEN+3);
	if (nSeq &0x1)
	  {
	    TOSH_CLR_RED_LED_PIN();
	  }
	else
	  {
	    TOSH_SET_RED_LED_PIN();
	  }
      }

    nSeq++;

    return SUCCESS;
  }

  command result_t Peek.lazyBcastChar(char data) {
    *pcPos = data;

    if ((++pcPos) == pcEnd)
      {
	pcPos = pcBegin;
	ppm->n2 = nSeq;
	*pnEnd = nSeq;
	output(TOS_BCAST_ADDR, PK_MSG_LEN+3);
	if (nSeq &0x2)
	  {
	    TOSH_CLR_RED_LED_PIN();
	  }
	else
	  {
	    TOSH_SET_RED_LED_PIN();
	  }
      }

    nSeq++;

    return SUCCESS;
  }

  result_t output(uint16_t addr, uint16_t nLen)
  {
    call SendPeekMsg.send(addr, nLen, (TOS_MsgPtr)(&msgPeek));

    return SUCCESS;
  }

  event result_t SendPeekMsg.sendDone(TOS_MsgPtr pmsgDone, result_t r)
    {
      return SUCCESS;
    } // sendDone
}

/*
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of Virginia.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Lin Gu
 * Date last modified:  6/12/03
 *
 */

