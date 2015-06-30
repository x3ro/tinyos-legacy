package net.tinyos.nucleus.xmlrpc;

import java.util.*;
import java.io.*;

import org.apache.log4j.*;

import org.apache.xmlrpc.WebServer;
import org.apache.xmlrpc.XmlRpcException;
import net.tinyos.nucleus.*;
import net.tinyos.drain.*;
import net.tinyos.message.*;

public class Server {

  public static final int NUCLEUS_NULL_RESPONSE = 1000;
  public static final int NUCLEUS_QUERY_INVALID_PARAMS = 1001;
  public static final int NUCLEUS_INVALID_SCHEMA = 1002;
  public static final int NUCLEUS_QUERY_IN_PROGRESS = 1003;
  public static final int NUCLEUS_TEMPFILE_CREATE_ERROR = 1004;
  public static final int NUCLEUS_TEMPFILE_WRITE_ERROR = 1005;
  public static final int NUCLEUS_SET_PARSE_ERROR = 1006;
  public static final int NUCLEUS_SCHEMA_LOAD_ERROR = 1007;

  private Logger log = Logger.getLogger(Server.class.getName());

  protected NucleusInterface ni;
  protected String[]names;
  protected int positions[];

  private WebServer webServer; 
  private int port = 8080;
  private ArrayList allowedhosts;
  private ArrayList deniedhosts;
  private String schemaFilepath = new String("nucleusSchemaTemp.xml");
  private String tosImageFilepath = new String("tos_image_temp.xml");
  private boolean localSchema;
  private Drain drain = new Drain();

  Server(String []args)
  {
    parseArgs(args); 

    webServer = new WebServer (port);
    webServer.setParanoid(false);

    for(int i=0; i< allowedhosts.size(); i++)
    {
      webServer.setParanoid(true);
      webServer.acceptClient( (String)allowedhosts.get(i) );
    }

    for(int i=0; i< deniedhosts.size(); i++)
    {
      webServer.setParanoid(true);
      webServer.denyClient( (String)deniedhosts.get(i));
    }

    webServer.addHandler("nucleus", new NucleusXMLRPCHandler());
    webServer.addHandler("drain", new DrainXMLRPCHandler());
    webServer.start();

    ni = new NucleusInterface();
  }

  public class NucleusXMLRPCHandler {
    private Boolean queryInProgress = Boolean.FALSE;

    public String getSchema() throws XmlRpcException {
      String schema;

      log.info("nucleus.getSchema()");

      schema = readFile(schemaFilepath);
      if (schema == null) {
	throw new XmlRpcException(NUCLEUS_SCHEMA_LOAD_ERROR, "Unable to load schema from " + schemaFilepath +".");
      }
      return schema;
    }

    public Boolean setSchema(String schema) throws XmlRpcException {
      FileWriter out;

      log.info("nucleus.setSchema(" + schema + ")");

      try {
	out = new FileWriter(schemaFilepath, false);
      }
      catch (IOException io)
      {
	throw new XmlRpcException(NUCLEUS_TEMPFILE_CREATE_ERROR, "Unable to create " + schemaFilepath +".");
      }
      
      try {
	out.write( schema );
      }
      catch (IOException io)
      {
	throw new XmlRpcException(NUCLEUS_TEMPFILE_WRITE_ERROR,"Unable to write to " + schemaFilepath +".");
      }
      
      try {
	out.close();
      }
      catch ( IOException io)
      {
	throw new XmlRpcException(NUCLEUS_TEMPFILE_WRITE_ERROR,"Unable to write to " + schemaFilepath +".");
      }

      return Boolean.TRUE;
    }
    
    public Hashtable get(int destAddr,
			 int queryDest,
			 int queryDelay,
			 Vector attrNames,
			 Vector attrPositions) throws XmlRpcException {
      
      log.info("nucleus.get(destAddr=" + destAddr +
	       ", queryDest=" + queryDest +
	       ", queryDelay=" + queryDelay +
	       ", attrNames=" + attrNames +
	       ", attrPositions" + attrPositions +
	       ")");

      queryLock();
      try{
        buildNamesPositions(attrNames, attrPositions);
        processSchemafile();
      }
      catch(XmlRpcException e)
      {
        queryUnlock();
	throw e;
      }
      catch (Exception e) 
      {
	queryUnlock();
	throw new XmlRpcException(NUCLEUS_NULL_RESPONSE, e.toString());
      }
      List result = null;
      try {
	result = ni.get(destAddr,
			queryDest,
			queryDelay,
			names,
			positions);
      } catch (Exception e) {
	queryUnlock();
	throw new XmlRpcException(NUCLEUS_NULL_RESPONSE, e.toString());
      }
      queryUnlock();

      if( result == null)
      {
        throw new XmlRpcException(NUCLEUS_NULL_RESPONSE, "Null response from Nucleus");
      }

      // Convert from the Nucleus response List to an XMLRPC friendly Hashtable
      Hashtable response = new Hashtable();

      for(Iterator it = result.iterator(); it.hasNext(); ) {
	NucleusResult nr = (NucleusResult) it.next();
	Hashtable values = new Hashtable();
	
	for(Iterator nameIt = nr.attrs.keySet().iterator(); 
	    nameIt.hasNext(); ) {
	  
	  String name = (String) nameIt.next();
	  NucleusValue nv = (NucleusValue) nr.attrs.get(name);
	  
	  String info = "" + nr.from + ": " + name + " = ";

	  if (nv.value != null) {
	    info += nv.value;
	    values.put(name, nv.value);
	  } else if (nv.bytes != null) {
	    String theValue = toHexByteString(nv.bytes);
	    info += theValue;
	    values.put(name, theValue);
	  } else {
	    info += "ERROR";
	    values.put(name, "ERROR");
	  }

	  log.info(info);
	}
	response.put( Integer.toString( nr.from ), values );
      }

      return response;
    }

