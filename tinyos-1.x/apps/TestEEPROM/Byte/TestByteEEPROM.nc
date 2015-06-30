// $Id: TestByteEEPROM.nc,v 1.4 2003/10/07 21:45:16 idgay Exp $

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
 * Authors:		Nelson Lee
 * Date last modified:  8/27/02
 *
 *
 */
/**
 * This program is a simple test of ByteEEPROM, a component which
 * provides a byte-level abstraction to the EEPROM. This application was used
 * to debug ByteEEPROM, and is a good example on how to wire and use it.
 * @author Nelson Lee
 */

includes Id;
configuration TestByteEEPROM { }
implementation {
  components Main, ByteEEPROM, TestByteEEPROMC, LedsC, GenericComm;

  Main.StdControl -> TestByteEEPROMC.StdControl;

  TestByteEEPROMC.AllocationReq1 -> ByteEEPROM.AllocationReq[TEST_ID1];
  TestByteEEPROMC.WriteData1 -> ByteEEPROM.WriteData[TEST_ID1];
  TestByteEEPROMC.ReadData1 -> ByteEEPROM.ReadData[TEST_ID1];

  TestByteEEPROMC.AllocationReq2 -> ByteEEPROM.AllocationReq[TEST_ID2];
  //TestByteEEPROMC.WriteData2 -> ByteEEPROM.WriteData[TEST_ID2];
  //TestByteEEPROMC.ReadData2 -> ByteEEPROM.ReadData[TEST_ID2];

  TestByteEEPROMC.AllocationReq3 -> ByteEEPROM.AllocationReq[TEST_ID3];
  //TestByteEEPROMC.WriteData3 -> ByteEEPROM.WriteData[TEST_ID3];
  //TestByteEEPROMC.ReadData3 -> ByteEEPROM.ReadData[TEST_ID3];

  TestByteEEPROMC.AllocationReq4 -> ByteEEPROM.AllocationReq[TEST_ID4];
  TestByteEEPROMC.WriteData4 -> ByteEEPROM.WriteData[TEST_ID4];

  TestByteEEPROMC.ByteEEPROMStdControl -> ByteEEPROM;
  TestByteEEPROMC.Leds -> LedsC;
  TestByteEEPROMC.GenericCommStdControl -> GenericComm;
  TestByteEEPROMC.SendMsg -> GenericComm.SendMsg[50];
}
