// $Id: ByteEEPROM.nc,v 1.1.1.1 2007/11/05 19:09:11 jpolastre Exp $

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
/*
 * Authors:		Nelson Lee, David Gay
 * Date last modified:  7/17/03
 */
/**
 * Provide access to, and sharing of, the mote flash
 * chip. <code>ByteEEPROM</code> does not interact properly with the
 * (deprecated) <code>Logger</code> component.
 *
 * The flash chip is shared by giving each user a separate "region" of the
 * flash. These regions are identified by the parameter to the
 * <code>AllocationReq</code>, <code>WriteData</code>,
 * <code>ReadData</code> and <code>LogData</code> parameterised
 * interfaces. A user of byte eeprom should define a constant with 
 * enum { MY_FLASH_REGION_ID = unique("ByteEEPROM") }; 
 * in some .h file, and use <code>MY_FLASH_REGION_ID</code> when wiring
 * interfaces to <code>ByteEEPROM</code>.
 *
 * Flash regions must be allocated via the <code>AllocationReq</code>
 * interface.  All allocation requests must be made at mote initialisation
 * time (in <code>StdControl.init</code> commands). Later allocation
 * requests will be refused.
 *
 * <code>ReadData</code> and <code>WriteData</code> provides
 * straightforward data reading and writing at arbitrary offsets in a flash
 * region. The <code>WriteData</code> interface guarantees that the data
 * has been committed to the flash when the <code>writeDone</code> event
 * completes successfully. As this has high overhead (both in time and
 * power), the alternative <code>LogData</code> interface is provided for
 * high-speed, low-overhead data logging.
 *
 * The <code>BufferedLog</code> component can be used in conjunction with
 * <code>ByteEEPROM</code> to provide even lower logging overhead at the cost
 * of extra RAM buffers. The <code>HighFrequencySampling</code> application
 * is an example of all this.
 * @author Nelson Lee
 * @author David Gay
 */
configuration ByteEEPROM {
  provides {
    interface AllocationReq[uint8_t id];
    interface WriteData[uint8_t id];
    interface LogData[uint8_t id];
    interface ReadData[uint8_t id];
    interface StdControl;
  }
}
implementation {
  components PageEEPROMC, ByteEEPROMC, ByteEEPROMAllocate;

  AllocationReq = ByteEEPROMAllocate;
  WriteData = ByteEEPROMC;
  LogData = ByteEEPROMC;
  ReadData = ByteEEPROMC;
  StdControl = ByteEEPROMAllocate;
  StdControl = PageEEPROMC;
  
  ByteEEPROMC.PageEEPROM -> PageEEPROMC.PageEEPROM[unique("PageEEPROM")];
  ByteEEPROMC.getRegion -> ByteEEPROMAllocate;
}









