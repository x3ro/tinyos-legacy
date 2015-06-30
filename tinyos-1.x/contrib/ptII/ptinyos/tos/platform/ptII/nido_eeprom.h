// $Id: nido_eeprom.h,v 1.1 2005/04/19 01:16:14 celaine Exp $

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
 *
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: eeprom.h
 * AUTHOR: pal
 *   DESC: A flat address space for LOGGER emulation.
 *
 * Anonymous EEPROMs are not kept between simulator invocations. Named
 * EEPROMs are; the name corresponds with a filename.
 *
 * The size of the EEPROM is specified in bytes.
 *
 * A named EEPROM is saved as the smallest file possible. For example,
 * if an EEPROM of 10 motes with 512K of EEPROM is named, it will be
 * 5MB long. If the same named EEPROM is loaded in a later simulation
 * with 20 motes, it will become 10MB long.
 *
 * All functions return 0 on success, -1 on failure.
 */

/**
 * @author Philip Levis
 * @author pal
 */


#ifndef EEPROM_H_INCLUDED
#define EEPROM_H_INCLUDED

int anonymousEEPROM(int numMotes, int eepromSize);
int namedEEPROM(char* name, int numMotes, int eepromSize);

int readEEPROM(char* buffer, int mote, int offset, int length);
int writeEEPROM(char* buffer, int mote, int offset, int length);

int syncEEPROM();

#endif // EEPROM_H_INCLUDED
