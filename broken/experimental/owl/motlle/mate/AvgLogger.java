// $Id: AvgLogger.java,v 1.1 2004/06/15 17:30:57 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
import java.sql.*;
import java.util.*;
import net.tinyos.packet.*;

/** DBLogger is repsonsible for logging query results to Postgres.
    When instantiated with a query, it creates a new table to
    hold the results of that query and registers itself as a listener
    to results from that query.

    The name of table that is logged to can be retrieved via the 
    getTableName() method.  It will be uniquely generated for each
    query.

    The schema of the results table is:

   +----------------------------------------------------------+
   |  time stamp  | epoch no  |  field1 |  .... |  field n    |
   +----------------------------------------------------------+


   Additionally, each query is logged to a queries table (which must have been
   created before DBLogger is invoked.  The command to insert the queries table
   is:
   
   create table queries (qname varchar(10), query_time timestamp, query_string varchar(500));
*/


public class AvgLogger implements PacketListenerIF
{
    static String[] fields;
    private Connection conn = null;
    private static String urlPSQL= "jdbc:postgresql:";
    private static String m_usr = "tele";
    private static String m_pwd = "tiny";
    private final static String insertQueryStmt = "INSERT INTO queries values (?, ?, ?)";
    private long queryTime;
    private Statement stmt;
    private String logTableName;
    private boolean dupElim = false;

    /* ------------------------------------- Public Methods ------------------------------------------ */


    /** Create a DBLogger for accessing the database
	without a query to log (e.g. to restore a query from
	the DB.
    */
    public AvgLogger() throws SQLException {
	initDBConn();
	if (stmt == null) throw new SQLException("Open failed.");
	queryTime = 0;
	logTableName = null;
    }

    /** Set the parameters that this logger needs to start logging
	data for a particular query.  Note that this allows us
	to append onto an existing result table, and will not
	work if that result table hasn't already been created.
    */
    void setupLoggingInfo(int id, String logTable) {
	queryTime = System.currentTimeMillis();
	logTableName = logTable;
    }
    
    /** Start logging the specified query
	@param query The query to log
	@param queryStr The SQL string corresponding to query (since not all TinyDB queries have a unique
	SQL representation)
	@param nw The TinyDBNetwork that will deliver results for this query
	@throw SQLExcpetion if logging failed
    */
    public AvgLogger(String name) throws SQLException
    {
	initDBConn();
	queryTime = System.currentTimeMillis();
	logTableName = name;
	logQuery();
    }

    /** @return The name of the table to which this queries results are being logged */
    public String getTableName() {
	return logTableName;
    }

    /** Toggle whether duplicate elimination is done on inserts
	@param enable If true, duplicate elimination will be enabled, otherwise it will be disabled
    */
    public void setDupElim(boolean enable) {
	dupElim = enable;
    }

    /** ResultListener Method.  Log the specified query result to the table set up for
	this DBLogger.
	@param qr The result to log
    */
    static int getFieldIndex(String name) {
	for (int i = 0; i < fields.length; i++)
	    if (fields[i].equals(name))
		return i;
	return -1;
    }

    public void addResult(Object[] qr) {
	String sqlStr = insertStmt(qr, logTableName);
	if (stmt == null) return;

	System.out.println("logging result: " + sqlStr);
	try {
	    boolean isDup = false;
		

	    if (dupElim) {
		stmt.execute("BEGIN TRANSACTION");
		//check and see if this is a duplicate row
		// note that if there are multiple writers, this does
		// not guarantee that there will be no duplicates, as 
		// both could check and not detect any duplicates before
		// writing the update, but...
		System.out.println("CHECKING FOR DUPLICATES.");
		Integer name = (Integer)qr[getFieldIndex("nodeid")];
		if (name != null) {
		    String dupCheckStmt = "SELECT * FROM " + logTableName + " WHERE nodeid = " 
			+ name + " AND epoch = " + qr[getFieldIndex("epoch")];
		    ResultSet rs;
		    rs = stmt.executeQuery(dupCheckStmt);
		    isDup = (rs.first());
		    if (isDup) System.out.println("WAS DUPLICATE : " + dupCheckStmt);
		}
	    }

	    //only update if this isn't a duplicate, or we're not checking for dups
	    if (!isDup) stmt.executeUpdate(sqlStr);
	    if (dupElim) stmt.execute("END TRANSACTION");
	}
	catch (SQLException e) {
	    System.err.println("INSERT Result for query failed.  SQLState = " + e.getSQLState());
	}
    }

