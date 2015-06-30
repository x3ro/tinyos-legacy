import java.util.*;
import net.tinyos.mgmtquery.*;
import net.tinyos.message.*;
import net.tinyos.util.*;
import net.tinyos.hello.*;

public class Network implements ResultListener, MessageListener {

  private NetworkListener networkListener;

  public Map nodes = new HashMap();
  public Map bridges = new TreeMap();
  
  private WatchableSchema schema;
  private MgmtQueryHost queryHost;
  private MgmtQuery enumQuery;
  private List enumQueryWatchables;

  private Timer enumQueryTimer = new Timer();

  private MoteIF moteIF;

  private static int QUERY_PERIOD = 8;
  
  public Network() {

    try {
      moteIF = new MoteIF(PrintStreamMessenger.err);
      moteIF.registerListener(new HelloMsg(), this);
      queryHost = new MgmtQueryHost();  
    } catch (Exception e) {
      System.out.println("ERROR: Couldn't contact serial forwarder.");
    }

    enumQueryTimer.schedule(new TimerTask() {
	public void run() {
	  System.out.println("Sending Enumeration Query");
	  
	  for(Iterator it = nodes.values().iterator(); it.hasNext(); ) {
	    Node node = (Node) it.next();
	    node.reExamine();
	  }
	  
	  if (moteIF != null) 
	    sendEnumQuery();
	}
      }, 
			    1000, QUERY_PERIOD * 1000);
  }
  
  public void addNetworkListener(NetworkListener nl) {
    networkListener = nl;
    for(Iterator it = nodes.values().iterator(); it.hasNext(); ) {
      Node node = (Node) it.next();
      networkListener.nodeAdded(node);
    }
  }

  public void setWatchableSchema(WatchableSchema ws) {
    schema = ws;
  }

  private void sendEnumQuery() {

    if (schema != null) {

      enumQuery = new MgmtQuery(4);
      enumQueryWatchables = new ArrayList();

      Watchable hardwareID = schema.getWatchable("HelloM.MoteSerialID");
      
      if (hardwareID != null) {
	enumQueryWatchables.add(hardwareID);
	enumQuery.appendKey(hardwareID.getKey(), hardwareID.getLength());
      }
      queryHost.sendOneShotQuery(enumQuery, 1, this);
    }
  }
  
  public void addResult(MgmtQueryResult qr) {
    
    Node node = (Node) nodes.get(new Integer(qr.getSourceAddr()));
    
    if (node == null) {
      node = new Node();
      node.setAddr(qr.getSourceAddr());
      try {
	node.setID(qr.getOctetString(0));
      } catch (IndexOutOfBoundsException e) {
	// Do nothing
      }
      addNode(node);
    }

    node.heardFrom();
  }
  
  public void addNode(Node node) {
    nodes.put(new Integer(node.getAddr()), node);
    if (networkListener != null) 
      networkListener.nodeAdded(node);
  }

  public void addBridge(Node node) {
      bridges.put(new Integer(node.getAddr()), node);
      if (networkListener != null) 
	  networkListener.nodeAdded(node);
  }

  public Node getNode(int id) {
    return (Node) nodes.get(new Integer(id));
  }

  public Map getNodeMap() { return nodes; }
  public Map getBridgeMap() { return bridges; }
  
  synchronized public void messageReceived(int to, Message m) {
    HelloMsg helloMsg = (HelloMsg) m;
    
    Node node = (Node) nodes.get(new Integer(helloMsg.get_sourceAddr()));
    
    if (node == null) {
      node = new Node();
      node.setAddr(helloMsg.get_sourceAddr());
      addNode(node);
    }
    
    node.booting();
  }

  public void testInit() {
    addBridge(new Node());
    addNode(new Node());
    addNode(new Node());
  }
  
  public static void main(String args[]) {
    Network nw = new Network();
  }  
}
