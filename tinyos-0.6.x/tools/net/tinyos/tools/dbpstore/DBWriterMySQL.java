package net.tinyos.tools.dbpstore;

import java.sql.*;
import java.util.*;

public class DBWriterMySQL {

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

    public DBWriterMySQL( ) {
	
    }

    public void Connect ( ) {
	try {
	    System.out.println ("Connecting to database");
	    Class.forName("org.gjt.mm.mysql.Driver");
	    db = DriverManager.getConnection(url, usr, pwd);
	    db.setAutoCommit (false);
	    st = db.createStatement( ResultSet.TYPE_SCROLL_SENSITIVE,
				    ResultSet.CONCUR_UPDATABLE );
	} catch (Exception ex) {
	    ex.printStackTrace();
	}
    }

    public void Close ( ) throws Exception {
	if ( st != null ) { st.close ( ); }
	if ( db != null ) { db.close ( ); }
	st = null;
	db = null;
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
        
    public boolean WriteSensorReadings ( byte[] readings ) {
	short crc, pcrc;
	System.out.println("Packet length: "+readings.length);
	/*
	for(int i = 0; i < readings.length; i ++){
	    System.out.print(Integer.toHexString((readings[i]&0xff)+0x100).toUpperCase().substring(1) + " ");
	}
	
	System.out.println("");
	
	*/
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
	    for (int i=0; i < 5; i++) {
		int moteid = ((readings[5+i*6]& 0xff) << 8) + ( readings[4+i*6]&0xff);
		if (moteid == 0xffff)
		    break;
		System.out.println ("moteID: " + moteid );
		if ((moteid >= 512) && (moteid <= 1024)) {
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
		return false;
	    }
	    }
	}
	else {
	    return false;
	}
	return true;
    }

    public boolean WritePacket ( byte[] packet ) {
	if ( packet == null || st == null ) {
	    System.out.println ( "DBWriter: Unable to write packet\n");
	    return false;
	}
	if ( packet.length < 4 ) {
	    System.out.println ( "DBWriter: received mal-formed packet");
	    return false;
	}/*
	try {
	    ResultSet rsUpdate = st.executeQuery ( "SELECT * FROM packets");
	    rsUpdate.moveToInsertRow ( );
	    rsUpdate.updateTimestamp ( "rcvdDate", 
				       new java.sql.Timestamp ( System.currentTimeMillis()));
	    rsUpdate.updateByte ( "field1", packet[FIELD1_POS] );
	    rsUpdate.updateByte ( "field2", packet[FIELD2_POS] );
	    rsUpdate.updateByte ( "field3", packet[FIELD3_POS] );
	    rsUpdate.updateBytes ( "payload", packet );
	    rsUpdate.insertRow ( );
	    }*/
	try {
	    PreparedStatement psInsert = db.prepareStatement ( "INSERT INTO packets VALUES (?,?,?,?,?)" );
	    psInsert.setTimestamp (1, new java.sql.Timestamp ( System.currentTimeMillis() ) );
	    psInsert.setByte (2, packet[FIELD1_POS] );
	    psInsert.setByte (3, packet[FIELD2_POS] );
	    psInsert.setByte (4, packet[FIELD3_POS] );
	    psInsert.setBytes (5, packet );
	    int bSuccess = psInsert.executeUpdate ( );
	    db.commit();
	    }
	catch ( SQLException e ) {
	    e.printStackTrace ( );
	    return false;
	}
	return true;
    }
}
