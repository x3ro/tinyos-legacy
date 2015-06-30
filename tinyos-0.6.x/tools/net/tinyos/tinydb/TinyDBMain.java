package net.tinyos.tinydb;

import net.tinyos.amhandler.*;
import java.util.*;

/** TinyDBMain creates the main UI for the TinyDB java
    classes.
*/
public class TinyDBMain {
    /**
    * @param args the command line arguments
    */
    public static void main(String args[]) {
	AMInterface aif;
	
	//open radio comm
	try {
	    aif = new AMInterface("COM1", false);
	    aif.open();


	    for (int i = 0; i < 3; i++) {
		aif.sendAM(CommandMsgs.resetCmd((short)-1), CommandMsgs.CMD_MSG_TYPE, (short)-1);
		Thread.currentThread().sleep(200);
	    }
	    
	    nw = new TinyDBNetwork(aif);
	    addQueryListener(nw);

	    CmdFrame cmf = new CmdFrame(aif);	    	    
	    cmf.setLocation(650,0);
	    cmf.show();
	    new QueryFrame(nw).show();
	} catch (Exception e) {
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

    public static AMInterface aif;
    public static TinyDBNetwork nw;
    private static Vector qls = new Vector(); //vector of query listeners
}
