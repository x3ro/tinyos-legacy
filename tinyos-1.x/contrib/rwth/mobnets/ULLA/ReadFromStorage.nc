/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
/**
 * ReadFromStorage Interface - processes a request from the ULLA
 * Query Processing to access the information in the ULLA Storage.
<p>
 *
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/ 
 

interface ReadFromStorage
{

  /**
   * Read data.
   * @param offset Offset at which to read.
   * @param data Where to place read data
   * @param numBytesRead number of bytes to read
   * @return FAIL if the read request is refused. If the result is SUCCESS, 
   *   the <code>readDone</code> event will be signaled.
   */
  command result_t read(uint32_t offset, uint8_t* buffer, uint32_t numBytesRead);

  /**
   * Signal read completion
   * @param data Address where read data was placed
   * @param numBytesRead Number of bytes read
   * @param status SUCCESS if read was successful, FAIL otherwise
   * @return Ignored.
   */
  event result_t readDone(uint8_t* buffer, uint32_t numBytesRead, result_t status);
  	
  
}
