/* -*- Mode: Java; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: Logger.java,v 1.1 2004/03/06 19:02:58 kaminw Exp $ */
/*////////////////////////////////////////////////////////*/
/**
 * A program to log uart packets into postgresql database
 * Author: Terence Tong
 */
/*////////////////////////////////////////////////////////*/

import java.util.*;
import java.io.*;
import javax.comm.*;
import java.sql.*;
import java.net.*;

import java.sql.Timestamp;
import java.util.Date;
import java.net.*;

import net.tinyos.packet.*;
import net.tinyos.util.*;
import net.tinyos.message.*;

import ucb.util.CommandArgs;

public class Logger {


  // TINYOS MESSAGE CONSTANT
  static final int TOS_UART_ADDR = 126;
  static int TOSH_DATA_LENGTH = 29;
  static int AM_HEADER_LENGTH = 5;
  static int CRC_LENGTH = 2;
  static int ADDR_OFFSET = 0;
  static int TYPE_OFFSET = 2;
  static int GROUP_OFFSET = 3;
  static int LENGTH_OFFSET = 4;
  static int VC_SOURCE_OFFSET = 5;

  // Listen Parameters
  static String sqlURL;
  static String sqlUser; // "Terence, postgres
  static String sqlPassword; // blah, oskirules
  static String source;
  static boolean doLogging;
  static boolean doDisplay;
  static boolean doCreateTable;
  static boolean doDropTable;
  static boolean doClearTable;
  static boolean doDuration;
  static boolean doReset;

  static String tablename;
  static Statement query = null;
  

  static void logPacket(byte[] packet) {
    Date date = new Date();
    Timestamp ts = new Timestamp(date.getTime());
    String dataField = "time";
    String dataValue = "'" + ts + "'";

    int[] intPacket = new int[packet.length];
    for (int i = 0; i < packet.length; i++) {
      if (packet[i] < 0) 
        intPacket[i] = (int) packet[i] + 256;
      else
        intPacket[i] = (int) packet[i];
    }

    for (int i = 0; i < intPacket.length; i++) {
      dataField += ", " + "b" + Integer.toString(i);
      dataValue += ", '" + intPacket[i] + "'";
    }
    String queryString = "insert into " + tablename + " (" + dataField + ") VALUES ( ";
    queryString += dataValue + ");";
    try {
      query.executeUpdate(queryString);
    } catch (SQLException e) {
      System.out.println("Query no good; " + e.getErrorCode() + "; " + queryString);
      
    }
  }
  static void connectDb() {
    // before: localhost/rsc
    sqlURL = "jdbc:postgresql://" + sqlURL;
    // after: "jdbc:postgresql://localhost/rsc"; "jdbc:postgresql://webbie.berkeley.intel-research.net/rsc"
    try {
      Class.forName("org.postgresql.Driver");
    } catch (ClassNotFoundException cnfe) {
      System.out.println("Couldn't find the driver!");
      System.out.println("Let's print a stack trace, and exit.");
      System.exit(1);
    }
    Connection connection = null;		
    try {
      connection = DriverManager.getConnection(sqlURL, sqlUser, sqlPassword);
      query = connection.createStatement();
    } catch (SQLException se) {
      System.out.println("Couldn't connect: " + se);
      System.exit(1);
    }
  }

  static void listen() {
    if (doLogging == true) {
      // first we connect to the database first
      connectDb();
    }
    PacketSource reader = BuildSource.makePacketSource(source);
    
    if (reader == null) {
      System.out.println("Cannot connect to destination.");
      System.out.println("Did you forget to do network@ip:port? Destination maybe wrong or busy");
    }
    try {
      reader.open(PrintStreamMessenger.err);
      
      for (;;) {
	byte[] packet = reader.readPacket();
	if (doLogging == true)
	  logPacket(packet);
	if (doDisplay == true)
          PrettyPrint.print(packet);
	System.out.println();
      }
    }
    catch (IOException e) {
      System.err.println("Error on " + reader.getName() + ": " + e);
    }
  }


  public static void createTable() {
    connectDb();
    String dataField = "";
    for(int i = 0; i < AM_HEADER_LENGTH + TOSH_DATA_LENGTH + CRC_LENGTH; i ++) {
      dataField = dataField + ", " + "b" + Integer.toString(i) + " smallint";
    }
    String sql = "create table " + tablename 
      + " (time timestamp without time zone, packetid serial" + dataField;
    sql += ", primary key (packetid) );";
    try {
      query.executeUpdate(sql);
      
    } catch (SQLException e) {
      System.out.println("SQL Exception: " + e);
      System.exit(1);
    }
    System.out.println("Initialise Table Successfully");
  }

  public static void dropTable() {
    connectDb();
    String sql = "drop table " + tablename + ";";
    try {
      query.executeUpdate(sql);
      
    } catch (SQLException e) {
      System.out.println("SQL Exception: " + e);
      System.exit(1);
    }
    System.out.println("Table Dropped Successfully");
  }
  public static void clearTable() {
    connectDb();
    String sql = "delete from " + tablename + ";";
    try {
      query.executeUpdate(sql);
      
    } catch (SQLException e) {
      System.out.println("SQL Exception: " + e);
      System.exit(1);
    }
    System.out.println("Table Cleared Successfully");
  }

