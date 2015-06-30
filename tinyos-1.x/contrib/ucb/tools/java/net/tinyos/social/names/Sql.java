package net.tinyos.social.names;

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
	    st = db.createStatement();
	} catch (Exception ex) {
	    ex.printStackTrace();
	    //System.exit(2);
	}
    }

    void addMote(int moteId, String name)
    {
	try {
	    st.executeUpdate("INSERT INTO mobilemote (moteid, name) " + 
			     "VALUES (" + moteId + ", \"" + name + "\")");
	} catch (SQLException e) {
	    System.err.println("Something BAD happened during the SQL update: "+e);
	    e.printStackTrace();
	}
    }

    void delMote(int moteId)
    {
	try {
	    st.executeUpdate("DELETE FROM mobilemote WHERE moteid = " + moteId);
	} catch (SQLException e) {
	    System.err.println("Something BAD happened during the SQL update: "+e);
	    e.printStackTrace();
	}
    }

    void setMoteName(int moteId, String name)
    {
	try {
	    st.executeUpdate("UPDATE mobilemote SET name = \"" + name + "\" WHERE moteid = " + moteId);
	} catch (SQLException e) {
	    System.err.println("Something BAD happened during the SQL update: "+e);
	    e.printStackTrace();
	}
    }

    void getMotes(UserDB db)
    {
	ResultSet results = null;

	try {
	    results = st.executeQuery("SELECT moteid, name FROM mobilemote");

	    int moteIdIndex = results.findColumn("moteid");
	    int nameIndex = results.findColumn("name");

	    while (results.next())
		db.add(new MoteInfo(results.getInt(moteIdIndex),
				    results.getString(nameIndex)));
	    results.close();
	} 
	catch (SQLException e) {
	    System.err.println("Something BAD happened during the SQL query: "+e);
	    e.printStackTrace();
	}
    }

}
