/* @(#)DBSensorListener.java
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
 * $\Id$
 */

/**
 * 
 *
 * @author <a href="mailto:szewczyk@sourceforge.net">Robert Szewczyk</a>
 */

package net.tinyos.tools.dbpstore;

import net.tinyos.util.*;
import java.io.*;
import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.sql.*;

public class DBSensorListener implements PacketListenerIF {

    Connection db = null;
    Statement  st = null;
    ResultSet  rs = null;
    String url = "jdbc:mysql://10.212.2.103:3306/penthouse";
    String usr = "bwhull";
    String pwd = "password";
    public static final boolean DEBUG_QUERIES = true;
    public static final boolean DEBUG         = true;
    public static final int FIELD1_POS = 1;
    public static final int FIELD2_POS = 2;
    public static final int FIELD3_POS = 3;
    int count = 0;

    public DBSensorListener( ) {
	
    }

    public void Connect ( ) {
	try {
	    System.out.println ("Connecting to database");
	    Class.forName("org.gjt.mm.mysql.Driver");
	    db = DriverManager.getConnection(url, usr, pwd);
	    st = db.createStatement( );
	} catch (Exception ex) {
	    ex.printStackTrace();
	}
    }
    private short calculateCRC(byte packet[]) {
	short crc;
	int i;
	int index = 0;
	int count = packet.length - 2;
	crc = 0;
	while (--count >= 0) {
	    crc = (short) (crc ^ ((short) (packet[index++]) << 8));
	    i = 8;
	    do {
		if ((crc & 0x8000) != 0)
		    crc = (short)(crc << 1 ^ ((short)0x1021));
		else
		    crc = (short)(crc << 1);
	    } while(--i>0);
	}
	return (crc);
    }

    public void packetReceived(byte[] readings) {
	short crc, pcrc;
	System.out.println("Packet length: "+readings.length);
	crc = calculateCRC(readings);
	pcrc = (short) (((readings[readings.length-1] & 0xff) << 8) +  (readings[readings.length-2] & 0xff));
	if (crc != pcrc)
	    System.out.println("CRC check failed. CRC expected: "+
			       Integer.toHexString(crc&0xffff)+
			       " CRC present: "+
			       Integer.toHexString(pcrc&0xffff));
	if (readings[2] == 8) {
	    StringBuffer buf = new StringBuffer("INSERT INTO sensor_data (moteID, lightVal, tempVal) VALUES ");
	    int ninserts = 0;
	    count++;
	    if (count >20) {
		count = 0;
		System.gc();
	    }
	    for (int i=0; i < 5; i++) {
		int moteid = ((readings[5+i*6]& 0xff) << 8) + ( readings[4+i*6]&0xff);
		if (moteid == 0xffff)
		    break;
		System.out.println ("moteID: " + moteid );
		if ((moteid >= 512) && (moteid < 1024)) {
		    if (i != 0) {
			buf.append(", ");
		    }
		} else {
		    break;
		}
		int data0 = readings[5+i*6+1]&0xff;
		int data1 = readings[5+i*6+2]&0xff;
		int data2 = readings[5+i*6+3]&0xff;
		int sequenceNo = readings[5+i*6+4]&0xff;
		int light = data2+ ((data1 &0x03) << 8);
		int temp = data0 + ((data1 &0x30) << 4);
		buf.append("("+moteid+", "+light+", "+temp+")");
		ninserts++;
		//if (i < readings[3])
		//    buf.append(", ");
		//ps.print(sequenceNo, sequenceNo+ " " + light+ " "+ temp);
	    }
	    System.out.println(buf);
	    if (ninserts != 0) {
		try {
		    st.executeUpdate(buf.toString());
		} catch (SQLException e) {
		    System.err.println("Something BAD happened during the SQL update: "+e);
		    e.printStackTrace();
		}
	    }
	}
    }
}
