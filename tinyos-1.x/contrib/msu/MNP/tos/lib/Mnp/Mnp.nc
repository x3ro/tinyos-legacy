/**
 * Copyright (c) 2005 - Michigan State University.
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL MICHIGAN STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF MICHIGAN
 * STATE UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * MICHIGAN STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND MICHIGAN STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * MNP interface
 * 
 * Authors: Limin Wang, Sandeep Kulkarni
 * 
 */
 
interface Mnp
{
	// MNP signals application that it wants to receive a new version of program, and asks for permission.
	// The application is supposed to relinquish control to wireless channel and EEPROM, 
	// and may save its state in EEPROM if it needs to restore any state after reboot.
	event result_t downloadRequest(uint16_t progID);
	
	// This event is triggered when download failure occurs. However, this may be temporary, 
	// since a new download process may follow up soon. Currently, we assume the application
	// simply returns SUCCESS. One possibility is that we can use a timer. When it times out,
	// the application can resume its normal operation or restore to some safe point.
	event result_t downloadAborted(uint16_t progID);
	
	// This event is triggered when download process is completed successfully. 
	event result_t downloadDone(uint16_t progID);
	
	// The application grant or deny download request from MNP module.
	command result_t requestGranted(uint16_t progID, bool grant_or_deny);

	// The mote ID and group ID are saved in a special location EEPROM. 
	// After reboot, Mnp.setIDs should be called to set the mote ID and group ID. 
	command result_t setIDs();
}
