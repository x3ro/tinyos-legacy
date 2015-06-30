/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
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
 * Authors:		Phil Levis
 * Date:        Sept 28 2001
 * Desc:        Template for classes.
 *
 */

package net.tinyos.tossim;

import net.tinyos.packet.*;
import javax.swing.*;
import java.lang.reflect.*;

public class InjectorPacketPanel extends JPanel {

    byte[] source = {0x00, 0x00, 0x00, 0x00};
    byte[] destination = {0x10, 0x00, 0x00, 0x00};

    short dest = (short)0xffff;
    byte group = (byte)0x7d;
    byte type = (byte)4;
    short bitmask = 0x7000;
    short moteID = 666;
    
    public InjectorPacketPanel() {super();}
    
    public TOSPacket getPacket() {
	NAMINGPacket packet = new NAMINGPacket();

	Field[] fields = packet.getPacketFields();
	for (int i = 0; i < fields.length; i++) {
	    System.out.println(fields[i].getType().getName());
	}
	try {
	    packet.setTwoByteField("AM_dest", dest);
	    packet.setOneByteField("AM_group", group);
	    packet.setOneByteField("AM_type", type);
	    packet.setByteArrayField("NAMING_source", source);
	    packet.setByteArrayField("NAMING_destination", destination);
	    packet.setTwoByteField("NAMING_bitmask", bitmask);
	    packet.setTwoByteField("NAMING_moteID", moteID);
	    
	
	    System.out.println("getPacket() called on packet panel.");
	    return packet;
	}
	catch (Exception exception) {
	    exception.printStackTrace();
	    return null;
	}
	    
	
    }
}

