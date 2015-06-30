/*                                                                      tab:4
 *
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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

#ifndef EEPROM_H_INCLUDED
#define EEPROM_H_INCLUDED

int anonymousEEPROM(int numMotes, int eepromSize);
int namedEEPROM(char* name, int numMotes, int eepromSize);

int readEEPROM(char* buffer, int mote, int offset, int length);
int writeEEPROM(char* buffer, int mote, int offset, int length);

int syncEEPROM();

#endif // EEPROM_H_INCLUDED
