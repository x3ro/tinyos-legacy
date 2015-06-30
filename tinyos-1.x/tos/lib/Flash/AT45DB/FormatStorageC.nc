// $Id: FormatStorageC.nc,v 1.1 2005/07/11 23:36:08 idgay Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/*
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author David Gay
 */

includes crc;
includes Storage;
#define HALAT45DB PageEEPROM

configuration FormatStorageC {
  provides interface FormatStorage;
}
implementation {
  components FormatStorageM, Main, PageEEPROMC as HALAT45DBC;

  FormatStorage = FormatStorageM;

  Main.StdControl -> FormatStorageM;
  Main.StdControl -> HALAT45DBC;
  FormatStorageM.HALAT45DB -> HALAT45DBC.HALAT45DB[unique("PageEEPROM")];
}
