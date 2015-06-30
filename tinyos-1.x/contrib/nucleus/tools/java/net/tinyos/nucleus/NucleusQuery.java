package net.tinyos.nucleus;

import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.drip.*;
import net.tinyos.drain.*;

import java.io.*; 
import java.text.*;
import java.util.*;

import org.jdom.*;
import org.jdom.input.*;

import org.apache.xmlrpc.*;

public class NucleusQuery {
  
  MoteIF moteIF;
  Drip queryDrip;
  DrainConnector mhConnector;

  private static int ATTR_SIZE = 3;

  boolean schemaSpecified = false;
  String schemaFilename = "nucleusSchema.xml";
  String querySend = "network";
  int querySendAddr;
  String responseDest = "remote";
  int queryDelay = 10;
  boolean byteStrings = false;
  boolean set = false;
  int setValue;
  String setBytes;

  String xmlRpcServer;

  String[] attrNames;
  int[] attrPositions;
    
  private void usage() {
    System.err.println("java NucleusQuery [options] <attribute name>");
    System.err.println("  options:");
    System.err.println("  -s {<addr>, link, network} : where to send the query");
    System.err.println("  -d {<addr>, serial, local, remote} : where to send the response");
    System.err.println("  -t <10ths of sec> : how long to wait for responses");
    System.err.println("  -b : display all results as byte strings instead of integers");
    System.err.println("  -f <filename> : attribute schema file (default: ./nucleusSchema.xml)");
    System.err.println("  -v <value> : set an integer attribute or RAM symbol");
    System.err.println("  -x <URL> : use a remote XMLRPC server for query processing");
    System.err.println("     with this flag set, only the -s, -f, and -r flags are valid");
    System.exit(1);
  }

  public NucleusQuery(String args[]) {

    parseArgs(args);

    int send = NucleusInterface.DEST_NETWORK;
    int response = NucleusInterface.RESPONSE_TREE;

    if (querySend.equals("network")) {
      send = NucleusInterface.DEST_NETWORK;
    } else if (querySend.equals("link")) {
      send = NucleusInterface.DEST_LINK;
    } else if (querySend.equals("node")) {
      send = querySendAddr;
    } else {
      System.err.println("Unknown send option: " + querySend);
      usage();
    }

    if (responseDest.equals("serial")) {
      response = 0x7E;
    } else if (responseDest.equals("local")) {
      response = 0xFFFF;
    } else if (responseDest.equals("remote")) {
      response = 0;
    } else {
      try {
	response = Integer.parseInt(responseDest);
      } catch (Exception e) {
	System.err.println("Unknown destination: " + responseDest);
	usage();
      }
    }

    NucleusInterface ni;
    List result = new ArrayList();
    boolean setResult;

    Hashtable rpcGetResult = new Hashtable();
    Boolean rpcSetResult = new Boolean(false);

    if (xmlRpcServer == null) {

      if (schemaFilename == null) {
	System.err.println("You must specify a schema filename.");
	System.exit(1);
      }

      ni = new NucleusInterface();
      ni.loadSchema(schemaFilename);
	
      if (!set) {
	result = ni.get(send, response, queryDelay, 
			attrNames, attrPositions);
	
	if (result == null) {
	  System.exit(1);
	}

	for(Iterator it = result.iterator(); it.hasNext(); ) {
	  NucleusResult nr = (NucleusResult) it.next();
	  for(Iterator nameIt = nr.attrs.keySet().iterator(); 
	      nameIt.hasNext(); ) {
	    String name = (String) nameIt.next();
	    NucleusValue nv = (NucleusValue) nr.attrs.get(name);
	    
	    System.out.print("" + nr.from + ": " + name + " = ");
	    
	    if (nv.value != null && !byteStrings) {
	      System.out.println(nv.value);
	    } else if (nv.bytes != null) {
	      System.out.println(toHexByteString(nv.bytes));
	    } else {
	      System.out.println("ERROR: didn't get value");
	    }
	  }
	}
	
      } else {
	short[] bytes;
	if (setBytes != null) {
	  bytes = toByteArray(setBytes);
	} else {
	  bytes = toByteArray(setValue);
	}

	setResult = ni.set(send, attrNames[0], attrPositions[0], bytes);
      }
      
    } else {
      String schema;

      if (schemaSpecified) {
	schema = readFile(schemaFilename);
	if (schema == null) {
	  System.err.println("Couldn't load schema from: " + schemaFilename);
	  System.exit(1);
	}
	try {
	  XmlRpcClient xmlrpc = new XmlRpcClient(xmlRpcServer);
	  Vector params = new Vector();
	  params.addElement(schema);
	  xmlrpc.execute("nucleus.setSchema", params);
	} catch (java.net.MalformedURLException e) {
	  System.err.println("Invalid URL: " + xmlRpcServer);
	  System.exit(1);
	} catch (IOException e) {
	  System.err.println(e);
	  System.exit(1);
	} catch (XmlRpcException e) {
	  System.err.println(e);
	  System.exit(1);
	}
      }
    
      try {
	XmlRpcClient xmlrpc = new XmlRpcClient(xmlRpcServer);

	if (!set) {
	  Vector params = new Vector();
	  params.addElement(new Integer(send));
	  params.addElement(new Integer(response));
	  params.addElement(new Integer(queryDelay));
	  
	  Vector attrNamesVec = new Vector();
	  for(int i = 0; i < attrNames.length; i++) {
	    attrNamesVec.add(attrNames[i]);
	  }
	  params.addElement(new Vector(attrNamesVec));
	  
	  Vector attrPositionsVec = new Vector();
	  for(int i = 0; i < attrPositions.length; i++) {
	    attrPositionsVec.add("" + attrPositions[i]);
	  }
	  params.addElement(new Vector(attrPositionsVec));

	  rpcGetResult = (Hashtable) xmlrpc.execute("nucleus.get", params);

	  for(Enumeration e = rpcGetResult.keys(); e.hasMoreElements(); ) {
	    String from = (String) e.nextElement();
	    Hashtable values = (Hashtable)rpcGetResult.get(from);
	    for(Enumeration e2 = values.keys(); e2.hasMoreElements(); ) {
	      String name = (String) e2.nextElement();
	      System.out.println(from + ": " + name + " = " 
				 + values.get(name));
	    }
	  }

	} else {

	  Vector params = new Vector();
	  params.addElement(new Integer(send));
	  params.addElement(attrNames[0]);
	  params.addElement(new Integer(attrPositions[0]));
	  params.addElement("" + setValue);

	  rpcSetResult = (Boolean) xmlrpc.execute("nucleus.set", params);
	}

      } catch (IOException e) {
	System.out.println("Couldn't connect to " + xmlRpcServer);
	System.out.println(e);
	e.printStackTrace();
	System.exit(1);
      } catch (XmlRpcException e) {
	System.out.println(e);
	System.exit(1);
      }
    }
    
    System.exit(0);
  }

