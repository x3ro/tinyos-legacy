import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;
import javax.swing.*;

import java.util.*;

public class TreeColumnView extends JPanel implements Scrollable, NetworkListener {

  private Network network;

    private ArrayList levelPanels;

  public TreeColumnView() {
    setBackground(Color.WHITE);
    setLayout(new BoxLayout(this, BoxLayout.LINE_AXIS));
  }

  public void setNetwork(Network nw) {
    network = nw;
  }

  public void nodeAdded(Node n) {
    NodeView nv = new NodeView(n);
    n.setNodeView(nv);
    System.out.println("Node Added" + n);
    organizeNodes();
  }

    private void organizeNodes() {
	if (network == null)
	    return;

	Map bridges = network.getBridgeMap();

	levelPanels.clear();
	addNodes(bridges, 0);

	removeAll();

	for(Iterator it = levelPanels.iterator(); it.hasNext(); ) {
	    JPanel panel = (JPanel) it.next();
	    add(panel);
	}

	doLayout();
    }

    private void addNodes(Map nodes, int depth) {
	JPanel level;

	if (levelPanels.size() > depth) {
	    level = (JPanel) levelPanels.get(depth);
	} else {
	    level = new JPanel();
	    level.setLayout(new BoxLayout(level, BoxLayout.PAGE_AXIS));
	    levelPanels.add(depth, level);
	}
 
	for(Iterator it = nodes.values().iterator(); it.hasNext(); ) {
	    Node node = (Node) it.next();
	    NodeView nodeView = node.getNodeView();
	    level.add(nodeView);
	    addNodes(node.getChildren(), depth+1);
	}
    }

  public Dimension getPreferredScrollableViewportSize() {
    return getPreferredSize();
  }

  public int getScrollableUnitIncrement(Rectangle visibleRect,
					int orientation,
					int direction) {
    return NodeView.NODE_HEIGHT/4;
  }
  
  public int getScrollableBlockIncrement(Rectangle visibleRect,
					 int orientation,
					 int direction) {
    if (orientation == SwingConstants.HORIZONTAL) {
      return NodeView.NODE_WIDTH; 
    } else {
      return NodeView.NODE_HEIGHT/2;
    }
  }

  public boolean getScrollableTracksViewportWidth() {
    return true;
  }
  
  public boolean getScrollableTracksViewportHeight() {
    return false;
  }

  public static void main(String args[]) {
  }
}



