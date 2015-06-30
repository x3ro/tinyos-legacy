//$Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/Spotlight/Celestron/Constants.java,v 1.1.1.1 2005/05/10 23:37:05 rsto99 Exp $

/* "Copyright (c) 2000-2004 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Author: Radu Stoleru
// Date: 3/26/2005


public class Constants {

    ///////////////////////////////////
    // Manually configurable parameters
	
    // Photo Sensor Configuration
    static final int DEFAULT_THRESHOLD = 70; 
    static final int DEFAULT_DELTA     = 100;
	
    // Packet Retransmission Configuration
    // MAKE SURE DEFAULT_RETRANSMIT_DURATION is a MULTIPLE OF 10, due to bug
    // http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=4500388
    static final int DEFAULT_RETRANSMIT_NUMBER      = 6;	
    static final int DEFAULT_RETRANSMIT_TOTAL_DELAY = 300;   // msec
    static final int DEFAULT_RETRANSMIT_DURATION = 
	DEFAULT_RETRANSMIT_TOTAL_DELAY/DEFAULT_RETRANSMIT_NUMBER;
	
    // ADD these values to the GUI, so that the user can change them
    static final int EVENT_RADIUS = 1;     // meters
    static final int FIELD_LENGTH = 15;    // meters
    static final int FIELD_HEIGHT = 4;     // meters 
    static final int SCAN_SPEED   = 3;     // meters/sec
    static final long BIAS        = -400;  // msec
	
    // Specify the COM ports for the Base Mote and Celestron Mount
    static final String CELESTRON_COM_PORT = "COM1";
    static final String BASE_COM_PORT      = "serial@COM6:mica2";
	



	
    /////////////////////////////////////////////////
    // You don't need to change anything from here on.
	
    // packet information
    static final int packetSize = 36;
    static final int macHeaderSize = 5;
    static final int flagPosition = macHeaderSize;
    static final int recordTypePosition = macHeaderSize + 1;
    static final int messageIDPosition = macHeaderSize + 2;
    static final int dataPosition = 8;

    // sending packets
    static final int sendPacketSize    = 34;
    static final int AM_TYPE           = 55;
    static final int GROUP_ID          = 125;
    static final short TOS_BCAST_ADDR  = (short) 0xffff;
    static final byte BYTE_COUNT       = (byte) 29;
    static final int LENGTH_OFFSET     = 4; 
    static final short DEST_ADDR       = (short) 0xffff;
    static final byte SYNC_REQUEST     = (byte) 10;
    static final byte SYNC_REPLY       = (byte) 20;
    static final int PACKET_TYPE_FIELD = 2;
    
    static final byte CONFIG_INIT     = (byte) 1;
    static final byte CONFIG_REQUEST  = (byte) 11;
    static final byte CONFIG_CLEAR    = (byte) 31; 
    static final byte CONFIG_RESTART  = (byte) 41;    
    static final byte CONFIG_RECONFIG = (byte) 51;         
    static final byte CONFIG_STORE    = (byte) 61; 

    static final long NANO  = 1000000000;
    static final long MICRO = 1000000;
    static final long MILI  = 1000;

    static final int BASE      = 1;
    static final int CELESTRON = 2;
	
}