    /** Shut down the connection to Postgres. */
    public void close()
    {
	try {
	    if (conn != null)
		conn.close();
	    conn = null;
	    System.out.println("disconnected from postgres.");
	}
	catch (Exception e) {}
    }

    /* ------------------------------------- Private Methods ------------------------------------------ */
    /** Open the connection to Postgres */
    private void initDBConn() {
	try {
	    urlPSQL += "//barnowl/task";
	    Class.forName("org.postgresql.Driver");
	    conn = DriverManager.getConnection(urlPSQL, m_usr, m_pwd);
	    stmt = conn.createStatement();
	    System.out.println("connected to " + urlPSQL);
	} catch (Exception ex) {
	    System.out.println("failed to connect to Postgres!\n");
	    stmt = null;
	    ex.printStackTrace();
	}
	System.out.println("Connected to Postgres!\n");
    }

    /** Do the setup work for starting to log a query
	@throw SQLException if an error occurred creating / logging a query 
    */
    private void logQuery() throws SQLException {
	// create log table for the query
	String dropOldTable = "DROP TABLE " + logTableName;
	try {
	    stmt.executeUpdate(dropOldTable);
	} catch (SQLException e){
	    //ignore exceptions
	}

	String createTabStr = createTableStmt(logTableName);
	System.out.println(createTabStr);
	try {
	    stmt.executeUpdate(createTabStr);
	}
	catch (SQLException e) {
	    System.err.println("INSERT Result for query failed.  SQLState = " + e.getSQLState());
	    throw e;
	}
    }

    public static String createTableStmt(String tableName) {
	String createTabStr = "CREATE TABLE " + tableName + "(result_time timestamp";
	for (int i = 0; i < fields.length; i++) {
	    String colName = fields[i];
	    createTabStr += ", ";
			
	    createTabStr += colName.replace('(','_').replace(')',' ').trim();
	    createTabStr += " ";
	    createTabStr += "int";
	}
	createTabStr += ")";
	return createTabStr;
    }

    public static String insertStmt(Object results[], String tableName) {
	String sqlStr = "INSERT INTO " + tableName + " VALUES (now()";
	
	for (int i = 0; i < results.length; i++) {
	    String str;
	    if (results[i] == null)
		str = "null";
	    else
		str = results[i].toString();
	    sqlStr += ", ";
	    if (str == null)
		sqlStr += "NULL";
	    else {
		sqlStr += str;
	    }
	}
	sqlStr += ")";
	return sqlStr;
    }

    public void packetReceived(byte[] packet) {
	int offset;

	if (packet[2] == 0x2b)
	    offset = 12;
	else if (packet[2] == 0x2a)
	    offset = 5;
	else
	    return;

	if (packet[4] - (offset - 5) != 2 * fields.length - 2) {
	    System.out.println("invalid packet length\n");
	    return;
	}
	Object[] result = new Object[fields.length];

	for (int i = 0; i < fields.length - 1; i++) {
	    int val = ((packet[offset + 2 * i]) & 0xff) |
		((packet[offset + 2 * i + 1]) & 0xff) << 8;
	    result[i] = new Integer(val);
	}
	try {
	    result[fields.length - 1] = new Integer(((Integer)result[fields.length - 2]).intValue() /
						    ((Integer)result[fields.length - 3]).intValue());
	}
	catch (Exception e) { }
	addResult(result);
    }

    public static void main(String[] args) throws SQLException {
	fields = new String[args.length];
	for (int i = 0; i < fields.length - 1; i++)
	    fields[i] = args[i + 1];
	fields[fields.length - 1] = "avg";

	AvgLogger logger = new AvgLogger(args[0]);

	PhoenixSource source = BuildSource.makePhoenix(null);
	source.setResurrection();

	source.registerPacketListener(logger);
	source.run();
    }
 }
