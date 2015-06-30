/* -*-Mode: C; c-file-style: "BSD" -*-					       	tab:4
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
 * $Id: DBLogger.java,v 1.6 2002/07/18 16:21:14 szewczyk Exp $
 */

package net.tinyos.DBListen; 

import java.sql.*;
import java.util.*;

public class DBLogger {

    Connection conn = null;
    private static  String urlPSQL= "jdbc:postgresql:";
    private String m_usr = "birdwatcher";
    private String m_pwd = "mote";
    private final static String insertStmt = "INSERT INTO weather values (now(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    private final static String updateStmt = "UPDATE last_heard SET last_seqno = ? WHERE node_id = ?";
    public DBLogger() {
	try {
		urlPSQL += "//" + InitLogger.pgHost + "/" + InitLogger.dbName;
	    Class.forName ( "org.postgresql.Driver" );
	    conn = DriverManager.getConnection(urlPSQL, m_usr, m_pwd);
		System.out.println("connected to " + urlPSQL);
	} catch (Exception ex) {
	    System.out.println("failed to connect to Postgres!\n");
	    ex.printStackTrace();
	}
	System.out.println("Connected to Postgres!\n");
    }

    public void logPacket(byte[] packet) {
	PreparedStatement  pstmt = null;
	Packet pack = new Packet(packet);
	PreparedStatement uPstmt = null;
	try {
	    int senderAddr = pack.getSenderAddr();
	    int lightReading = pack.getLightReading();
	    int tempReading = pack.getTempReading();
	    int voltageReading = pack.getVoltageReading();
	    int thermopileReading = pack.getThermopileReading();
	    int thermistorReading = pack.getThermistorReading();
	    int humidityReading = pack.getHumidityReading();
	    int intersemaPressureReading = pack.getPressureReading();
	    int intersemaPressureRaw = pack.getPressureRaw();
	    int intersemaTempReading = pack.getITempReading();
	    int intersemaTempRaw = pack.getITempRaw();
	    int seqno = pack.getSeqno();
	    int crc = pack.getCRC();
	    System.out.println("mote= " +
			       String.valueOf(senderAddr) + ", light= " +
			       String.valueOf(lightReading) + ", thermistor= " +
				   String.valueOf(thermistorReading) + ", thermopile= " +
				   String.valueOf(thermopileReading) + ", pressure_mbar= " +
				   String.valueOf(intersemaPressureReading) + ", pressure_temp= " +
				   String.valueOf(intersemaTempReading) + ", humidity= " +
				   String.valueOf(humidityReading) + ", temp= " +
			       String.valueOf(tempReading) + ", voltage= " +
			       String.valueOf(voltageReading) + ", seqno= " +
			       String.valueOf(seqno));
	    pstmt = conn.prepareStatement(insertStmt);
	    pstmt.setInt(1, senderAddr);

	    pstmt.setInt(2, lightReading);
	    pstmt.setInt(3, tempReading);
	    pstmt.setInt(4, thermopileReading);
	    pstmt.setInt(5, thermistorReading);
	    pstmt.setInt(6, humidityReading);
	    pstmt.setInt(7, intersemaPressureReading);
	    pstmt.setInt(8, intersemaPressureRaw);
	    pstmt.setInt(9, intersemaTempReading);
	    pstmt.setInt(10, intersemaTempRaw);
	    pstmt.setInt(11, voltageReading);
	    pstmt.setInt(12, seqno);
	    pstmt.setInt(13, crc);
	    pstmt.setBytes(14, packet);
	    pstmt.executeUpdate();
	    pstmt.close();
	    uPstmt = conn.prepareStatement(updateStmt);
	    uPstmt.setInt(1, seqno);
	    uPstmt.setInt(2, senderAddr);
	    uPstmt.executeUpdate();
	    uPstmt.close();
	}
	catch (Exception ex) {
	    System.out.println("insert failed.\n");
	    ex.printStackTrace();
	}
    }

    public void close() {
	try
	    {
		if (conn != null)
		    conn.close();
		conn = null;
		System.out.println("disconnected from Postgres.\n");
	    }
	catch (Exception e)
	    {
	    }
    }
}

