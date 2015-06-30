/* -*- Mode: Java; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/* $Id: Receiver.java,v 1.21 2003/08/05 00:02:28 wetoasis Exp $ */
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

import java.sql.Timestamp;
import java.util.Date;
import java.net.*;

public class Receiver {

  static final int TOS_UART_ADDR = 0x7e;
  static int TOSH_DATA_LENGTH = 29;
  static int AM_HEADER_LENGTH = 5;
  static int CRC_LENGTH = 2;
  static boolean PRINT_RAW_BYTE = true;
  static boolean PRINT_QUERY = false;
  static boolean PRINT_SELECTIVE = true;

  static boolean ALL_OFF = false;


  static int[] MY_TYPES = {1, 2, 3, 5, 6, 12, 17, 102};

  static int MY_GROUP = 0xb;

  static int ADDR_OFFSET = 0;
  static int TYPE_OFFSET = 2;
  static int GROUP_OFFSET = 3;
  static int LENGTH_OFFSET = 4;

  static int VC_SOURCE_OFFSET = 5;

  static int NETWORK_PORT = 10002;

  static boolean logging = true;

  static String to2Hex(int input) {
    input = input & 0xff;
    return "x" + Integer.toHexString(input);
  }
  static String toHexString(int input) {
    return "x" + Integer.toHexString(input);
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to print out the packet one byte by one byte
   * @author: terence
   * @param: dataLength, the length field in am header
   * @param: packet, a int array of the whole packet
   * @return: void
   */

  public static void printPacket(int dataLength, byte[] packet) {
    if (PRINT_RAW_BYTE == false) return;
    for(int i = 0; i < AM_HEADER_LENGTH + dataLength + CRC_LENGTH; i++) {
      System.out.print(Integer.toHexString(packet[i] & 0xff) + " ");
    }
    System.out.println();
  }
  /*////////////////////////////////////////////////////////*/
  /**
   * Dispatch to different print methdo.
   * @author: terence
   * @param: dataLength, the length field in am header
   * @param: packet, a int array of the whole packet
   * @return: void
   */

  static void printField(int intLength, byte[] packetBuffer) {
    if (packetBuffer[TYPE_OFFSET] == StatPacket.AM_TYPE) {
      printDataPacket(intLength, packetBuffer);
    } else if (packetBuffer[TYPE_OFFSET] == RoutePacket.AM_TYPE) {
      printRoutePacket(intLength, packetBuffer);
    } else if (packetBuffer[TYPE_OFFSET] == RouteDBMsg.AM_TYPE) {
      printDBPacket(intLength, packetBuffer);
    } else if (packetBuffer[TYPE_OFFSET] == SurgeMsg.AM_TYPE) {
      printSurgePacket(intLength, packetBuffer);
    } else if (packetBuffer[TYPE_OFFSET] == EstimatorMsg.AM_TYPE) {
      printEstimatorPacket(intLength, packetBuffer);
    } else if (packetBuffer[TYPE_OFFSET] == TablePacket.AM_TYPE) {
      printTablePacket(intLength, packetBuffer);
    }

  }

  static void printTablePacket(int intLength, byte[] packetBuffer) {
    TablePacket msg = new TablePacket(packetBuffer);
    System.out.print(" id:" +  to2Hex(msg.get_id1()));
    System.out.print(" receiveEst:" +  to2Hex(msg.get_receiveEst1()));
    System.out.print(" sendEst:" +  to2Hex(msg.get_sendEst1()));
    System.out.print(" cost:" +  to2Hex(msg.get_cost1()));
    System.out.println("");

    System.out.print(" id:" +  to2Hex(msg.get_id2()));
    System.out.print(" receiveEst:" +  to2Hex(msg.get_receiveEst2()));
    System.out.print(" sendEst:" +  to2Hex(msg.get_sendEst2()));
    System.out.print(" cost:" +  to2Hex(msg.get_cost2()));
    System.out.println("");

    System.out.print(" id:" +  to2Hex(msg.get_id3()));
    System.out.print(" receiveEst:" +  to2Hex(msg.get_receiveEst3()));
    System.out.print(" sendEst:" +  to2Hex(msg.get_sendEst3()));
    System.out.print(" cost:" +  to2Hex(msg.get_cost3()));
    System.out.println("");

    System.out.print(" id:" +  to2Hex(msg.get_id4()));
    System.out.print(" receiveEst:" +  to2Hex(msg.get_receiveEst4()));
    System.out.print(" sendEst:" +  to2Hex(msg.get_sendEst4()));
    System.out.print(" cost:" +  to2Hex(msg.get_cost4()));
    System.out.println("");

    System.out.print(" id:" +  to2Hex(msg.get_id5()));
    System.out.print(" receiveEst:" +  to2Hex(msg.get_receiveEst5()));
    System.out.print(" sendEst:" +  to2Hex(msg.get_sendEst5()));
    System.out.print(" cost:" +  to2Hex(msg.get_cost5()));
    System.out.println("");

    System.out.println("\n");
  
  }
  static void printEstimatorPacket(int intLength, byte[] packetBuffer) {
    EstimatorMsg msg = new EstimatorMsg(packetBuffer);
    System.out.println(msg);
  }
  static void printSurgePacket(int intLength, byte[] packetBuffer) {
    SurgeMsg surgeMsg = new SurgeMsg(packetBuffer);
    System.out.print("s" + toHexString(surgeMsg.get_originaddr()));
    System.out.print(" parent_link_quality:" + 
                     toHexString(surgeMsg.get_parent_link_quality()));
    System.out.print(" parent_addr:" + toHexString(surgeMsg.get_parentaddr()));
    
    System.out.println("");
  }

  static void printPlotPacket(int intLength, byte[] packetBuffer) {
  }


  static void printDBPacket(int intLength, byte[] packetBuffer) {
    RouteDBMsg routeDbMsg = new RouteDBMsg(packetBuffer);
    // System.out.println(routeDbMsg);
    
    System.out.print("d" + to2Hex(routeDbMsg.get_source()));
    System.out.print(" decision:" + to2Hex(routeDbMsg.get_decision()));
    System.out.print(" oldParent:" + to2Hex(routeDbMsg.get_oldParent()));
    System.out.print(" bestParent:" + to2Hex(routeDbMsg.get_bestParent()));
    System.out.print(" realparent:" + to2Hex(routeDbMsg.get_parent()));
    System.out.print(" dbseqnum:" + to2Hex(routeDbMsg.get_dbSeqnum()));

    System.out.println("");
    
    System.out.print("oldParentLinkCost:" + toHexString(routeDbMsg.get_oldParentLinkCost()));
    System.out.print(" oldParentCost:" + toHexString(routeDbMsg.get_oldParentCost()));
    System.out.print(" bestParentLinkCost:" + toHexString(routeDbMsg.get_bestParentLinkCost()));
    System.out.print(" bestParentCost:" + toHexString(routeDbMsg.get_bestParentCost()));
    
    System.out.println("");
    System.out.print("oldParentSendEst:" + to2Hex(routeDbMsg.get_oldParentSendEst()));
    System.out.print(" oldParentReceiveEst:" + to2Hex(routeDbMsg.get_oldParentReceiveEst()));
    System.out.print(" bestParentSendEst:" + to2Hex(routeDbMsg.get_bestParentSendEst()));
    System.out.print(" bestParentReceiveEst:" + to2Hex(routeDbMsg.get_bestParentReceiveEst()));
    System.out.println("");

    System.out.println("\n");
    
    }


  /*////////////////////////////////////////////////////////*/
  /**
   * this handle a route packet, print out the corresponding fields
   * @author: terence
   * @param: dataLength, the length field in am header
   * @param: packet, a int array of the whole packet
   * @return: void
   */

  static void printRoutePacket(int intLength, byte[] packetBuffer) {
    RoutePacket routePacket = new RoutePacket(packetBuffer);
    System.out.print("R" + toHexString(routePacket.get_source()));
    System.out.print(" parent:" + toHexString(routePacket.get_parent()));
    System.out.print(" hop:" + toHexString(routePacket.get_hop()));
    System.out.print(" cost:" + toHexString(routePacket.get_cost()));
    System.out.println("");

  }
  /*////////////////////////////////////////////////////////*/
  /**
   * this handle a data packet, print out the corresponding fields
   * @author: terence
   * @param: dataLength, the length field in am header
   * @param: packet, a int array of the whole packet
   * @return: void
   */

  static void printDataPacket(int intLength, byte[] packetBuffer) {
    StatPacket statPacket = new StatPacket(packetBuffer);

    System.out.print("D" + toHexString(statPacket.get_realSource()));
    System.out.print(" parent:" + toHexString(statPacket.get_parent()));
    System.out.print(" pSendEst:" + toHexString(statPacket.get_parentSendQuality()));
    System.out.print(" cost:" + toHexString(statPacket.get_cost()));
    /*
    for (int i = 0; i < 1; i++) {
      short id = statPacket.getElement_id(i);
      if (id == 255) {
        continue;
      }
      String neighborName = "n" + toHexString(id);
      System.out.print(" " + neighborName + "sendEst:" 
                       + toHexString(statPacket.getElement_sendEst(i)));
    }
    */
    System.out.println("");

  }

  /*////////////////////////////////////////////////////////*/
  /**
   * This print out the data packet, but with the 'additional overload' format
   * i leave this here because this additional information are really useful for
   * debugging
   * @param: dataLength, the length field in am header
   * @param: packet, a int array of the whole packet
   * @return: void
   */

  /*  
  static void printDataPacket(int intLength, byte[] packetBuffer) {
    System.out.print("D" + packetBuffer[9]);
    System.out.print(" parent:" + packetBuffer[17]);
    System.out.print(" pSendEst:" + packetBuffer[26]);
    System.out.print(" pCost:" + packetBuffer[27]);
    System.out.print(" pLinkQuality:" + packetBuffer[23] * 4);
    System.out.print(" spSuccess:" + packetBuffer[24]);
    System.out.print(" spFail:" + packetBuffer[25]);
    for (int i = 0; i < 1; i++) {
      if (packetBuffer[i + 22] == 255) {
        break;
      }
      String neighborName = "n" + packetBuffer[i + 22];
      System.out.print(" " + neighborName + "sendEst:" + packetBuffer[2 * i + 28]);
      System.out.print(" " + neighborName + "cost:" + packetBuffer[2 * i + 29]);
    }
    System.out.println("");

  }
  */
  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to save down tha packet to the database
   * @author: terence
   * @param: void
   * @return: void
   */


  public static void savePacket(int dataLength, byte[] packet) {
    Date date = new Date();
    Timestamp ts = new Timestamp(date.getTime());

    int[] intPacket = new int[TOSH_DATA_LENGTH + AM_HEADER_LENGTH + CRC_LENGTH];
    for (int i = 0; i < packet.length; i++) {
      if (packet[i] < 0) 
        intPacket[i] = (int) packet[i] + 256;
      else
        intPacket[i] = (int) packet[i];
    }

    String dataField = "time";
    String dataValue = "'" + ts + "'";
    for (int i = 0; i < AM_HEADER_LENGTH + dataLength; i++) {
      dataField += ", " + "b" + Integer.toString(i);
      dataValue += ", '" + intPacket[i] + "'";
    }
    String queryString = "insert into " + expName + " (" + dataField + ") VALUES ( ";
    queryString += dataValue + ");";
    
    if (PRINT_QUERY == true) {
      System.out.println(queryString);
    }
    try {
      query.executeUpdate(queryString);
    } catch (SQLException e) {
      System.out.println("SQL Exception: " + e);
    }
    
  }


  public static void setupConnection(String host, int port) {
    Socket socket = null;
    try {
      socket = new Socket(host, port);
      in = socket.getInputStream();
    } catch (UnknownHostException e) {
      System.err.println("Dont' know about host " + host);
      System.exit(1);
    } catch (IOException e) {
      System.err.println("Couldn't establish connection with " + host);
      System.exit(1);
    }

  }
  
  static long startTime, duration;
  
  
  public static void checkToSuicide() {
    if (duration == 0) return;
    if (System.currentTimeMillis() - startTime > duration) {
      System.out.println("Killing myself .... ");
      System.exit(0);
    }


  }
  /*////////////////////////////////////////////////////////*/
  /**
   * a for loop to save the packet, and do the filtering too
   * @author: terence
   * @param: void
   * @return: void
   */

  public static void read() {
    int addr, type, group, length;

    try {
      while(true) {
        checkToSuicide();
        // do all the filtering here
        addr = in.read();
        db2("addr:" + addr);
        if (addr != TOS_UART_ADDR) continue;
        if (in.read() != 0) continue;

        type = in.read();
        db2("type:" + type);
        group = in.read();
        
        db2("group:" + group);
        boolean result = false;
        for (int i = 0; i < MY_TYPES.length; i++) {
          result = result || (type == MY_TYPES[i]);
        }
        if (result == false) continue;
        if (group != MY_GROUP) continue; 
        length = in.read();
        db2("length:" + length);
        if (0 >= length || length > TOSH_DATA_LENGTH) continue;
        byte[] packet = new byte[TOSH_DATA_LENGTH + AM_HEADER_LENGTH + CRC_LENGTH];
        packet[ADDR_OFFSET] = (byte)addr;
        packet[ADDR_OFFSET + 1] = 0;
        packet[TYPE_OFFSET] = (byte)type;
        packet[GROUP_OFFSET] = (byte)group;
        packet[LENGTH_OFFSET] = (byte)length;
        for (int i = 0; i < length; i++) {
          packet[AM_HEADER_LENGTH + i] = (byte)in.read();
        }
        // because serial forwarder or surge is stupid, it is just weird
        packet[AM_HEADER_LENGTH + TOSH_DATA_LENGTH] = 1; 
        packet[AM_HEADER_LENGTH + TOSH_DATA_LENGTH + 1] = 0; 

        printPacket(length, packet);
        if (ALL_OFF == false) { printField(length, packet); }
        if (logging == true) { savePacket(length, packet); }
        //rt.write(packet);
      }
    } catch (IOException e) {
      System.out.println(e);
    }
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to create a table with a packetid and all the bytes of the packet
   * @author: terence
   * @param: void
   * @return: void
   */
  static String expName = null;
  public static void createTable() {
    String dataField = "";
    for(int i = 0; i < AM_HEADER_LENGTH + TOSH_DATA_LENGTH; i ++) {
      dataField = dataField + ", " + "b" + Integer.toString(i) + " smallint";
    }
    String sql = "create table " + expName 
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


  /*////////////////////////////////////////////////////////*/
  /**
   * Dbg statement
   * @author: terence
   * @param: 
   * @return: 
   */

  static void db1(String input) {
    System.out.println(input);
  }
  static void db2(String input) {
    // System.out.println(input);
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to open the port
   * @author: terence
   * @param: the port we are going to open
   * @return: void
   */

  private static InputStream in;
  private static final int PORT_SPEED = 19200;
  public static void open(String portName) {
    SerialPort port;
    CommPortIdentifier portId;
    OutputStream out;
    try {
      portId = CommPortIdentifier.getPortIdentifier(portName);
      port = (SerialPort)portId.open("RSC", 0);
      in = port.getInputStream();
      port.setFlowControlMode(SerialPort.FLOWCONTROL_NONE);
      port.disableReceiveFraming();
			
      // These are the mote UART parameters
      port.setSerialPortParams(PORT_SPEED,
                               SerialPort.DATABITS_8,
                               SerialPort.STOPBITS_1,
                               SerialPort.PARITY_NONE);
    } catch (Exception e) {
      System.out.println("Couldn't open a Serial port with Exception " + e);
      System.exit(1);
    }
  }

  /*////////////////////////////////////////////////////////*/
  /**
   * This is going to connect to database
   * @author: terence
   * @param: void
   * @return: void
   */

  static Statement query = null;
  static void connectDb() {
    try {
      Class.forName("org.postgresql.Driver");
    } catch (ClassNotFoundException cnfe) {
      db1("Couldn't find the driver!");
      db1("Let's print a stack trace, and exit.");
      System.exit(1);
    }
    Connection connection = null;		

    try {
      // The second and third arguments are the username and password,
      // respectively. They should be whatever is necessary to connect
      // to the database.
      /*
      connection = DriverManager.getConnection("jdbc:postgresql://webbie.berkeley.intel-research.net/rsc",
                                               "postgres", "oskirules");
      */
      connection = DriverManager.getConnection("jdbc:postgresql://localhost/rsc",
                                               "Administrator", "blah");

      query = connection.createStatement();
    } catch (SQLException se) {
      db1("Couldn't connect: print out a stack trace and exit.");
      System.exit(1);
    }
  }

  ////////////////////////////////////////////////////////////////////////
  public static void main(String[] args) {
    int argsLength = args.length;
    if (argsLength < 3) { System.out.println("Not Enough Args"); System.exit(1); }
    // save down the action
    boolean newTable = args[0].equals("newTable") ? true : false;
    boolean network = args[0].equals("network") ? true : false;
  
    // save down experiment name
    expName = args[1];
    
    // connect to database
    if (logging == true) { connectDb(); }
    db1("startDB: connection successful");		
    if (newTable == true) { createTable(); db1("Create New Table"); return; }
    if (network == true) {
      String host = args[2];
      setupConnection(host, NETWORK_PORT);
    } else {
      String portName = args[2];
      open(portName);
    }
    db1("Successfully opening Port");
    
    //ReceiverServer rt = new ReceiverServer();
    //rt.start();
    if (args.length < 4) {
      duration = 0;
    } else {
      startTime = System.currentTimeMillis();
      duration = Long.parseLong(args[3]) * 1000;
      System.out.println("Duration " + duration  + "MiliSeconds");
    }
    read();
  }


}










