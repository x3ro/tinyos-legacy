import java.util.*;
import net.tinyos.mgmtquery.*;

public class WatchableUserQuery implements ResultListener {

  private Network network;
  private WatchableSchema schema;
  private MgmtQueryHost queryHost;
  private MgmtQuery userQuery;
  private List userQueryWatchables;

  private String key;
  private Watchable watchable;

  private Timer userQueryTimer = new Timer();

  private static int QUERY_PERIOD = 2;

  public WatchableUserQuery(WatchableSchema ws) {
      queryHost = new MgmtQueryHost();  
      schema = ws;
      userQueryTimer.schedule(new TimerTask() {
	  public void run() {
	    if (key != null) {
	      System.out.println("Sending User Query");
	      sendUserQuery();
	    }
	  }
	}, 
			      0, QUERY_PERIOD * 1000);
  }
  
  public void clearWatchable() {
    Map nodeMap = network.getNodeMap();

    for(Iterator it = nodeMap.values().iterator(); it.hasNext(); ) {
      Node node = (Node) it.next();
      node.setRecentWatchableValue("");
      node.reExamine();
    }

    this.key = null;
  }

  public void addWatchable(String key) {

    Map nodeMap = network.getNodeMap();

    for(Iterator it = nodeMap.values().iterator(); it.hasNext(); ) {
      Node node = (Node) it.next();
      node.setRecentWatchableValue("");
      node.reExamine();
    }

    this.key = key;
  }

  private void sendUserQuery() {

    userQuery = new MgmtQuery(1);
    userQueryWatchables = new ArrayList();
    
    watchable = schema.getWatchable(key);
    
    if (watchable != null) {
      userQueryWatchables.add(watchable);
      if (schema.isRAMQuery()) {
	userQuery.setRAMQuery(true);
	userQuery.appendKey(makeRAMKey(watchable.getKey(), watchable.getLength()),
			    makeRAMLength(watchable.getLength()));
	System.out.println(userQuery);
      } else {
	userQuery.appendKey(watchable.getKey(), watchable.getLength());
      }

      queryHost.sendOneShotQuery(userQuery, 2, this);
    }
  }

  public void addResult(MgmtQueryResult qr) {
    
    if (network == null)
      return;

    Node node = network.getNode(qr.getSourceAddr());

    if (node == null)
      return;

    String result = "";

    try {

      if (watchable.getType().equals("MA_TYPE_UINT")) {
	result = new Integer(qr.getInt(0)).toString();
      } else if(watchable.getType().equals("MA_TYPE_TEXTSTRING")) {
	result = qr.getString(0);
      } else if(watchable.getType().equals("MA_TYPE_OCTETSTRING")) {
	result = qr.getOctetString(0);
      } else if (watchable.getType().equals("MA_TYPE_BITSTRING")) {
	result = qr.getBitString(0);
      } else if(watchable.getType().equals("MA_TYPE_UNIXTIME")) {
	long time = (long)qr.getInt(0);
	Date date = new Date(time * 1000);
	result = date.toString().substring(0, 20);
      }
    } catch (IndexOutOfBoundsException e) {
      // Do nothing;
    }
    
    node.setRecentWatchableValue(result);
    node.reExamine();
  }

  public void setNetwork(Network nw) {
    network = nw;
  }

  private int makeRAMKey(int key, int length) {
    int fieldLengthLog2;
    if (length == 1) {
      fieldLengthLog2 = 0; 
    } else if (length == 2) {
      fieldLengthLog2 = 1;
    } else if (length > 2 && length <= 4) {
      fieldLengthLog2 = 2;
    } else if (length > 4 && length <= 8) {
      fieldLengthLog2 = 3;
    } else {
      fieldLengthLog2 = 3;
    }
  
    return (key | (fieldLengthLog2 << 14));
  }

  private int makeRAMLength(int length) {
    if (length == 1) {
      return 1;
    } else if (length == 2) {
      return 2;
    } else if (length > 2 && length <= 4) {
      return 4;
    } else if (length > 4 && length <= 8) {
      return 8;
    } 
    return 0;
  }
}
