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
 * WriteToStorage Interface - processes a request from the ULLA
 * Query Processing to update the information in the ULLA Storage.
<p>
 *
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/ 
 

interface WriteToStorage
{

   /** Write bytes to region (erase must be called first)

   * @return FAIL if writes are not allowed.
   * @param offset Offset of data written
   * @param data Address of data written
   * @param numBytesWrite Number of bytes written
   * If the result is SUCCESS, <code>writeDone</code> will be signaled.
   */
  command result_t write(uint32_t offset, uint8_t* data, uint32_t numBytesWrite);
  
  /**
   * Report write completion.
   * @param data Address of data written
   * @param numBytesWrite Number of bytes written
   * @param status SUCCESS if write was successful, FAIL otherwise
   * @return Ignored.
   */
  event result_t writeDone(uint8_t* data, uint32_t numBytes, result_t status);
    
}
