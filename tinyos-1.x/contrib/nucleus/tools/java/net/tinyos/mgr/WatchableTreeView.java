import java.awt.Dimension;
import java.awt.Rectangle;
import java.awt.Color;
import java.awt.event.*;
import java.awt.geom.*;
import javax.swing.*;
import javax.swing.tree.*;
import javax.swing.event.*;

import java.util.*;

public class WatchableTreeView extends JPanel
  implements TreeExpansionListener, TreeSelectionListener, Scrollable {

  private WatchableSchema watchableSchema;
  private WatchableUserQuery userQuery;

  private JTree tree;
  private DefaultMutableTreeNode top = 
  new DefaultMutableTreeNode("SNMS Watchables");
  
  private JSplitPane splitPane;

  public WatchableTreeView(WatchableSchema ws, WatchableUserQuery uq) {
    setBackground(Color.WHITE);

    watchableSchema = ws;
    userQuery = uq;

    buildTree();

    tree = new JTree(top);
    tree.getSelectionModel().setSelectionMode
      (TreeSelectionModel.DISCONTIGUOUS_TREE_SELECTION);
    tree.setRootVisible(false);
    tree.setShowsRootHandles(true);

    tree.addTreeExpansionListener(this);
    tree.addTreeSelectionListener(this);

    add(tree);
  }

  private void buildTree() {
    List watchables = watchableSchema.getWatchables();

    for(Iterator it = watchables.iterator(); it.hasNext(); ) {
      Watchable newWatchable = (Watchable) it.next();

      System.err.println(newWatchable.getName());

      String[] nameParts = newWatchable.getName().split("\\.");
      
      DefaultMutableTreeNode curNode = top;
      boolean found;

      for ( int i = 0; i < nameParts.length; i++ ) {
	found = false;

	System.err.println("-" + nameParts[i]);
      
	for ( Enumeration e = curNode.children(); e.hasMoreElements() ;) {
	  DefaultMutableTreeNode node = 
	    (DefaultMutableTreeNode) e.nextElement();
	  
	  if ( ((String)node.getUserObject()).equals(nameParts[i]) ) {
	    curNode = node;
	    found = true;
	    break;
	  }
	}

	if (!found) {
	  DefaultMutableTreeNode newNode = 
	    new DefaultMutableTreeNode(nameParts[i]);
	  curNode.add(newNode);
	  curNode = newNode;
	}
      }
    }
  }

  public Dimension getMinimumSize() {
    return tree.getPreferredSize();
  }

  public Dimension getPreferredSize() {
    return tree.getPreferredSize();
  }

  public void setSplitPane(JSplitPane pane) {
    splitPane = pane;
  }

  // Required by TreeExpansionListener interface.
  public void treeExpanded(TreeExpansionEvent e) {
    System.out.println(tree.getPreferredSize());
    splitPane.resetToPreferredSizes();
  }
  
  // Required by TreeExpansionListener interface.
  public void treeCollapsed(TreeExpansionEvent e) {
    System.out.println(tree.getPreferredSize());
    splitPane.resetToPreferredSizes();
  }

  public void valueChanged(TreeSelectionEvent e) {
    TreePath path = tree.getSelectionPath();
    
    if (path == null)
      return;
    
    System.out.println(path);

    userQuery.clearWatchable();

    /*
    if (path.getPathCount() < 3) {
      return;
    }
    */

    String key = "";

    if (path.getPathCount() == 3) {
      key = path.getPathComponent(1) + "." + path.getPathComponent(2);
    } else if (path.getPathCount() == 2) {
      key = "" + path.getPathComponent(1);
    }

    System.out.println("Query: " + key);

    userQuery.addWatchable(key);
  }

  public Dimension getPreferredScrollableViewportSize() {
    return getMinimumSize();
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
    return false;
  }
  
  public boolean getScrollableTracksViewportHeight() {
    return false;
  }
}