  public static void duration() {
    connectDb();
    String sql = "select min(time), max(time), count(*) from " + tablename + ";";
    try {
      ResultSet rs = query.executeQuery(sql);
      rs.next();
      int numCols  = rs.getMetaData().getColumnCount();
      String minTime = rs.getString(1);
      String maxTime = rs.getString(2);
      String numPackets = rs.getString(3);
      System.out.println("Experiment " + tablename + "\n\tfrom: " + minTime + "\n\tto: " + maxTime + "\n\tpackets: " + numPackets);
      
    } catch (SQLException e) {
      System.out.println("SQL Exception: " + e);
      System.exit(1);
    }
  }

  public static void reset() {
    // network@ip:10002
    String address = source.substring(8, source.length() - 6) ;

    try {
      Socket server = new Socket(address, 9999);
      DataOutputStream out = new DataOutputStream(server.getOutputStream());
      out.writeBytes("\r\n");
      out.flush();
      out.writeBytes("9\r\n");
      out.flush();
    } catch (Exception e) {
      System.out.println("Sorry I can't reset the device fro some reason: " + e);
      System.exit(1);
    }
    System.out.println("Issued reset command to " + address);
  }

  static void help() {
    System.out.println("");
    System.out.println("Usage: java RawLogger [options] ");
    System.out.println("  [options] are:");
    System.out.println("  -h, --help                  Display this message.");
    System.out.println("  --logging                   Enable Logging.");
    System.out.println("                              Required options (source). ");
    System.out.println("                              And (url, user, pass, tablename). ");
    System.out.println("  --display                   Display Packets.");
    System.out.println("                              Required options (source). ");
    System.out.println("  --createtable               Create a table.");
    System.out.println("                              Required options (url, user, pass, tablename).");
    System.out.println("  --droptable                 Drop a table.");
    System.out.println("                              Required options (url, user, pass, tablename).");
    System.out.println("  --cleartable                Clear a table.");
    System.out.println("                              Required options (url, user, pass, tablename).");
    System.out.println("  --duration                  Summary of Experiement Duration.");
    System.out.println("                              Required options (url, user, pass, tablename).");
    System.out.println("  --reset                     Reseting EPRB and the attached mote ");
    System.out.println("                              Required options (source). ");
    System.out.println("  --tablename=<name>          Specify sql tablename ");
    System.out.println("  --url=<ip/dbname>           JDBC URL. eg: localhost/rsc.");
    System.out.println("  --user=<user>               User of the database.");
    System.out.println("  --pass=<password>           Password of the database.");
    System.out.println("  --source=<type>             Standard TinyOS Source");
    System.out.println("                              serial@COM1:platform");
    System.out.println("                              network@HOSTNAME:PORTNUMBER");
    System.out.println("                              sf@HOSTNAME:PORTNUMBER");
    System.out.println("");
    System.exit(-1);
  }
  public static void main(String[] args) {
    String[] options = { "h", "help", "tablename=", "logging", "display", "reset",
                         "createtable", "droptable", "cleartable", "duration", 
                         "url=", "user=", "pass=", "source="};

    CommandArgs cmdArgs = new CommandArgs(options, args);

    boolean helpSpecified = cmdArgs.present("help");
    helpSpecified |= cmdArgs.present('h');

    // if help is requested, do help
    if (helpSpecified == true) { help(); }

    doLogging = cmdArgs.present("logging");
    doDisplay = cmdArgs.present("display");
    doCreateTable = cmdArgs.present("createtable");
    doDropTable = cmdArgs.present("droptable");
    doClearTable = cmdArgs.present("cleartable");
    doDuration = cmdArgs.present("duration");
    doReset = cmdArgs.present("reset");

    sqlURL = cmdArgs.optionValue("url", 0);
    sqlUser = cmdArgs.optionValue("user", 0);
    sqlPassword = cmdArgs.optionValue("pass", 0);
    source = cmdArgs.optionValue("source", 0);
    tablename = cmdArgs.optionValue("tablename", 0);


    // if action is logging, all that crap must present
    if (doLogging == true && 
	(tablename == null || source == null ||
	 sqlURL == null || sqlUser == null || sqlPassword == null))
      { help(); }
    
    if (doDisplay == true &&
	(source == null))
      { help(); }

    if (doCreateTable == true && 
        (sqlURL == null || sqlUser == null || sqlPassword == null ||
         tablename == null))
      { help(); }

    if ((doDuration == true || doDropTable == true || doClearTable == true) &&
        (tablename == null || sqlURL == null || sqlUser == null || sqlPassword == null))
      { help(); }

    if ((doReset == true ) &&
        (source == null))
      { help(); }
    
    if (doCreateTable == true) {
      createTable();
    } 
    if (doLogging == true || doDisplay == true) {
      listen();
    } 

    if (doDropTable == true) {
      dropTable();
    }
    
    if (doClearTable == true) {
      clearTable();
    }
    if (doDuration == true) {
      duration();
    }
    
    if (doReset == true) {
      reset();
    }
  }
  
  
  



}
