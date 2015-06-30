import java.util.*;

public class Node {

  public int addr = 65535;
  public String id = null;

  private long lastHeard;
  private long reportPeriod = 65535;

  private String recentWatchableValue = "";

  private Node parent;
  private Map children = new TreeMap();
  
  private NodeView nodeView;
  
  private boolean booting;

  public Node() {    

  }

  public NodeView getNodeView() { return nodeView; }
  public void setNodeView(NodeView nv) { nodeView = nv; }

  public Map getChildren() { return children; }
  public void addChild(Node child) {
    children.put(new Integer(child.getAddr()), child);
  }
  
  public void heardFrom() {
    booting = false;

    if (lastHeard > 0) {
      reportPeriod = reportPeriod / 2 + ((System.currentTimeMillis() - lastHeard)/2);
    }
    lastHeard = System.currentTimeMillis();
    nodeView.repaint();
  }

  public void reExamine() {
    nodeView.repaint();
  }

  public boolean isBooting() {
    return booting;
  }

  public boolean isInactive() {
    return ((System.currentTimeMillis() - lastHeard) > (reportPeriod * 2));
  }

  public int getAddr() { return addr; }
  public void setAddr(int addr) { this.addr = addr; }

  public String getID() { return id; }
  public void setID(String id) { this.id = id; }

  public String getRecentWatchableValue() {
    return recentWatchableValue;
  }

  public void setRecentWatchableValue(String v) {
    recentWatchableValue = v;
  }

  public void booting() {
    booting = !booting;
    lastHeard = System.currentTimeMillis();
    nodeView.repaint();
  }

  public static void main(String args[]) {
    new Node();
  }
}



