package net.tinyos.tinydb;

import java.util.*;
import net.tinyos.amhandler.*;

/** TinyDBNetwork is responsible for getting and
    sending results and queries over the network

    @author madden

*/
public class TinyDBNetwork implements AMHandler, Runnable, QueryListener {

    static final short ROUNDS_TO_NEIGHBORHOOD_RESET = 5; //how long before we decide the neighborhood is empty
    static final short IGNORE_AGE = 5; //results older than this many epochs should be ignored

    public static final byte QUERY_MSG_ID = 101; //message ids used by tinydb
    public static final byte DATA_MSG_ID = 100;
    public static final byte UART_MSG_ID = 1;

    static int baseBcastInterval = 1700; //rate at which data messages are broadcast from the root

    EpochTimer et = new EpochTimer(32); //background timer that tracks time left per epoch per query

    private AMInterface aif;
    private Hashtable qidListeners = new Hashtable();  //qid -> Vector(ResultListener)
    private Hashtable processedListeners = new Hashtable(); //qid -> Vector(ResultListener)
    private Vector listeners = new Vector(); //Vector(ResultListener), receive all results
    
    private short neighborhoodResetCount; //how long til we reset the neighborhood hashtable
    private Hashtable neighborhood = new Hashtable(); //list of motes we've heard recently

    private boolean sendingQuery = false;
   
    Vector knownQids = new Vector(); //list of known query ids
    Vector queries = new Vector(); //list of queries, where queries[i].qid = i;  some elements may be null


    /** Constructor 
	@param aif The AMInterface used to send / receive messages from the motes 
    */
    public TinyDBNetwork(AMInterface aif) {
	this.aif = aif;
	Thread t = new Thread(this);

	aif.registerHandler(this, DATA_MSG_ID);
	aif.registerHandler(this, UART_MSG_ID);
	t.start();

    }
    
    /** Add a listener to be notified when a query result for
	the specified query id arrives 
	@param rl The ResultListener to add
	@param aggResults Does the listener want processed (e.g. combined aggregate) results, 
	                  or raw results?
        @param qid The query id this listener is interested in
    */
    public void addResultListener(ResultListener rl, boolean aggResults, int qid) {
	Vector qidV;

	if (!aggResults) {
	    qidV = (Vector)qidListeners.get(new Integer(qid));
	} else {
	    qidV = (Vector)processedListeners.get(new Integer(qid));
	}
	if (qidV == null) {
	    qidV = new Vector();
	    if (!aggResults) {
		qidListeners.put(new Integer(qid), qidV);
	    } else {
		processedListeners.put(new Integer(qid), qidV);
	    }
	}
	qidV.addElement(rl);


    }

    
    /** Add a listener to be notified when any query result
	arrives 
	@param rl The listener to register
    */
    public void addResultListener(ResultListener rl) {
	listeners.addElement(rl);
    }

    /** Remove a specific result listener 
     @param rl The listener to remove
    */
    public void removeResultListener(ResultListener rl) {
	listeners.remove(rl);
	Enumeration e = qidListeners.elements();
	Vector qidV;

	while (e.hasMoreElements()) {
	    qidV = (Vector)e.nextElement();
	    qidV.remove(rl);
	}

	e = processedListeners.elements();
	while(e.hasMoreElements()) {
	    qidV = (Vector)e.nextElement();
	    qidV.remove(rl);
	}
    }


    Vector lastEpochs = new Vector(); //vector of last epochs for all queries
    Vector lastResults = new Vector(); //vector of HashTables by group id of results for all queries