    public Boolean set(int destAddr,
		       String name,
		       int position,
		       String value) throws XmlRpcException {

      log.info("nucleus.set(destAddr=" + destAddr +
	       ", attrName=" + name +
	       ", attrPosition=" + position +
	       ", attrValue=" + value +
	       ")");
      queryLock();
      try{
        processSchemafile();
      }
      catch(XmlRpcException e)
      {
        queryUnlock();
	throw e;
      }
      catch(Exception e)
      {
	queryUnlock();
	throw new XmlRpcException(NUCLEUS_SET_PARSE_ERROR, e.toString());
      }
      short valueBytes[] = null; 
      try {
	valueBytes = toByteArray(Integer.parseInt(value));
      }
      catch(NumberFormatException e)
      {
	queryUnlock();
	throw new XmlRpcException(NUCLEUS_SET_PARSE_ERROR, "Unable to parse value: " + value);
      }
      boolean b = false;
      try {
	b = ni.set(destAddr,name,position,valueBytes);
      } catch (Exception e) {
	queryUnlock();
	throw new XmlRpcException(NUCLEUS_NULL_RESPONSE, e.toString());
      }
      queryUnlock();

      return b? Boolean.TRUE: Boolean.FALSE;
    }

    private short[] toByteArray(int value) {
      short[] theBytes = new short[4];
      for(int i = 0; i < 4; i++) {
        theBytes[i] = (short)(value & 0xFF);
        value >>= 8;
      }
      return theBytes;
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
    
    // This method is only necessary to coerce the names and positions
    private void buildNamesPositions(Vector attrNames,
				     Vector attrPositions) throws XmlRpcException
    {
      if(attrNames == null || attrPositions == null ||
	 attrPositions.size() != attrNames.size())
      {
        throw new XmlRpcException(NUCLEUS_QUERY_INVALID_PARAMS, "Invalid params in query");
      }
      
      // coerce from Vector to String[]
      names = new String[ attrNames.size() ];
      for(int i=0; i< attrNames.size(); i++)
      {
	if (!(attrNames.elementAt(i) instanceof String)) {
	  throw new XmlRpcException(NUCLEUS_QUERY_INVALID_PARAMS, "Invalid params in query");
	}
        names[i] = (String)attrNames.elementAt(i);
      }
      
      // coerce from Vector to int[]
      positions = new int[ attrNames.size() ];

      for(int i=0; i< attrNames.size(); i++)
      {
        if( attrPositions != null )
	{
	  if (!(attrPositions.elementAt(i) instanceof String)) {
	    throw new XmlRpcException(NUCLEUS_QUERY_INVALID_PARAMS, "Invalid params in query");
	  }
	  positions[i] = Integer.parseInt((String)attrPositions.elementAt(i));
	}
        else
	{
          positions[i] = 0;
	}
      }
    }

    // This method write the submitted schema string to a temporary file
    private void processSchemafile() throws XmlRpcException
    {
      try
      {
        ni.loadSchema( schemaFilepath );
      }
      catch (Exception e)
      {
        throw new XmlRpcException(NUCLEUS_INVALID_SCHEMA, "Schema " + schemaFilepath + " is invalid.");
      }
    }

    private void queryLock() throws XmlRpcException
    {
      synchronized( queryInProgress ) {
        if( queryInProgress == Boolean.TRUE )
	  {
	    throw new XmlRpcException(NUCLEUS_QUERY_IN_PROGRESS, "Nucleus query currently in progress");
	  }
	queryInProgress = Boolean.TRUE;
      }
    } 

    private void queryUnlock()
    {
      synchronized( queryInProgress ) {
        queryInProgress = Boolean.FALSE;
      }
    }
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

  public class DrainXMLRPCHandler {
    public Boolean buildTree(int delay, int treeInstance, boolean defaultRoute) {
      drain.buildTree(delay, treeInstance, defaultRoute);
      return Boolean.TRUE;
    }
  }

  private void usage() {
    System.err.println("java NucleusXMLRPCServer [options]");
    System.err.println("  -p <serverport>  : Port to run the XML Web Server on");
    System.err.println("  -a <allowedhost> : Address of host allowed to run methods on server");
    System.err.println("  -d <deniedhost>  : Address of host denied access to the server");
    System.err.println("  -t <tmpfilepath> : Path that XMLRPC server stores schema temporarily");
    System.err.println("  -l : Use local schema, instead of query schema.");
    System.err.println("     : You should have a schema file already in <tmpfilepath>");
    System.exit(1);
  }

  private void parseArgs(String[] args)
  {
    allowedhosts = new ArrayList();
    deniedhosts = new ArrayList();

    for(int i = 0; i < args.length; i++) {
      if(args[i].startsWith("-"))
      {
        String opt = args[i].substring(1);
        if(opt.equals("p"))
	{
	  port = Integer.parseInt(args[++i]);
	}
	else if(opt.equals("a"))
	{
	  allowedhosts.add(args[++i]);
	}
	else if(opt.equals("d"))
	{
          deniedhosts.add(args[++i]); 
	}
	else if(opt.equals("t"))
	{
	  schemaFilepath = args[++i];
	}
	else if(opt.equals("l"))
	{
	  localSchema = true;
	}
	else
	{
	  usage();
	}
      }
    }
  }

  public static void main(String[] args){
    PropertyConfigurator.configureAndWatch("log4j.properties", 1000);
    new Server(args);
  }
}
