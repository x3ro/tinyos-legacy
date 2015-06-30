package net.tinyos.mgmtquery;

import net.tinyos.message.*;
import net.tinyos.util.*;

import net.tinyos.multihop.*;
import net.tinyos.drip.*;

import java.io.*; 
import java.text.*;
import java.util.*;

public class MgmtQueryHost implements MessageListener {
  
  public static int MAX_QUERIES = 4;
  public static int ATTR_KEY_SIZE = 2;

  private MgmtQuery currentQueries[];
  private DripMsg queryMsgs[];

  private HashSet   currentQueryListeners[];

  private MultihopConnector mhConnector;

  private MoteIF moteIF;

  public MgmtQueryHost() {
    try {
      moteIF = new MoteIF((Messenger)null);
    } catch (Exception e) {
      System.err.println("ERROR: Couldn't contact serial forwarder.");
      System.exit(1);
    }

    currentQueries = new MgmtQuery[MAX_QUERIES];
    queryMsgs = new DripMsg[MAX_QUERIES];
    currentQueryListeners = new HashSet[MAX_QUERIES];

    mhConnector = new MultihopConnector();
    mhConnector.registerListener(MgmtQueryResponseMsg.AM_TYPE, this);
  }

  public boolean isActive(int qid) {
    if (currentQueries[qid] == null)
      return false;
    else
      return true;
  }

  void registerListener(int id, ResultListener m) {

    HashSet listenerSet = currentQueryListeners[id];
    
    if (listenerSet == null) {
      listenerSet = new HashSet();
      currentQueryListeners[id] = listenerSet;
    }

    listenerSet.add(m);
  }

  int transformQid(int qid) {
    return 10+qid;
  }

  int transformDripID(int dripid) {
    return dripid-10;
  }

  public void injectQuery(MgmtQuery q, int qid, ResultListener listener) {

    registerListener(qid-1, listener);

    currentQueries[qid-1] = q;

    DripMsg msg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE + 
			      MgmtQueryMsg.DEFAULT_MESSAGE_SIZE +
			      (q.numAttrs() * ATTR_KEY_SIZE));
    msg.set_metadata_id((short) transformQid(qid));
    msg.set_metadata_seqno((byte)0);

//    System.out.println(msg);

    MgmtQueryMsg queryMsg = 
	new MgmtQueryMsg(msg, msg.offset_data(0), 
			 MgmtQueryMsg.DEFAULT_MESSAGE_SIZE +
			 (q.numAttrs() * ATTR_KEY_SIZE));
    
    queryMsg.set_epochLength(q.samplePeriod());
    queryMsg.set_msgType((byte)1);
    queryMsg.set_numAttrs((byte)q.numAttrs());
    if (q.isRAMQuery())
      queryMsg.set_ramQuery((byte)1);
  
    int i = 0;      
    for (Iterator it = q.keyList().iterator(); it.hasNext(); i++) {
      MgmtAttr attr = (MgmtAttr) it.next();
      queryMsg.setElement_attrList(i, attr.id);
    }

    send(msg);
  }

  public void cancelQuery(int qid) {
    DripMsg msg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE + 
			      MgmtQueryMsg.DEFAULT_MESSAGE_SIZE);
    msg.set_metadata_id((short)transformQid(qid));
    msg.set_metadata_seqno((byte)0);

    MgmtQueryMsg queryMsg = new MgmtQueryMsg(msg, msg.offset_data(0), 
					     MgmtQueryMsg.DEFAULT_MESSAGE_SIZE);
    queryMsg.set_msgType((byte)0);

    send(msg);
  }

  public void sendOneShotQuery(MgmtQuery q, int qid, ResultListener listener) {

    registerListener(qid-1, listener);
    currentQueries[qid-1] = q;

    DripMsg msg = new DripMsg(DripMsg.DEFAULT_MESSAGE_SIZE + 
			      MgmtQueryMsg.DEFAULT_MESSAGE_SIZE + 
			      (q.numAttrs() * ATTR_KEY_SIZE));
    msg.set_metadata_id((short)transformQid(qid));
    msg.set_metadata_seqno((byte)0);

    MgmtQueryMsg queryMsg = new MgmtQueryMsg(msg, msg.offset_data(0), 
					     MgmtQueryMsg.DEFAULT_MESSAGE_SIZE
					     + (q.numAttrs() * ATTR_KEY_SIZE));
    
    queryMsg.set_epochLength(q.samplePeriod());
    queryMsg.set_msgType((byte)2);
    queryMsg.set_numAttrs((byte)q.numAttrs());
    if (q.isRAMQuery())
      queryMsg.set_ramQuery((byte)1);

    int i = 0;
    for (Iterator it = q.keyList().iterator(); it.hasNext(); i++) {
      MgmtAttr attr = (MgmtAttr) it.next();
      queryMsg.setElement_attrList(i, attr.id);
    }

    send(msg);
  }

  public synchronized void send(Message m) {
    try {
      moteIF.send(MoteIF.TOS_BCAST_ADDR, m);
    } catch (IOException e) {
      e.printStackTrace();
      System.err.println("ERROR: Can't send message");
      System.exit(1);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public void messageReceived(int to, Message m) {
    
    MultihopLayerMsg mhMsg = (MultihopLayerMsg) m;
    MgmtQueryResponseMsg mqrMsg = 
      new MgmtQueryResponseMsg(mhMsg, mhMsg.offset_data(0), 
			       mhMsg.dataLength()
			       - mhMsg.offset_data(0));

    int qid = mqrMsg.get_qid();
    MgmtQuery query = currentQueries[qid-1];

    if (query == null) {
      return;
    }

    MgmtQueryResult mqr = new MgmtQueryResult(mhMsg.get_originaddr(),
					      query, mqrMsg, qid);
    mqr.setTTL(mhMsg.get_ttl());

    HashSet listenerSet = currentQueryListeners[qid-1];
    
    if (listenerSet != null) {
      for(Iterator it = listenerSet.iterator(); it.hasNext(); ) {
	ResultListener listener = (ResultListener) it.next();
	listener.addResult(mqr);
      }
    }
  }
}




