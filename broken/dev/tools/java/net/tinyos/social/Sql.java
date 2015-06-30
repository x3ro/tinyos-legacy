package net.tinyos.social;

import java.sql.*;
import java.util.Date;

class Sql 
{
    Connection db = null;
    Statement  st = null;
    ResultSet  rs = null;
    String url = "jdbc:mysql://10.212.2.158:3306/retreattest";
    String usr = "tinyos";
    String pwd = "mote";

    Sql() 
    {
    }

    void connect() 
    {
	try {
	    System.out.println ("Connecting to database");
	    Class.forName("org.gjt.mm.mysql.Driver");
	    db = DriverManager.getConnection(url, usr, pwd);
	    st = db.createStatement( );
	    db.setAutoCommit(false);
	} catch (Exception ex) {
	    ex.printStackTrace();
	    //System.exit(2);
	}
    }

    static private String d2(int n)
    {
	return "" + n / 10 + n % 10;
    }

    static String sqlTime(long millis)
    {
	Date t = new Date(millis);

	return d2(t.getYear() % 100) + d2(t.getMonth() + 1) + d2(t.getDate()) +
	    d2(t.getHours()) + d2(t.getMinutes()) + d2(t.getSeconds());
    }

    void writeTracking(int moteId, int nbrId, long time, int signalStrength)
    {
	try {
	    System.out.println("INSERT INTO tracking (moteid, nbrid, signalstrength, time) " + 
			     "VALUES (" + moteId + ", " + nbrId +
			     ", " + signalStrength + ", " + sqlTime(time) + ")");
	    st.executeUpdate("INSERT INTO tracking (moteid, nbrid, signalstrength, time) " + 
			     "VALUES (" + moteId + ", " + nbrId +
			     ", " + signalStrength + ", " + sqlTime(time) + ")");
	} catch (SQLException e) {
	    System.err.println("Something BAD happened during the SQL update: "+e);
	    e.printStackTrace();
	}
    }

    void writeSocial(int moteId, int nbrId, long time, int duration)
    {
	try {
	    System.out.println("INSERT INTO social (moteid, nbrid, duration, time) " + 
			     "VALUES (" + moteId + ", " + nbrId +
			     ", " + duration + ", " + sqlTime(time) + ")");
	    st.executeUpdate("INSERT INTO social (moteid, nbrid, duration, time) " + 
			     "VALUES (" + moteId + ", " + nbrId +
			     ", " + duration + ", " + sqlTime(time) + ")");
	} catch (SQLException e) {
	    System.err.println("Something BAD happened during the SQL update: "+e);
	    e.printStackTrace();
	}
    }

    void commit() {
	try {
	    db.commit();
	} catch (SQLException e) {
	    System.err.println("Something BAD happened during the SQL commit: "+e);
	    e.printStackTrace();
	}
    }
}
