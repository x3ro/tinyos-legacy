/*
 * Project EYES Demonstrator
 *
 * Created on 24.09.2004
 */
package de.tub.eyes.diagram;

import java.util.*;

/**
 * This class holds the Selection for the {@link de.tub.eyes.diagram.Diagram Diagram}. It stores the
 * selected Nodes and supports adding and removing of nodes from or to the Selection. In that operation
 * it sets the 'selected' property of the Nodes, so these are drawn correct.
 *
 * @author Joachim Praetorius
 */
public class Selection {
    List selection;

    /**
     * Creates a new Selection Object
     *
     */
    public Selection() {
        selection = new ArrayList();

    }

    /**
     * Adds a new Node to the Selection. If add is <code>true</code> the selection is extended by the
     * new Node, all previously selected Nodes stay selected. This particularly means that the Node returned by
     * {@link #getPrimarySelection() getPrimarySelection()} doesn't change.
     * If add is <code>false</code> all other selected nodes get deselected before the given node is selected.
     * By that the given Node is the one returned by {@link #getPrimarySelection() getPrimarySelection()}.
     * @param node The node to add
     * @param add <code>true</code> if Selection should be extended, <code>false</code> otherwise
     */
    public void add(Node node, boolean add) {

        if (node == null) {
            clear();
            return;
        }

        if (add) {
            if (selection.remove(node)) {
                node.setSelected(false);

//                for (Iterator it = selection.iterator(); it.hasNext();) {
//                  System.out.println("selected nodes: " + (Node) it.next());
//                }

                return;
            }
        } else {
            clear();
        }
        selection.add(node);
        node.setSelected(true);

//        for (Iterator it = selection.iterator(); it.hasNext();) {
//          System.out.println("selected nodes: " + (Node) it.next());
//        }

    }

public void add(Node node) {

  if(selection.contains(node)) {
    return;
  } else {
    selection.add(node);
 //   System.out.println("in Selection#add: primaryNode = " + node);
 //    node.setSelected(true);
  }

}

public void remove(Node node) {

  if(selection.contains(node)) {
    selection.remove(node);
//    node.setSelected(false);
  } else {
    return;
  }

//  primaryNode = node;
//  System.out.println("in Selection#remove: primaryNode = " + node);

}

    /**
     * Returns the primary Selected Node. If more than one node is selected this is the node
     * that was selected first. Otherwise it is the selected node.
     * @return The primary selected Node, or <code>null</code> when no node is selected.
     */
    public Node getPrimarySelection() {
        try {
//          for(int i = 0; i< selection.size(); i++) {
//            System.out.println("selection[" + i + "]: " + selection.get(i));
//          }
          return (Node) selection.get(0); // used to be 0 => primary selected node is the first selected one
        } catch (IndexOutOfBoundsException e) {
            return null;
        }

    }

    /**
     * Sets all selected nodes to unselected and removes them from the selection
     *
     */
    private void clear() {
        for (Iterator it = selection.iterator(); it.hasNext();) {
            ((Node) it.next()).setSelected(false);
        }
        selection.clear();
    }

}
