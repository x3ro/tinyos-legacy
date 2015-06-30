/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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

module TinyDBAttrM 
{
	provides interface StdControl;
	uses
	{
		interface AttrRegister as ParentAttr;
#ifdef kCONTENT_ATTR
		interface AttrRegister as ContentionAttr;
#endif
		interface AttrRegister as FreeSpaceAttr;
		interface AttrRegister as QueueLenAttr;
		interface AttrRegister as MHQueueLenAttr;
		interface AttrRegister as DepthAttr;
		interface AttrRegister as QidAttr;
		// interface AttrRegister as XmitCountAttr;
		interface AttrRegister as QualityAttr;
		interface NetworkMonitor;
		interface QueryProcessor;
		interface MemAlloc;
	}
}
implementation 
{
	command result_t StdControl.init()
	{
		call ParentAttr.registerAttr("parent", UINT16, 2);
#ifdef kCONTENT_ATTR
		call ContentionAttr.registerAttr("content", UINT16, 2);
#endif
		call FreeSpaceAttr.registerAttr("freeRAM", UINT16, 2);
		call QueueLenAttr.registerAttr("qlen", UINT8, 1);
		call MHQueueLenAttr.registerAttr("mhqlen", UINT8, 1);
		call DepthAttr.registerAttr("depth", UINT8, 1);
		call QidAttr.registerAttr("qids", UINT16, 2);
		// call XmitCountAttr.registerAttr("xmitcnt", UINT8, 1);
		call QualityAttr.registerAttr("qual", UINT8, 1);
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		return SUCCESS;
	}

	event result_t ParentAttr.startAttr()
	{
		return call ParentAttr.startAttrDone();
	}

	event result_t ParentAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *err)
	{
		*err = SCHEMA_RESULT_READY;
		*(uint16_t*)resultBuf = call NetworkMonitor.getParent();
		return SUCCESS;
	}
	event result_t ParentAttr.setAttr(char *name, char *resultBuf)
	{
		// don't allow manually setting parent
		return FAIL;
	}

#ifdef kCONTENT_ATTR
	event result_t ContentionAttr.startAttr()
	{
		return call ContentionAttr.startAttrDone();
	}

	event result_t ContentionAttr.getAttr(char *name, char* resultBuf, SchemaErrorNo *err) 
	{
		*err = SCHEMA_RESULT_READY;
		*(uint16_t*)resultBuf = call NetworkMonitor.getContention();
		return SUCCESS;
	}

	event result_t ContentionAttr.setAttr(char *name, char* resultBuf) 
	{
		return FAIL; //can't set
	}
#endif

	event result_t FreeSpaceAttr.startAttr()
	{
		return call FreeSpaceAttr.startAttrDone();
	}

  /** FreeSpaceAttr tracks the amount of RAM available in the local heap.
   */
  event result_t FreeSpaceAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *err)
    {
      *err = SCHEMA_RESULT_READY;
      *(uint16_t*)resultBuf = call MemAlloc.freeBytes();
      return SUCCESS;
    }

  event result_t FreeSpaceAttr.setAttr(char *name, char *resultBuf)
    {
      // don't allow manually setting of free space
      return FAIL;
    }
  event result_t MemAlloc.reallocComplete(Handle handle, result_t success)
  {
  	return SUCCESS;
  }
  event result_t MemAlloc.compactComplete()
  {
  	return SUCCESS;
  }
  event result_t MemAlloc.allocComplete(HandlePtr handle, result_t success)
  {
  	return SUCCESS;
  }

	event result_t QueueLenAttr.startAttr()
	{
		return call QueueLenAttr.startAttrDone();
	}

  /** QueueLenAttr returns the send queue length for all messages
   */
  event result_t QueueLenAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *err)
    {
      *err = SCHEMA_RESULT_READY;
	  *(uint8_t*)resultBuf = call NetworkMonitor.getQueueLength();
      return SUCCESS;
    }

  event result_t QueueLenAttr.setAttr(char *name, char *resultBuf)
    {
      // don't allow manually this attribute
      return FAIL;
    }
#if 0
  /** XmitCountAttr returns the number of transmissions for the head
   * of send queue
   */
  event result_t XmitCountAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *err)
    {
      *err = SCHEMA_RESULT_READY;
	  *(uint8_t*)resultBuf = call NetworkMonitor.getXmitCount();
      return SUCCESS;
    }

  event result_t XmitCountAttr.setAttr(char *name, char *resultBuf)
    {
      // don't allow manually setting this attribute
      return FAIL;
    }
#endif
	event result_t QualityAttr.startAttr()
	{
		return call QualityAttr.startAttrDone();
	}

  /** QualityAttr returns a goodness measure of current parent
   */
  event result_t QualityAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *err)
    {
      *err = SCHEMA_RESULT_READY;
	  *(uint8_t*)resultBuf = call NetworkMonitor.getQuality();
      return SUCCESS;
    }

  event result_t QualityAttr.setAttr(char *name, char *resultBuf)
    {
      // don't allow manually setting this attribute
      return FAIL;
    }

	event result_t MHQueueLenAttr.startAttr()
	{
		return call MHQueueLenAttr.startAttrDone();
	}

  /** MHQueueLenAttr returns the send queue length in multihop routing
   */
  event result_t MHQueueLenAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *err)
    {
      *err = SCHEMA_RESULT_READY;
	  *(uint8_t*)resultBuf = call NetworkMonitor.getMHopQueueLength();
      return SUCCESS;
    }

  event result_t MHQueueLenAttr.setAttr(char *name, char *resultBuf)
    {
      // don't allow manually setting of free space
      return FAIL;
    }

	event result_t DepthAttr.startAttr()
	{
		return call DepthAttr.startAttrDone();
	}

  /** DepthAttr returns the depth of the current node in multihop routing tree
   */
  event result_t DepthAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *err)
    {
      *err = SCHEMA_RESULT_READY;
	  *(uint8_t*)resultBuf = call NetworkMonitor.getDepth();
      return SUCCESS;
    }

  event result_t DepthAttr.setAttr(char *name, char *resultBuf)
    {
      // don't allow manually setting of free space
      return FAIL;
    }

	event result_t QidAttr.startAttr()
	{
		return call QidAttr.startAttrDone();
	}

  /** QidAttr returns the qids of the two currently running queries
   */
  event result_t QidAttr.getAttr(char *name, char *resultBuf, SchemaErrorNo *err)
    {
	  short numqs = call QueryProcessor.numQueries();
	  uint8_t qid1 = 0xff, qid2 = 0xff;
      *err = SCHEMA_RESULT_READY;
	  if (numqs >= 1)
	  	qid1 = (uint8_t)((call QueryProcessor.getQueryIdx(0))->qid);
	  if (numqs >= 2)
	  	qid2 = (uint8_t)((call QueryProcessor.getQueryIdx(1))->qid);
	  *(uint8_t*)resultBuf = qid1;
	  *(uint8_t*)(resultBuf + 1) = qid2;
      return SUCCESS;
    }

  event result_t QidAttr.setAttr(char *name, char *resultBuf)
    {
      // don't allow manually setting of free space
      return FAIL;
    }

  event result_t QueryProcessor.queryComplete(ParsedQueryPtr q)
  {
  	return SUCCESS;
  }
}
