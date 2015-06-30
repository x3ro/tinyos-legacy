import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;
import javax.swing.*;

import java.util.*;

public class GridView extends NetworkView 
  implements Scrollable, NetworkListener {
  
  private Network network;
  private GridLayout gridLayout = new GridLayout();
  private Set nodeViewSet = new HashSet();
  
  JPanel innerPane;
  
  public GridView(Network n) {
    setBackground(Color.WHITE);
    setLayout(gridLayout);
    
    network = n;
    network.addNetworkListener(this);

    addComponentListener(new ComponentAdapter() {
	public void componentResized(ComponentEvent e) {
	  redoGrid();
	}
      });
  }

  public void redoGrid() {

    int cols = (getWidth() / NodeView.NODE_WIDTH);

    if (cols == 0)
	return;

    ((GridLayout)getLayout()).setColumns(cols);
    
    double rows = (getComponentCount() / (double)cols);
    int realRows = (getComponentCount() / cols);
    
    if ((rows - realRows) > 0)
      realRows++;
    
    //    System.out.println(getWidth() + ":" + cols + ":" + rows + 
    // ":" + realRows);
    
    ((GridLayout)getLayout()).setRows(realRows);

    revalidate();
    repaint();
    
    //    System.out.println(getLayout());
  }

  public void paintComponent(Graphics g) {
    super.paintComponent(g);
  }

  public void nodeAdded(Node n) {
    NodeView nv = new NodeView(n);
    n.setNodeView(nv);
    add(nv);
    //    System.out.println("Node Added" + n);
    redoGrid();
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
