/* Demo for a signal plotter.
*/
package net.tinyos.gdi;

import java.sql.*;
import java.util.*;
import java.rmi.*;
import java.rmi.server.UnicastRemoteObject;

public class GDIserver extends UnicastRemoteObject implements GDIquery {

    protected Connection conn;
    static String rmiHost = "webbie.berkeley.intel-research.net";
    static String dbUser = "postgres";
    static String dbPasswd = "oskirules";
    static String dbHost = "webbie.berkeley.intel-research.net";
    static String dbPort = "5432";
    static String dbName = "gdi";

    public GDIserver() throws RemoteException {
	super();
    }

    public Vector sqlQuery(String sql) throws RemoteException {
	System.out.println("Query " + sql);
	String sqlStmt = sql;
	
	String sqlUrl = "jdbc:postgresql://" + dbHost + ":" + dbPort +
	    "/" + dbName;
	try {
	    Class.forName("org.postgresql.Driver");
	}
	catch (Exception e) {
	    e.printStackTrace();
	    // error finding class, return null to the client.
	    return null;
	}

	Statement stmt = null;
	ResultSet rs = null;

	try {
	    conn = DriverManager.getConnection(sqlUrl, dbUser, dbPasswd);
	    stmt = conn.createStatement();    
	    rs = stmt.executeQuery(sqlStmt);
	}
	catch (Exception e) {
	    // error connecting to sql database, return null to client
	    return null;
	}

	// build result set
	Vector main = new Vector();
	Vector col1 = new Vector();
	Vector col2 = new Vector();
	Vector col3 = new Vector();
	try {
	    while (rs.next()) {
		int nid =  rs.getInt(1);
		long now = (long)rs.getInt(2);
		int value = rs.getInt(3);
	    
		col1.addElement(new Integer(nid));
		col2.addElement(new Long(now));
		col3.addElement(new Integer(value));
	    }
	}
	catch (Exception e) {
	    e.printStackTrace();
	}
	main.addElement(col1);
	main.addElement(col2);
	main.addElement(col3);
	return main;
    }

    public static void main(String args[]) {
	// Create and isntall a security manager
	if (System.getSecurityManager() == null) {
	    System.setSecurityManager(new RMISecurityManager());
	}

	try {
	    GDIserver obj = new GDIserver();
	    
	    // bind to the repository as "GDIserver"
	    Naming.rebind("//" + rmiHost + "/GDIserver", obj);
	    System.out.println("Bound in registry");
	}
	catch (Exception e) {
	    System.out.println("Bind error: " + e.getMessage());
	    e.printStackTrace();
	}
    }

}