class Packet {
    private final static int DEST_ADDR_BYTE	= 		0;
    private final static int AM_HANDLER_BYTE =		2;
    private final static int GROUP_ID_BYTE	= 		3;
    private final static int SENDER_ADDR_BYTE = 	4;
    private final static int LIGHT_READING_BYTE	= 	5;
    private final static int TEMP_READING_BYTE = 	7;
    private final static int THERMOPILE_READING_BYTE = 9;
    private final static int THERMISTOR_READING_BYTE = 11;
    private final static int HUMIDITY_READING_BYTE = 13;
    private final static int VOLTAGE_READING_BYTE = 15;
    private final static int SEQ_NO_BYTE =			16;

    private final static int ITEMP_RAW_BYTE = 20;
    private final static int PRESSURE_RAW_BYTE = 22;
    private final static int PRESSURE_READING_BYTE = 24;

    private final static int ITEMP_READING_BYTE = 26;

    private final static int CRC_BYTE = 			34;

	
    private byte[]	mPacket;

	public static int unsign(byte b)
	{
		if (b < 0)
			return (int)(b & 0x7f) + 128;
		else
			return (int)b;
	}

	public static int makeInt16(byte low_b, byte high_b)
	{
		return unsign(high_b) << 8 + unsign(low_b);
	}

	public static int makeInt32(byte b0, byte b1, byte b2, byte b3)
	{
		return unsign(b3) << 24 + unsign(b2) << 16 + unsign(b1) << 8 + unsign(b0);
	}

    public Packet(byte[] packet)
	{
	    mPacket = packet;
	}

    public int getSenderAddr()
	{
		
		int x = (mPacket[SENDER_ADDR_BYTE]&0xff);
	    return x;
	}
    public int getLightReading()
	{
	    int x = (mPacket[LIGHT_READING_BYTE]&0xff) + 
		    ((mPacket[LIGHT_READING_BYTE + 1]&0xff) << 8); 
	    
	    return x;
	}
    public int getTempReading()
	{
	    int x = (mPacket[TEMP_READING_BYTE]&0xff) +
		    ((mPacket[TEMP_READING_BYTE + 1] & 0xff) << 8); 
	    return x;
	}
    public int getThermopileReading()
	{
	    int x = (mPacket[THERMOPILE_READING_BYTE]&0xff) + 
		    ((mPacket[THERMOPILE_READING_BYTE + 1]&0xff) << 8); 
	    
	    return x;
	}
    public int getThermistorReading()
	{
	    int x = (mPacket[THERMISTOR_READING_BYTE]&0xff) + 
		    ((mPacket[THERMISTOR_READING_BYTE + 1]&0xff) << 8); 
	    
	    return x;
	}
    public int getHumidityReading()
	{
	    int x = (mPacket[HUMIDITY_READING_BYTE]&0xff) + 
		    ((mPacket[HUMIDITY_READING_BYTE + 1]&0xff) << 8); 
	    
	    return x;
	}
    public int getPressureReading()
	{
	    int x = (mPacket[PRESSURE_READING_BYTE]&0xff) + 
		    ((mPacket[PRESSURE_READING_BYTE + 1]&0xff) << 8); 
	    
	    return x;
	}
    public int getPressureRaw()
	{
	    int x = (mPacket[PRESSURE_RAW_BYTE]&0xff) + 
		    ((mPacket[PRESSURE_RAW_BYTE + 1]&0xff) << 8); 
	    
	    return x;
	}
    public int getITempReading()
	{
	    int x = (mPacket[ITEMP_READING_BYTE]&0xff) + 
		    (mPacket[ITEMP_READING_BYTE + 1] << 8); 
	    
	    return x;
	}
    public int getITempRaw()
	{
	    int x = (mPacket[ITEMP_RAW_BYTE]&0xff) + 
		    ((mPacket[ITEMP_RAW_BYTE + 1]&0xff) << 8); 
	    
	    return x;
	}
    public int getSeqno()
	{
	    int x = ((mPacket[SEQ_NO_BYTE + 3] & 0xff) << 24) +
		    ((mPacket[SEQ_NO_BYTE + 2] & 0xff) << 16) +
		    ((mPacket[SEQ_NO_BYTE + 1] & 0xff) << 8) +
		    (mPacket[SEQ_NO_BYTE] & 0xff);
	    return x;
	}
    public int getVoltageReading()
	{
	    int x = (mPacket[VOLTAGE_READING_BYTE] & 0xff);
	    return x;
	}
    public int getCRC()
	{
	    int x = (mPacket[CRC_BYTE] & 0xff) +
		    ((mPacket[CRC_BYTE+1] & 0xff) << 8); 
	    return x;
	}
    public int getAMHandler()
	{
	    int x = mPacket[AM_HANDLER_BYTE] & 0xff;
	    return x;
	}
}
