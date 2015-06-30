package de.tub.eyes.gui.customelements;

import javax.swing.*;
import javax.swing.event.*;
import javax.swing.tree.*;

import java.util.Vector;
import java.util.Map;
import java.util.TreeMap;
import java.util.Iterator;

import de.tub.eyes.diagram.*;
import de.tub.eyes.comm.MessageReceiver;
import de.tub.eyes.apps.demonstrator.Demonstrator;
import de.tub.eyes.apps.PS.PSSubscription;

import net.tinyos.message.Message;
import de.tub.eyes.ps.*;
import net.tinyos.drain.*;

/**
 *
 * @author Till Wimmer
 */
public class NodePropertyViewer extends JTree implements SelectionListener, MessageReceiver {
    private MyTreeModel model = null;
    private NodePS node = null;
    private final static int DATANODE_TIMEOUT = 30;
    
    public NodePropertyViewer() {
        setModel(model);
        Demonstrator.getMoteComm().addListener(this);
    }
    
    public void selectionChanged(Node n) {
        if (n != null && n instanceof NodePS) {
            if (n != node) {                            
                node = (NodePS)n;
                model = new MyTreeModel("Node " + node.getId());
                setModel(model);
                updateUI();
            }
        }        
    }
    
    public void receiveMessage(Message m) {
        if (node == null || model == null)
            return;
        
        if (!(m instanceof DrainMsg)) {
            System.err.println("NodePropertyViewer.class: No implementation for this message type yet.");
            return;
        }
            
        DrainMsg mhmsg = (DrainMsg)m;
        PSNotificationMsg msgTemp = new PSNotificationMsg(mhmsg, mhmsg.offset_data(0));
        PSNotificationMsg ps2Msg = new PSNotificationMsg(mhmsg, mhmsg.offset_data(0), 
                    msgTemp.DEFAULT_MESSAGE_SIZE + msgTemp.get_dataLength());
        
        if (ps2Msg.get_sourceAddress() != node.getId())
            return;
        model.updateNode(new String [] {"Epoch"},
                String.valueOf(node.getEpoch()));
        model.updateNode(new String [] {"Subcription" + String.valueOf(ps2Msg.get_subscriptionID()),"Header", "parentAddress"}, 
                String.valueOf(ps2Msg.get_parentAddress()));
        model.updateNode(new String [] {"Subcription" + String.valueOf(ps2Msg.get_subscriptionID()),"Header", "subscriberID"},
                String.valueOf(ps2Msg.get_subscriberID()));
        model.updateNode(new String [] {"Subcription" + String.valueOf(ps2Msg.get_subscriptionID()),"Header","modificationCounter"},
                String.valueOf(ps2Msg.get_modificationCounter()));
            
        for (int i=0; i< ps2Msg.getAVPairCount(); i++) {                                                                            
            int attr = ps2Msg.getAVPairAttributeID(i);
            String attrName = PSSubscription.getAttribName(attr);
            
            model.updateNode(new String [] {"Subcription" + String.valueOf(ps2Msg.get_subscriptionID()),"Data", attrName},
                    PSSubscription.arrayToObject(ps2Msg.getAVPairValue(i), attr).toString());                
        }
    }
        
    class MyTreeModel implements TreeModel {
        Vector treeModelListeners = new Vector();        
        DataNode root;
        
        public MyTreeModel(String Name) {
           root = new DataNode(null, Name);
        }
        
        public void addNode(String [] path, String value) {
            String [] base = new String [path.length-1];
            
            for (int i=0; i<path.length-1; i++)
                base[i] = path[i];
            
            DataNode parent = getNode(base);
            if (parent == null) {
                System.err.println("Path" + base + "does not exits!");
                return;
            }
            
            DataNode node = new DataNode(parent, path[path.length-1]);
            node.setValue(value);
            parent.addChild(node);
        }
        
        public void updateNode(String [] path, String value) {
            DataNode node;
            
            node = makePath(path);
            //node = getNode(path);
            fireTreeNodesChanged(node.setValue(value));
        }

        private DataNode makePath(String [] path) {
            DataNode root = null;
            int level = path.length;
            String [] newpath;
            
            
            while ( root == null ) {
                newpath = new String [level];
                for (int i=0; i<level; i++)
                    newpath[i] = path[i];
                
                if ( (root = getNode(newpath)) == null)
                    level--;        
            }
            
            if (level < path.length) {            
                DataNode node = new DataNode(root, path[level]);
                fireTreeNodesInserted(root.addChild(node));
                return makePath(path);
            }
            
            return root;
        }
        
        private DataNode getNode(String [] path) {
            DataNode node = this.root;
            
            for (int i=0; i<path.length; i++) {
                node = getNode(node, path[i]);
                if (node == null)
                    break;
            }
           
            return node;
        }
        
