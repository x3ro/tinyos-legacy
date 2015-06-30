package de.tub.eyes.gui.customelements;

import java.awt.Color;

import java.awt.Component;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.beans.BeanInfo;

import javax.swing.*; //modified by Chen
import javax.swing.event.*;
import javax.swing.BorderFactory;

import com.jgoodies.forms.builder.PanelBuilder;
import com.jgoodies.forms.layout.CellConstraints;
import com.jgoodies.forms.layout.FormLayout;
import com.l2fprod.common.model.DefaultBeanInfoResolver;
import com.l2fprod.common.propertysheet.PropertySheet;
import com.l2fprod.common.propertysheet.PropertySheetPanel;

import de.tub.eyes.diagram.Node;
import de.tub.eyes.model.NodeListChangeListener;
import de.tub.eyes.diagram.Diagram;
import de.tub.eyes.diagram.Selection;
import de.tub.eyes.diagram.JDiagramViewer;
import de.tub.eyes.diagram.SelectionListener;
import de.tub.eyes.components.AbstractNetworkComponent;

/**
 * done by Chen
 */

public class NodeListViewer extends JComponent implements NodeListChangeListener, ActionListener, ListSelectionListener {

    private FormLayout layout;
    private PanelBuilder builder;
    private CellConstraints cc;
    private BeanInfo beanInfo;
    private DefaultBeanInfoResolver resolver;
    private de.tub.eyes.diagram.Node data;
    private javax.swing.Timer timer;
    private DefaultListModel listModel;
    private JList nodeList;
    private Selection selection;
    private AbstractNetworkComponent nvc;
    private JDiagramViewer viewer;


    /**
     * Creates a new NodeListViewer with the needed Components
     *
     */
    public NodeListViewer() {
        layout = new FormLayout("p", "p,3dlu,p");
        cc = new CellConstraints();
        builder = new PanelBuilder(layout);
        listModel = new DefaultListModel();

        nodeList = new JList(listModel);
        nodeList.addListSelectionListener(this);
 
        //timer = new javax.swing.Timer(1000, this);
        //timer.start();

        selection = new Selection();
    }

    /**
     * Returns the Component that displays the NodeListViewer
     *
     * @return the Component that displays the NodeListViewer
     */
    public Component buildUI() {
        builder.addLabel("Select for Oscope:", cc.xy(1,1));
        builder.add(nodeList,cc.xy(1, 3));

        return builder.getPanel();
    }

    /**
     * Sets the NodeListViewer inspects
     * @param newNode
     */
    public void addNode(Node newNode) {
      listModel.addElement(newNode);
      sortList();
     }

    public void removeNode(Node node) {
      listModel.removeElement(node);
      sortList();
     }
    
    /**
     * Updates the display. For that a {@link javax.swing.Timer Timer} is used, that calls this Method
     * periodically every 1000ms
     * @see java.lang.Runnable#run()
     * @param e
     */
    public void actionPerformed(ActionEvent e) {
        if (data != null) {
        // to be done
        }
    }

    public void setJDiagramViewer(JDiagramViewer viewer) {      
        //this.viewer = viewer;
    }

    public void setNetworkViewComponent(AbstractNetworkComponent n) {
      this.nvc = n;
    }

    public void valueChanged(ListSelectionEvent e){

      Object[] o = nodeList.getSelectedValues();

      if(o.length == 0) {
        for (int ii=0;ii<nodeList.getModel().getSize();ii++) {
          Node m = (Node) nodeList.getModel().getElementAt(ii);
          //viewer.addNodeToSelection(m,false);
          nvc.fireRemoveFromFilter(m.getId());
        }
      } else {

        for (int i=0;i<nodeList.getModel().getSize();i++) {
          Node m = (Node)nodeList.getModel().getElementAt(i);

          //System.out.println("NodeListViewer - handling " + m +" now !!!!!!!!!!");
          m.setSelected(false); // set the node to unselected

          for(int j=0;j<o.length;j++) {
            Node n = (Node) o[j];

            if(m.equals(n)) {
              m.setSelected(true);
              break;
            }
          }

          if(m.isSelected()) {
            //viewer.addNodeToSelection(m,true);
            nvc.fireAddToFilter(m.getId());
          }
          else {
              //viewer.addNodeToSelection(m,false);
              nvc.fireRemoveFromFilter(m.getId());
            }
        }
      }
    }
    
    private void sortList() {
        int size = listModel.getSize();
        Object [] elements = new Node[size];
        
        for (int index=0; index < size; index++) {
            elements[index] = listModel.getElementAt(index);
        }
        
        java.util.Arrays.sort(elements, new MyNodeComparator());
        
        listModel.clear();
        for (int index=0; index < size; index++) {
            listModel.add(index,elements[index]);
        }       
    }
    
    class MyNodeComparator implements java.util.Comparator {
  
        public int compare( Object o1, Object o2 ) {
    
            return ( ((Node)o1).getId() - ((Node)o2).getId() );
        }
    }       
}



