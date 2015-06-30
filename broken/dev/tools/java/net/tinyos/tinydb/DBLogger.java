package net.tinyos.tinydb; 

import java.sql.*;
import java.util.*;

public class DBLogger implements ResultListener, QueryListener
{

    private Connection conn = null;
    private static String urlPSQL= "jdbc:postgresql:";
    private static String m_usr = Config.getParam("postgres-user");
    private static String m_pwd = Config.getParam("postgres-passwd");;
    private final static String insertQueryStmt = "INSERT INTO queries values (?, ?, ?)";
	private TinyDBQuery queryToLog;
	private String queryString;
	private long queryTime;
	private Statement stmt;
	private String logTableName;
	private TinyDBNetwork network;

	private void initDBConn()
	{
		try {
		    urlPSQL += "//" + Config.getParam("postgres-host") + "/" + Config.getParam("postgres-db");
		    Class.forName ( "org.postgresql.Driver" );
		    conn = DriverManager.getConnection(urlPSQL, m_usr, m_pwd);
		    stmt = conn.createStatement();
		    if (TinyDBMain.debug) System.out.println("connected to " + urlPSQL);
		} catch (Exception ex) {
		    System.out.println("failed to connect to Postgres!\n");
		    ex.printStackTrace();
		}
		if (TinyDBMain.debug) System.out.println("Connected to Postgres!\n");
	}

    public DBLogger(TinyDBQuery query, String queryStr, TinyDBNetwork nw)
	{
		initDBConn();
		queryToLog = query;
		queryString = queryStr;
		network = nw;
		queryTime = System.currentTimeMillis();
		logTableName = "query" + query.getId(); // XXX to be made really unique
		logQuery();
		nw.addResultListener(this, true, query.getId());
	}

	private void logQuery()
	{
		try
		{
			PreparedStatement  pstmt = null;
			pstmt = conn.prepareStatement(insertQueryStmt);
			pstmt.setInt(1, queryToLog.getId());
			pstmt.setTimestamp(2, new Timestamp(queryTime));
			pstmt.setString(3, queryString);
			pstmt.executeUpdate();
			pstmt.close();
		}
		catch (Exception ex) {
			System.out.println("logQuery failed.\n");
			ex.printStackTrace();
		}
		// create log table for the query
		String dropOldTable = "DROP TABLE " + logTableName;
		try {
		    stmt.executeUpdate(dropOldTable);
		} catch (Exception e){
		}

		String createTabStr = "CREATE TABLE " + logTableName + "(result_time timestamp";
		Vector columns = queryToLog.getColumnHeadings();
		for (int i = 0; i < columns.size(); i++)
		    {
			String colName = (String)columns.elementAt(i);
			createTabStr += ", ";
			
			createTabStr += colName.replace('(','_').replace(')',' ').trim();
			createTabStr += " ";
			if (queryToLog.getFieldType(i) == QueryField.STRING)
				createTabStr += "varchar(32)"; // XXX should be sufficient for now
			else
				createTabStr += "int";
		}
		createTabStr += ")";
		if (TinyDBMain.debug) System.out.println(createTabStr);
		try
		{
			stmt.executeUpdate(createTabStr);
		}
		catch (SQLException e)
		{
			System.err.println("INSERT Result for query " + queryToLog.getId() + " failed.  SQLState = " + e.getSQLState());
		}
	}

	public void addResult(QueryResult qr)
	{
		String sqlStr = "INSERT INTO " + logTableName + " VALUES (now()";
		Vector resultVector = qr.resultVector();
		for (int i = 0; i < resultVector.size(); i++)
		{
			sqlStr += ", ";
			if (queryToLog.getFieldType(i) == QueryField.STRING)
				sqlStr += "'";
			sqlStr += resultVector.elementAt(i);
			if (queryToLog.getFieldType(i) == QueryField.STRING)
				sqlStr += "'";
		}
		sqlStr += ")";
		if (TinyDBMain.debug) System.out.println("logging result: " + sqlStr);
		try
		{
			stmt.executeUpdate(sqlStr);
		}
		catch (SQLException e)
		{
			System.err.println("INSERT Result for query " + queryToLog.getId() + " failed.  SQLState = " + e.getSQLState());
		}
	}

    public void removeQuery(TinyDBQuery q) {
	if (q == queryToLog) {
	    close();
	}
    }
    
    public void addQuery(TinyDBQuery q) {
    }

	public void close()
	{
		network.removeResultListener(this);
		try
		{
			if (conn != null)
				conn.close();
			conn = null;
			if (TinyDBMain.debug)  System.out.println("disconnected from postgres.");
		}
		catch (Exception e)
		{
		}
	}
}
