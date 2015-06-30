/**
 * Copyright (c) 2003 - The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */



/*
 * Authors: Hongwei Zhang, Anish Arora
 *
 */

includes AM;
includes ReliableComm;

interface ReliableCommControl
{

  /* command to set snooping to be TRUE to FALSE */
  command result_t setSnooping(bool snoop);

  /* command to set a node to be a base station or otherwise */
  command result_t setBase(bool isABase);

  /* command to set whether a node is a child of a base station or not */
  command result_t setBaseChildren(bool isABaseChild);

  /* tune parameters */
  command result_t parameterTuning(ReliableComm_Tuning_Msg * tuningMsgPtr);

  /* log operations */
#ifdef LOG_STATE
  command result_t logState();
#endif
#ifdef REPORT_LOG_WHILE_ALIVE 
  command result_t logToUart();
#endif
}
