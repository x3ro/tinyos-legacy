// $Id: Sampling.nc,v 1.3 2003/10/07 21:44:50 idgay Exp $

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
/** 
 * A sampling interface. Note that where sampling data is collected and
 * how that data is recovered is up to each sampling component
 */
interface Sampling {
  /**
   * Prepare to peform sampling. 
   * @param interval The interval in microseconds between samples
   * @param count The number of samples to collect
   * @return If the result is SUCCESS, <code>ready</code> will be signaled
   *   If the result is FAIL, no sampling will happen.
   */
  command result_t prepare(uint32_t interval, uint32_t count);

  /**
   * Report if sampling can be started
   * @param ok SUCCESS if sampling can be started by calling 
   *   <code>start</code>, FAIL otherwise
   * @return Ignored
   */
  event result_t ready(result_t ok);

  /** 
   * Start sampling requested by previous <code>prepare</code>
   * @return SUCCESS if sampling started (<code>done</code> will be signaled
   *   when it complates), FAIL if it didn't.
   */
  command result_t start();

  /**
   * Report sampling completion
   * @param ok SUCCESS if sampling was succesful, FAIL if it failed. Failure
   *   may be due to the sampling interval being too short or to a data
   *   logging problem.
   * @param sampledBytes Number of bytes of sampling data collected
   * @return Ignored
   */
  event result_t done(result_t ok, uint32_t sampledBytes);
}
