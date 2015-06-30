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
 * Desc:        Class responsible for packet injection.
 *
 */

package net.tinyos.tossim;

import java.lang.reflect.*;
import java.io.*;
import java.net.*;
import net.tinyos.packet.*;

public class MulticastInjector {
    private Socket socket;


    byte[] source = {0x00, 0x00, 0x00, 0x00};
    byte[] destination = {(byte)0xf9, (byte)0xf0, 0x00, 0x00};

    short dest = (short)0xffff;
    byte group = (byte)0xad;
    byte type = (byte)13;
    short bitmask = 0x7000;
    short moteID = 666;


    
    public MulticastInjector() {
	try {
	    socket = new Socket("127.0.0.1", 10579);
	}
	catch (Exception exception) {
	    exception.printStackTrace();
	}
    }

    
    public void sendPacket(TOSPacket packet) {
	try {
	    DataOutputStream output = new DataOutputStream(socket.getOutputStream());
	    byte[] data = packet.toByteArray();
	    System.out.println("Packet injection called.");
	    output.writeLong(0);
	    output.writeShort(0);
	    output.write(data);
	}
	catch (Exception exception) {
	    exception.printStackTrace();
	}
    }

    public static void main(String[] args) {
	MulticastInjector injector = new MulticastInjector();

	NAMINGPacket packet = new NAMINGPacket();
	
	Field[] fields = packet.getPacketFields();
	try {
	    packet.setTwoByteField("AM_dest", injector.dest);
	    packet.setOneByteField("AM_group", injector.group);
	    packet.setOneByteField("AM_type", injector.type);
	    packet.setByteArrayField("NAMING_source", injector.source);
	    packet.setByteArrayField("NAMING_destination", injector.destination);
	    packet.setTwoByteField("NAMING_bitmask", injector.bitmask);
	    packet.setTwoByteField("NAMING_moteID", injector.moteID);

	    injector.sendPacket(packet);
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
    }
}

