package net.tinyos.tinydb;

import java.util.*;
import net.tinyos.message.*;
import net.tinyos.sf.*;
import java.io.*;

/** TinyDBMain creates the main UI for the TinyDB java
    classes.
*/
public class TinyDBMain {
    /**
    * @param args the command line arguments
    */
    public static void main(String args[]) {
	
	if (!parseArgs(args)) return;

	Config.init(configFile);

	String groupStr = Config.getParam("am-group-id");
	if (groupStr == null) 
	    groupid = GROUP_ID;
	else {
	    try {
		groupid = new Byte(groupStr).byteValue();
		if (debug) System.out.println("GROUPID : " + groupid);
	    } catch (NumberFormatException e) {
		System.out.println("Bad am-group-id entry in config file: " + groupStr);
		groupid = GROUP_ID;
	    }
	}
	if (Config.getParam("show-command-window").equalsIgnoreCase("true"))
		showControlPanel = true;

	String commandString = Config.getParam("show-command-window");
	if (commandString != null) {
	    if (commandString.toLowerCase().equals("true"))
		showControlPanel = true;
	    else
		showControlPanel = false;
	}
	
	String startSfString = Config.getParam("start-sf");
	if (startSfString != null)
	    if (startSfString.toLowerCase().equals("false"))
		startSerialForwarder=false;
	


	//open radio comm
	try {
	    Thread t;

	    if (getMoteIF() == null)
		throw new IOException();

	    t = new Thread(mif);
	    t.start();

	    for (int i = 0; i < 3; i++) {
		mif.send((short)-1,CommandMsgs.resetCmd((short)-1));
		Thread.currentThread().sleep(200);
	    }
	    
	    nw = new TinyDBNetwork(mif);
	    addQueryListener(nw);
	    
	    if (cmdLine) {
		CmdLineOutput cmdLine = new CmdLineOutput(nw, cmdLineQuery);
		while (true) {
		    try {
			Thread.currentThread().sleep(1000);
		    } catch(Exception e) {
		    }
		}
	    } else {
		
		if (showControlPanel) {
		    CmdFrame cmf = new CmdFrame(mif);	    	    
		    cmf.setLocation(750,30);
		    cmf.show();
		}
		
		MainFrame mf = new MainFrame(nw, startGuiInterface);
		mf.setLocation(5,30);
		mf.show();
	    }
	} catch (Exception e) {
	    if (debug) e.printStackTrace();
	    System.out.println("Open failed -- network won't work.");
	}


    }
    

    // The following methods are used to register/remove QueryListeners
    // that are notified whenever a query is started or stopped
    
    
    /** Register the specified QueryListener.  The listener will be notified
	everytime notifyAddedQuery or notifyRemovedQuery is called. 
    */
    public static void addQueryListener(QueryListener ql) {
	qls.addElement(ql);
    }

    /** Deregister the specified QueryListener */
    public static void removeQueryListener(QueryListener ql) {
	qls.removeElement(ql);
    }

    /** Notify all currently registered QueryListeners with a addQuery message */
    public static void notifyAddedQuery(TinyDBQuery q) {
	Enumeration e;
	e = qls.elements();
	while (e.hasMoreElements()) {
	    QueryListener ql = (QueryListener)e.nextElement();
	    ql.addQuery(q);
	}
    }

    /** Notify all currently register QueryListeners with a removeQuery message */
    public static void notifyRemovedQuery(TinyDBQuery q) {
	Enumeration e;
	e = qls.elements();
	while (e.hasMoreElements()) {
	    QueryListener ql = (QueryListener)e.nextElement();
	    ql.removeQuery(q);
	}
    }

    static boolean parseArgs(String[] args) {
	boolean setInterface = false;
	try {
	    for (int i = 0; i < args.length; i++) {
		if (args[i].equals("-text")) {
		    startGuiInterface = false;
		    if (setInterface) {
			System.out.println("-text option conflicts with previous input window option. \n" + usage);
			return false;
		    }
		    setInterface = true;
		}
		else if (args[i].equals("-cmdwindow"))
		    showControlPanel = true;
		else if (args[i].equals("-gui")) {
		    startGuiInterface = true;
		    if (setInterface) {
			System.out.println("-gui option conflicts with previous input window option. \n" + usage);
			return false;
		    }
		    setInterface = true;
		} else if (args[i].equals("-configfile")) {
		    configFile = args[++i];
		} else if (args[i].equals("-run")) {
		    cmdLine = true;
		    cmdLineQuery = args[++i];
		} else if (args[i].equals("-debug")) {
		    debug = true;
		} else {
		    System.out.println("Unknown argument: " + args[i]);
		    System.out.println(usage);
		    return false;
		}
	    } 
	} catch (ArrayIndexOutOfBoundsException e) {
	    System.out.println("Missing expected command line argument! \n" + usage);
	    return false;
	}

	return true;
    }


    static MoteIF getMoteIF() throws IOException{
	String host = "localhost";
	short port = 9000;

	if (mif == null) {
	    if (startSerialForwarder)
		SerialForward.run(false, MSG_SIZE);
	    try {
		Thread.currentThread().sleep(100);
	    } catch (Exception e) {}
	    if (!startSerialForwarder) {
		String portString;
		
		host = Config.getParam("sf-host");
		if (host == null) {
		    System.out.println("sf-host config file option is not set, but start-sf is!");
		    return null;
		}
		portString = Config.getParam("sf-port");
		if (portString == null) {
		    System.out.println("sf-port config file option is not set, but start-sf is!");
		    return null;
		}
		try {
		    port = new Integer(portString).shortValue();
		} catch (NumberFormatException e) {
		    System.out.println("couldn't parse sf-port config file option (" + portString + " is not a valid port number.");
		    return null; //failed
		}
		
	    }
	    mif = new MoteIF(host, port ,groupid,DATA_SIZE, false);
	} 
	return mif;
    }
    
    public static MoteIF mif = null;

    static byte groupid;


    public static TinyDBNetwork nw;

    static boolean debug = false;
    static boolean startSerialForwarder = true;
    static boolean startGuiInterface = true;
    static boolean showControlPanel = false;
    private static boolean cmdLine = false;
    private static String cmdLineQuery;

    private static String configFile = "net/tinyos/tinydb/tinydb.conf";

    static final String usage = "Usage: java TinyDBMain [-text|-gui] [-cmdwindow] [-configfile file] [-run query] [-debug] \n\t-text: Use text input window \n\t-gui: Use gui input window (default) \n\t-cmdwindow: Display the command window. \n\t-configfile: The name of the configuration file to use (default: " + configFile + ")\n\t-run: Run the specified query on the command line\n\t-debug: Enable debugging messages";

    private static Vector qls = new Vector(); //vector of query listeners

  public static final int MSG_SIZE = 47;
  public static final int DATA_SIZE = MSG_SIZE - 7;
    private static final int GROUP_ID = 105;




}