        private DataNode getNode(DataNode root, String Name) {
            Vector childs = root.getChilds();
            
            for (Iterator it=childs.iterator(); it.hasNext();) {
                DataNode child = (DataNode)it.next();
                if (child.getName().equals(Name)) {
                    return child;
                }
            }
            
            return null;
        }
            
        public void setID(String id) {
            root.setValue("Node " + id);
        }
        
        /**
         * Adds a listener for the TreeModelEvent posted after the tree changes.
         */
        public void addTreeModelListener(TreeModelListener l) {
            treeModelListeners.addElement(l);
        }
        
        /**
         * Returns the child of parent at index index in the parent's child array.
         */
        public Object getChild(Object parent, int index) {        
            DataNode dn = (DataNode)parent;
            return dn.getChilds().get(index);
        }

        /**
         * Returns the number of children of parent.
         */
        public int getChildCount(Object parent) {        
            DataNode dn = (DataNode)parent;            
            return dn.getChilds().size();
        }

        /**
         * Returns the index of child in parent.
         */
        public int getIndexOfChild(Object parent, Object child) {     
            DataNode dn = (DataNode)parent;            
            return dn.getChilds().indexOf(child);
        }

        /**
         * Returns the root of the tree.
         */
        public Object getRoot() {        
            return root;
        }

        /**
         * Returns true if node is a leaf.
         */
        public boolean isLeaf(Object node) {        
            DataNode dn = (DataNode)node;            
            return dn.getChilds().size() == 0;
        }

        /**
         * Removes a listener previously added with addTreeModelListener().
         */
        public void removeTreeModelListener(TreeModelListener l) {        
            treeModelListeners.removeElement(l);
        }

        /**
         * Messaged when the user has altered the value for the item
         * identified by path to newValue.  Not used by this model.
         */
        public void valueForPathChanged(TreePath path, Object newValue) {        
            System.out.println("*** valueForPathChanged : "
                    + path + " --> " + newValue);
        }        
    
        private void fireTreeNodesInserted(TreeModelEvent e) {

            for (Iterator it= treeModelListeners.iterator(); it.hasNext();) {
                ((TreeModelListener)it.next()).treeNodesInserted(e);
            }
        }
        
        private void fireTreeNodesChanged(TreeModelEvent e) {

            for (Iterator it= treeModelListeners.iterator(); it.hasNext();) {
                ((TreeModelListener)it.next()).treeNodesChanged(e);
            }
        }        
    }
    
    /*
     * DataNodes have a lifetime DATANODE_TIMEOUT. A DataNode which isn't updated 
     * for DATANODE_TIMEOUT secs erases himself by changing the childs list of his parent
     */
    
    class DataNode {
        DataNode parent;
        String name;
        String value = "null";
        Vector childs = new Vector();
        DataNode [] path = null;
        
        public DataNode(DataNode parent, String name) {
            this.parent = parent;
            this.name = name;

            if (parent == null)
                return;
            
            int size = 0;
            if (parent.getPath() != null)
                size = parent.getPath().length;
            
            path = new DataNode [size+1];
            for (int i=0; i<size; i++)
                path[i] = parent.getPath()[i];
            
            path[size] = parent;            
        }
        
        public DataNode getParent() {
            return this.parent;            
        }
        
        public DataNode [] getPath() {
            return this.path;
        }
        
        public String getName() {
            return this.name;
        }
        
        public Vector getChilds() {
            return this.childs;
        }
        
        public TreeModelEvent addChild(DataNode child) {
            Object [] children = new Object[1];
            int [] childIndices = new int[1];
            
            childs.addElement(child);
            
            childIndices[0] = childs.indexOf(child);
            children[0] = child;
            TreeModelEvent event = new TreeModelEvent(this, child.getPath(), childIndices, children);
            
            System.out.println("Event = " + event.toString());
            return event;
        }
        
        public void removeChild(DataNode child) {
            childs.remove(child);
        }
        
        public String toString() {
            if (childs.size() == 0)
                return name + ": " + value;
            else
                return (name);
        }
        
        public TreeModelEvent setValue(String value) {
            Object [] children = new Object[1];
            int [] childIndices = new int[1];
            
            this.value = value;
            
            childIndices[0] = parent.getChilds().indexOf(this);
            children[0] = this;
            TreeModelEvent event = new TreeModelEvent(parent, this.getPath(), childIndices, children);           
            touch();
            
            return event;
        }
        
        private void onTimeout() {
            if ( parent != null )
                parent.removeChild(this);
        }
        
        /*
         * touch() is called every time the DataNode is updated so the lifetime doesn't exceed.
         */
        private void touch() {
            /*
             *TODO: Update (kill + star new) timer
             */
            if ( parent != null )
                parent.touch();
        }
    }
}
