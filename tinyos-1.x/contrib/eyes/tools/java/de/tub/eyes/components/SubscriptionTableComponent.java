/*
 * SubscriptionTableComponent.java
 *
 * Created on 18. Juli 2005, 20:55
 */

package de.tub.eyes.components;

import java.awt.Component;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.Dimension;

import java.util.*;

import javax.swing.*;
import javax.swing.event.*;
import javax.swing.table.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;

import net.tinyos.message.Message;
import de.tub.eyes.ps.*;
import net.tinyos.drain.*;
import net.tinyos.surge.*;
import com.jgoodies.forms.builder.PanelBuilder;
import com.jgoodies.forms.builder.ButtonBarBuilder;
import com.jgoodies.forms.layout.CellConstraints;
import com.jgoodies.forms.layout.FormLayout;

import de.tub.eyes.apps.demonstrator.*;
import de.tub.eyes.gui.customelements.CaptionBorder;
//import de.tub.eyes.comm.SubscriptionListener;
import de.tub.eyes.comm.MessageReceiver;
import de.tub.eyes.apps.PS.*;
/**
 *
 * @author Till Wimmer
 */
public class SubscriptionTableComponent extends AbstractComponent 
        implements ActionListener, MessageReceiver, SnapshotHandler {
    
    private JPanel panel, buttonBar;
    private JToggleButton tButton;
    private JTable table;
    private JButton unsubscribeButton, editButton, newButton;
    
    private Demonstrator d;
    
    private PanelBuilder builder;
    private FormLayout layout;
    
    private Map subscriptions = new TreeMap();
    private int [] subscrIDs;
    private int subscrCnt = 0;
    private Map recvCntrMap = new TreeMap();
    private final int firstID = 1;
    private int lastID = firstID -1;
    
    /** Creates a new instance of SubscriptionTableComponent */
    public SubscriptionTableComponent(Demonstrator d) {
        this.d = d;
        buildUI();
        Snapshot.addSnapshotHandler(this);
     }

    /**
     * Returns the UI for this Component. In this case it is a JPanel
     * @see de.tub.eyes.components.AbstractComponent#getUI()
     */
    public Component getUI() {
        CompoundBorder b = new CompoundBorder(new CaptionBorder(
                "Subscription Panel"), new EmptyBorder(10, 10, 10, 10));
        panel.setBorder(b);
        return panel;
    } 
    
    /**
     * Returns the ToggleButton for this component 
     * @see de.tub.eyes.components.AbstractComponent#getButton()
     */
    public JToggleButton getButton() {
        return tButton;
    }
 
    public void actionPerformed(ActionEvent e) {
        if (e.getSource() == editButton ) {
            actionEdit();            
        }
        
        if (e.getSource() == newButton) {
            actionNew();
        }
        
        if (e.getSource() == unsubscribeButton) {
            actionUnsubscribe();
            table.updateUI();
        }        
    }  
    
    /**
     * Creates the UI
     *
     */
    private void buildUI() {
        initComponents();

        tButton = new JToggleButton("<html>Subscribe<br>Panel");
        tButton.setHorizontalAlignment(JButton.LEFT);
        tButton.setActionCommand("subscriptionpanel");

        layout = new FormLayout("3dlu,d,3dlu", "3dlu,t:d,3dlu,p,3dlu");
        builder = new PanelBuilder(layout);
        panel = builder.getPanel();
        
        // Obtain a reusable constraints object to place components in the grid.
        CellConstraints cc = new CellConstraints();
                
        builder.add(new JScrollPane(table), cc.xy(2,2));
        builder.add(buttonBar, cc.xy(2,4));
    }
    
    /**
     * Creates, intializes and configures the UI components. 
     * Real applications may further bind the components to underlying models. 
     */
    private void initComponents() {
        initTable();
                
        newButton = new JButton("New");
        newButton.addActionListener(this);
        unsubscribeButton = new JButton("Unsubscribe");
        unsubscribeButton.addActionListener(this);
        editButton = new JButton("Edit");
        editButton.addActionListener(this);
        
        ButtonBarBuilder builder = new ButtonBarBuilder();        
        builder.addGriddedButtons(new JButton [] { newButton, editButton, unsubscribeButton});
        
        buttonBar = builder.getPanel();
    }
       
    void initTable() {
        TableModel model = new PSTableModel();
        table = new JTable(model);

        //table.setPreferredScrollableViewportSize(new Dimension(100,40));                
        //table.setRowHeight(20);
        //table.setGridColor(Color.gray);
        //table.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);        
    }
    
    void actionEdit() {                
        int row = table.getSelectedRow();        
        if (row == -1)
            return;        

        PSSubscription subscription = (PSSubscription)subscriptions.get(new Integer(subscrIDs[row]));
        if (subscription == null)
            return;
        
        JFrame frame = new SubscriptionComponent("Edit Subscription",d, subscription, this);  
        frame.setVisible(true);
    }
    
    void actionNew() {
        JFrame frame = new SubscriptionComponent("New Subscription", d, null, this);
        frame.setVisible(true);        
    }
    
    public void updateSubscription(PSSubscription subscription) {        
        if (subscription.getID() != -1) {
            subscriptions.put(new Integer(subscription.getID()), subscription);
        }
        else {
            lastID++;
            subscription.setID(lastID);
            subscriptions.put(new Integer(subscription.getID()), subscription);
        }
        subscription.setFlag(PSSubscription.FLAG_SUBSCRIBE);
        System.out.println("Subscribe " + subscription.toString());        
        subscription.send();
        updateSubscriptionIDs();
        table.updateUI();
    }
        
    private void actionUnsubscribe() {
        int row = table.getSelectedRow();        
        if (row == -1)
            return;
        
        PSSubscription subscription = (PSSubscription)subscriptions.get(new Integer(subscrIDs[row]));
        if ( subscription == null) {
            System.err.println("actionUnsubscribe failed: ID "+subscrIDs[row]+" not found!");
            return;
        }
        
        subscription.incModificationCounter();
        System.out.println("Unsubscribe " + subscription.toString());
        subscription.setFlag(PSSubscription.FLAG_UNSUBSCRIBE);
        subscription.send();
        //subscriptions.remove(new Integer(subscrIDs[row]));
        updateSubscriptionIDs();
        table.updateUI();
    }
    
    private void updateSubscriptionIDs() {
            
        int subscrCntTmp = 0;
        PSSubscription subscr;
        subscrIDs = new int[subscriptions.size()];
        for (Iterator it = subscriptions.keySet().iterator(); it.hasNext();) {                       
            if ((subscr = (PSSubscription)subscriptions.get(it.next())) != null)
                subscrIDs[subscrCntTmp++] = subscr.getID();
        }
        
        subscrCnt = subscrCntTmp;
    }
    
    private void updateLastID() {
        int highestID = firstID -1;
        PSSubscription subscr;
        
        for (Iterator it = subscriptions.keySet().iterator(); it.hasNext();) {                       
            if ((subscr = (PSSubscription)subscriptions.get(it.next())) != null)
                if ( subscr.getID() >= highestID )
                    highestID = subscr.getID();
        }
        
        lastID = highestID;
    }
    
    public void receiveMessage(Message m) {
        if (d.isSurge())
            return;
        
        PSNotificationMsg ps2Msg;
        
        if (d.isDrip() ) {
            DrainMsg mhmsg = (DrainMsg)m;
            ps2Msg = new PSNotificationMsg(mhmsg, mhmsg.offset_data(0));            
        }
        else {
            MultihopMsg msg = new MultihopMsg(m.dataGet());
            ps2Msg = new PSNotificationMsg(msg.dataGet(), msg.offset_data(0));            
        }
        
        Integer ID = new Integer(ps2Msg.get_subscriptionID());
        int cnt = 1;
        
        if (recvCntrMap.containsKey(ID))
            cnt = ((Integer)recvCntrMap.get(ID)).intValue() + 1;
        
        recvCntrMap.put(ID, new Integer(cnt));
        
        table.updateUI();
    }
    
    public void restoreSnapshot(TreeMap data) {
        subscriptions = data;
        subscrCnt = subscriptions.size();
        updateSubscriptionIDs();
        updateLastID();
        table.updateUI();
    }
    
    public TreeMap getSnapshot() {
        return (TreeMap)subscriptions;
    }
    
    class PSTableModel extends AbstractTableModel {
        private int columnCount = 6;
        
        public int getRowCount() {
            return subscrCnt;
        }
        
        public int getColumnCount() {
            return columnCount;
        }
        
        public Object getValueAt(int row, int column) {
                        
            PSSubscription subscr = (PSSubscription)subscriptions.get(new Integer(subscrIDs[row]));
            
            if (subscr == null)
                return new Integer(-1);
            
            switch (column ) {
               case 0:
                    return new Integer(subscr.getID());
                    
                case 1:
                    return new Integer(subscr.cntAvpairs());
                    
                case 2:
                    return new Integer(subscr.cntConstraints());
                    
                case 3:
                    Integer ID = new Integer(subscr.getID());
                    if (recvCntrMap.containsKey(ID))
                        return recvCntrMap.get(ID);
                    else
                        return new Integer(0);
                    
                case 4:
                    return new Integer(subscr.getModificationCounter());
                    
                case 5:
                    if (subscr.getFlag() == PSSubscription.FLAG_SUBSCRIBE)
                        return "*";
                    else
                        return "";
                    
                default:
                    return new Integer(-1);
            }
        }
        
        public String getColumnName(int column) {
            String[] headings = {
                "Subscr. No.", "Commands", "Constraints", "Received", "Modif. Ctr.", "Active"                
            };
            
            return headings[column];            
        }
    }
}