    /** Process a radio message 
     Assumes results are QueryResults -- parses them, and maintains the following
    data structures:
    - most recent epoch heard for each query
    - most recent (paritially aggregated) result for each query
    
    Notifies ResultListeners for all results every time a value arries
    Notifies ResultListeners for raw results for a pariticular query id every time a result for that query arrives
    Notifies ResultListeners for processed results from the current epoch every time a new epoch begins;  the aggregate
                                  combines results that are from the same epoch and are not obviously bogus (e.g.
				  from a ridiculous epoch number);  each group is reported in a different result message.
				  
                             
    */
    public void handleAM(byte[] data, short addr, byte id, byte group) {
	try {
	  int qid = QueryResult.queryId(data);


	  if (lastEpochs.size() <= (qid+1)) {
	    lastEpochs.setSize(qid+1);
	    lastResults.setSize(qid+1);
	  }
	  Hashtable curHt = (Hashtable)lastResults.elementAt(qid);
	  QueryResult curQr;
	  Integer le = (Integer)lastEpochs.elementAt(qid);
	  int lastEpoch = (le == null)?-1:le.intValue();
	  TinyDBQuery q = (TinyDBQuery)queries.elementAt(qid);
	  if (q != null) {
	    QueryResult newqr = new QueryResult(q, data);
	    Vector listeners;
	    Enumeration e;

	    neighborhood.put(new Integer(newqr.getSender()), new Integer(0)); //keep a list of the sensors we've heard recently

	    //send this result to listeners for all results
	    e = this.listeners.elements();
	    while (e.hasMoreElements()) {
		((ResultListener)e.nextElement()).addResult(newqr);
	    }

	    //plus listeners for unprocessed results for this query id
	    listeners = (Vector)qidListeners.get(new Integer(newqr.qid()));
	    if (listeners != null) {
		e = listeners.elements();
		while (e.hasMoreElements()) {
		    ((ResultListener)e.nextElement()).addResult(newqr);
		}
	    }
		
	    if (newqr.getRecipient() != 0) {
		System.out.print("("+newqr.getRecipient()+"->" +newqr.getSender()+")");
		return; //not for us
	    }
	    if (newqr.epochNo() > lastEpoch + 1000) {
		System.out.println("e");
	      return; //ignore wacky results!
	    }

	    if (q.isAgg()) {
	      if (newqr.epochNo() > lastEpoch || curHt == null) { //onto a new epoch!
		if (curHt != null) {
		  Iterator it = curHt.values().iterator();
		  while (it.hasNext()) {
		    curQr = (QueryResult)it.next();
		    listeners = (Vector)processedListeners.get(new Integer(curQr.qid()));
		    if (listeners != null) {
			e = listeners.elements();
			while (e.hasMoreElements()) {
			    ((ResultListener)e.nextElement()).addResult(curQr);
			}
		    }
		  }
		}
		curHt = new Hashtable();
		curHt.put(new Integer(newqr.group()), newqr);
		lastResults.setElementAt(curHt, qid);
		lastEpochs.setElementAt(new Integer(newqr.epochNo()), qid);
		System.out.print("+");
	     } else if (newqr.epochNo() >= (lastEpoch - IGNORE_AGE)) { //ignore really old results
		curQr = (QueryResult)curHt.get(new Integer(newqr.group()));
		if (curQr != null)
		  curQr.mergeQueryResult(newqr);
		else 
		  curHt.put(new Integer(newqr.group()), newqr);
		//lastEpochs.setElementAt(new Integer(newqr.epochNo()), qid);
		System.out.print(newqr.getSender());
	      } else
		System.out.print("$");

	    } else { //not agg
	      if (newqr.epochNo() >= (lastEpoch - IGNORE_AGE)) { //skip old results
		System.out.println("Result for query " + QueryResult.queryId(data) + ":"+ newqr.toString());
		listeners = (Vector)processedListeners.get(new Integer(newqr.qid()));
		if (listeners != null) {
		    e = listeners.elements();
		    while (e.hasMoreElements()) {
			((ResultListener)e.nextElement()).addResult(newqr);
		    }
		}
		lastEpochs.setElementAt(new Integer(newqr.epochNo()), qid);
		System.out.print("+");
	      } else
		System.out.print("[$"+newqr.epochNo()+"]");
	    }	    


	  }
	} catch (ArrayIndexOutOfBoundsException e) {
	    e.printStackTrace();
	    System.out.print("-");
	}
    }