  private String readFile(String filename) {
    try {
      BufferedReader in = new BufferedReader(new FileReader(filename));
      StringBuffer buf = new StringBuffer();
      String line;
      while ((line = in.readLine()) != null) {
	buf.append(line + "\n");
      }
      return buf.toString();
    } catch (Exception e) { 
      System.out.println(e);
      return null;
    }
  }

  private String toHexByteString(ArrayList arr) {
    String ret = "";
    for (Iterator byteIt = arr.iterator(); byteIt.hasNext(); ) {
      Byte theByte = (Byte) byteIt.next();
      ret += toHexByte(theByte.intValue()) + " "; 
    }
    return ret;
  }

  private String toHexByte(int b) {
    String buf = "";
    String bs = Integer.toHexString(b & 0xff).toUpperCase();
    if (b >=0 && b < 16)
      buf += "0";
    buf += bs;
    return buf;
  }

  private short[] toByteArray(int value) {
    short[] theBytes = new short[4];
    for(int i = 0; i < 4; i++) {
      theBytes[i] = (short)(value & 0xFF);
      value >>= 8;
    }
    return theBytes;
  }

  private short[] toByteArray(String value) {
    String[] theByteStrings = value.split(":");
    short[] theBytes = new short[theByteStrings.length];
    for(int i = 0; i < theByteStrings.length; i++) {
      theBytes[i] = (short)Integer.parseInt(theByteStrings[i], 16);
    }
    return theBytes;
  }

  private void parseArgs(String args[]) {

    ArrayList cleanedArgs = new ArrayList();

    for(int i = 0; i < args.length; i++) {
      if (args[i].startsWith("--")) {

        // Parse Long Options
        String longopt = args[i].substring(2);

      } else if (args[i].startsWith("-")) {

        // Parse Short Options
	String opt = args[i].substring(1);

	if (opt.equals("s")) {
	  String sendDest = args[++i];
	  try {
	    querySendAddr = Integer.parseInt(sendDest);
	    querySend = "node";
	  } catch (Exception e) {
	    querySend = sendDest;
	  }
	} else if (opt.equals("d")) {
	  responseDest = args[++i];
	} else if (opt.equals("t")) {
	  queryDelay = Integer.parseInt(args[++i]);
	} else if (opt.equals("f")) {
	  schemaSpecified = true;
	  schemaFilename = args[++i];
	} else if (opt.equals("b")) {
	  byteStrings = true;
	} else if (opt.equals("v")) {
	  set = true;
	  setValue = Integer.parseInt(args[++i]);
	} else if (opt.equals("vb")) {
	  set = true;
	  setBytes = args[++i];
	} else if (opt.equals("x")) {
	  xmlRpcServer = args[++i];
	}
	
      } else {

        // Place into args string
        cleanedArgs.add(args[i]);
      }
    }
    
    if (cleanedArgs.size() < 1) {
      usage();
    }
    
    int i = 0;
    attrNames = new String[cleanedArgs.size()];
    attrPositions = new int[cleanedArgs.size()];
    
    for(Iterator it = cleanedArgs.iterator(); it.hasNext(); ) {
      
      String name = (String)it.next();
      String attr[] = name.split("\\.");
      String attrName;
      int attrPos = 0;
      
      attrName = "";
      
      if (attr.length > 1) {
	for (int j = 0; j < attr.length-1; j++) {
	  attrName += attr[j];
	  if (j < attr.length-2) {
	    attrName += ".";
	  }
	}
      }
      
      try {
	attrPos = Integer.parseInt(attr[attr.length-1]);
      } catch (Exception e) {
	if (!attrName.equals("")) {
	  attrName += ".";
	}
	attrName += attr[attr.length-1];
      }
      
      attrNames[i] = attrName;
      attrPositions[i] = attrPos;
      i++;
    }
  }

  public static void main(String[] args) {
    new NucleusQuery(args);
  }
}
