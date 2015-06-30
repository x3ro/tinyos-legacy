// $Id: CheckpointInit.nc,v 1.3 2003/10/07 21:46:14 idgay Exp $

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

interface CheckpointInit
{
  /**
   * Initialise the checkpointer for checkpoint state. <code>initialised</code>
   * is signaled when initialisation is complete.
   *
   * @param eepromBase The EEPROM line from which the checkpoint state is 
   * stored.
   *
   * @param dataLength The size of data to be checkpointed.
   *
   * @param nDataSets The number of different data sets (all of the same
   * length) which you want to checkpoint. The maximum number is 16 (the
   * EEPROM line size). 
   * 
   * The EEPROM storage requirements are (in EEPROM lines):
   * <p> (<code>nDataSets</code) + 1) * dlines + 4
   * <p>where dlines = (<code>datalength</code> + 15) / 16
   *
   * @return FAIL if the checkpointer cannot be initialised, SUCCESS otherwise
   */
  command result_t init(uint16_t eepromBase, uint16_t dataLength,
			uint8_t nDataSets);

  /**
   * Signaled when the checkpointer is initialised if <code>init</code> 
   * returnd SUCESS.
   * @param cleared TRUE if no valid checkpoint state was found based
   * on the parameters passed to <code>init</code>.
   * @return Ignored.
   */
  event result_t initialised(bool cleared);
}