    /** Background thread used to periodically send information from the root
	down into the network;  current this information includes:
	a message index (so that children can choose root as parent)
	information about the typical number of senders during an epoch (so that children can schedule comm)
	an epoch number (per query).
    */
    public void run() {
	byte[] msg;
	short idx = 0;
	byte curQuery = 0, qid;
	short nwSizeEstimate = 16; //initial value

	while (true) {
	    try {

		Thread.currentThread().sleep(getBaseBcastInterval()); 
		
		if (knownQids.size() != 0) {
		  neighborhoodResetCount--;
		  
		  if (neighborhoodResetCount <= 0) {
		    neighborhoodResetCount = ROUNDS_TO_NEIGHBORHOOD_RESET;
		    
		    nwSizeEstimate = (short)(2 * (double)neighborhood.size());
		    if (nwSizeEstimate == 0) nwSizeEstimate = 16; //default instead of 0!
		    System.out.println("New neighborhood size = " + nwSizeEstimate);
		    neighborhood = new Hashtable();
		    
		  }
		
		  int cnt = 0;
		  boolean isTopo = false;
		  do {
		      if (knownQids.size() > 127) System.out.println("WARNING : TOO MANY QUERIES!");
		      if (curQuery >= knownQids.size()) {
			  curQuery = 0;
		      }
		      qid = (byte)((Integer)knownQids.elementAt(curQuery)).intValue();
		      cnt++;
		  } while ( cnt <= knownQids.size());

		  
		  idx++;
		  if (idx < 0) idx = 0; //handle wraparound
		  
		  short epochNo;
		  try {
		      epochNo = (short)(((Integer)lastEpochs.elementAt(qid)).intValue() + 1);
		  } catch (ArrayIndexOutOfBoundsException e) {
		      epochNo = 0;
		  }

		  msg =	QueryResult.generateDataMessage(qid,
							idx,
							epochNo,
							(byte)(nwSizeEstimate & 0x00FF),
							(byte)(0xFF));

		  for (int i = 0; i < msg.length; i++) {
		    System.out.print(msg[i] + ",");
		  }
		  if (!sendingQuery) {
		      System.out.println("Sending msg.");
		    aif.sendAM(msg, DATA_MSG_ID, AMInterface.TOS_BCAST_ADDR);	    
		  } else
		    System.out.println("Sending query.");
		}
	    } catch (Exception e) {
		e.printStackTrace();
	    }
	}
    }


    //QueryListener methods
    /** A new query has begun running.  Use this to track the queries that we need to
	send data messages for (see run() above.)
    */
    public void addQuery(TinyDBQuery q) {
	knownQids.addElement(new Integer(q.getId()));
	if (queries.size() < ( q.getId() + 1))
	    queries.setSize(q.getId() + 1);
	queries.setElementAt(q, q.getId());
    }

    /** A query has stopped running */
    public void removeQuery(TinyDBQuery q) {
	Integer qid = new Integer(q.getId());
	knownQids.remove(qid);
	processedListeners.remove(qid);
	qidListeners.remove(qid);
	queries.removeElementAt(q.getId());
    }

    /** Send the specified query out over the radio */
    public void sendQuery(TinyDBQuery q) {
	sendingQuery = true;
	Iterator it = q.messageIterator(); //generate messages for this query

	try {
	    System.out.println("Sending query.");
	    while (it.hasNext()) {
		byte msg[] = (byte[])it.next();

		aif.sendAM(msg, QUERY_MSG_ID, AMInterface.TOS_BCAST_ADDR);
		Thread.currentThread().sleep(1000);
	    }
	} catch (Exception e) {
	    e.printStackTrace();
	}
	sendingQuery = false;
    }

    /** Send message to abort the specified query out over the radio */
    public void abortQuery(TinyDBQuery query)
    {
	for (int i = 0; i < 5; i++)
	    {
		try
		    {
			aif.sendAM(query.abortMessage(), QUERY_MSG_ID, AMInterface.TOS_BCAST_ADDR);
			Thread.currentThread().sleep(200);
		    }
		catch (Exception e)
		    {
			e.printStackTrace();
		    }
	    }
    }

    /** Return baseBcastInterval, which controls how often data messages are 
	sent out from the base station so that nodes can see
	the root.
    */	
    public static int getBaseBcastInterval()
    {
  	return baseBcastInterval;
    }

    /** Set the base station data message broadcast interval */
    public static void setBaseBcastInterval(int interval)
    {
	baseBcastInterval = interval;
    }


    
}

