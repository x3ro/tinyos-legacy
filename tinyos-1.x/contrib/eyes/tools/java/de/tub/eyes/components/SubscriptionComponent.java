/*
 * SubscriptionComponent.java
 *
 * Created on 10. Februar 2005, 17:07
 */

package de.tub.eyes.components;

import java.awt.Component;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.*;

import javax.swing.*;
import javax.swing.event.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;

import net.tinyos.message.Message;
import de.tub.eyes.ps.*;
import com.jgoodies.forms.builder.DefaultFormBuilder;
import com.jgoodies.forms.layout.CellConstraints;
import com.jgoodies.forms.layout.FormLayout;
import com.jgoodies.forms.layout.RowSpec;

import de.tub.eyes.apps.demonstrator.*;
import de.tub.eyes.gui.customelements.CaptionBorder;
import de.tub.eyes.comm.SubscriptionListener;
import de.tub.eyes.apps.PS.*;

/**
 *
 * @author Till Wimmer
 */
public class SubscriptionComponent extends JFrame 
        implements ActionListener {
    
    JPanel panel;
    JToggleButton tButton;
    
    private Demonstrator d;
    private PSSubscription subscription = null;
    
    private DefaultFormBuilder builder;
    private FormLayout layout;
    private SubscriptionTableComponent stc;
     
    private JButton avpairAddButton, avpairRemButton, constrAddButton, constrRemButton, okButton, cancelButton;
    
    private static int [] seqNo = {1, 1};
    private static Vector listener = new Vector();
    
    private Map editElements = new TreeMap();
        
    private int lastLine=2, lastConstrLine=6, lastAvpairLine=6, lastInsLine=6;
    
    private int eeID=-1;
    
    public static int [] constrIDs = PSSubscription.getConstraintIDs();
    public static int [] avIDs = PSSubscription.getAVPairIDs();
    public static int subscriberID = Integer.parseInt(Demonstrator.getProps().getProperty("uartAddr","126"));

    private final static int initFields = 3;
    /** Creates a new instance of SubscriptionComponent */
    public SubscriptionComponent(String title, Demonstrator d, PSSubscription subscription, SubscriptionTableComponent stc) {
        super(title);
        this.d = d;
        this.subscription = subscription;
        this.stc = stc;
        
        buildUI();
        getContentPane().add(panel);
        pack();
    }
    
    /**
     * Reacts on the Buttons and the Combo
     * @see java.awt.event.ActionListener#actionPerformed(java.awt.event.ActionEvent)
     */
    public void actionPerformed(ActionEvent e) {
        Object source = e.getSource();
        if (source == avpairAddButton ) {
            actionAvpairAdd(null);
        }
                 
        if (source == constrAddButton ) {
            actionConstrAdd(null);
        }
        
        if (source == okButton) {
            if (!consolidate())
                return;
            
            subscription.incModificationCounter();
            stc.updateSubscription(subscription);
            //panel.setVisible(false);
            dispose();
        }
        
        if (source == cancelButton)
            dispose();
        
        if (source == constrRemButton) {
            actionConstrRem();
        }

        if (source == avpairRemButton) {
            actionAvpairRem();
        }
        
        if ( source instanceof JComboBox
                && ((JComboBox)source).getSelectedItem() != null ) {
            checkCB(source, e.getActionCommand());
            
        }
    }
    
    /**
     * Returns the UI for this Component. In this case it is a JPanel
     * @see de.tub.eyes.components.AbstractComponent#getUI()
     */
    public Component getUI() {
        //CompoundBorder b = new CompoundBorder(new CaptionBorder(
        //        "Subscription Panel"), new EmptyBorder(10, 10, 10, 10));
        //panel.setBorder(b);
        return panel;
    } 
    
    /**
     * Returns the ToggleButton for this component 
     * @see de.tub.eyes.components.AbstractComponent#getButton()
     */
    public JToggleButton getButton() {
        return tButton;
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
        panel = new JPanel();
        layout = new FormLayout("6dlu,p,6dlu,p,6dlu,p,6dlu,p,24dlu,p,6dlu,p,6dlu,p,6dlu",
                "3dlu,p,6dlu,p,3dlu,p,3dlu,p,3dlu,p,3dlu,p,3dlu,p");
        builder = new DefaultFormBuilder(panel, layout);
        
        // Obtain a reusable constraints object to place components in the grid.
        CellConstraints cc = new CellConstraints();
                
        layout.setColumnGroups(new int[][]{ {4, 6, 8, 12, 14}, {2, 10} });
        
        if (subscription == null) {
            subscription = new PSSubscription(-1,subscriberID);
            
            builder.addSeparator("new Subscription", cc.xyw(2, lastLine+=2, 13));
            builder.addLabel("Constraints", cc.xyw(2,lastLine+=2,3));
            builder.addLabel("Commands", cc.xyw(10,lastLine,3));            
            
            //actionAvpairAdd(null);
           // actionConstrAdd(null);
            
            //if (lastConstrLine > lastAvpairLine)
            //    lastLine = lastConstrLine;
            //else
            //    lastLine = lastAvpairLine;
            
        }
        else {
            builder.addSeparator("Subscription " + subscription.getID(), cc.xyw(2, lastLine+=2, 13));
            builder.addLabel("Constraints", cc.xyw(2,lastLine+=2,3));                        
            builder.addLabel("Commands", cc.xyw(10,lastLine,3));
            
            for (Iterator it= subscription.getAvpairsIterator(); it.hasNext(); ) {
                AvpairEditElement aee = new AvpairEditElement(this, (Avpair)it.next());
                actionAvpairAdd(aee);                
            }
             
            for (Iterator it= subscription.getConstraintsIterator(); it.hasNext(); ) {
                ConstraintEditElement cee = new ConstraintEditElement(this, (Constraint)it.next());
                actionConstrAdd(cee);                
            }
 
            if (lastConstrLine > lastAvpairLine)
                lastLine = lastConstrLine;
            else
                lastLine = lastAvpairLine;
                        
        }
              
        builder.add(constrAddButton, cc.xy(4, lastLine+=2));
        builder.add(constrRemButton, cc.xy(6, lastLine));
        builder.add(avpairAddButton, cc.xy(12, lastLine));
        builder.add(avpairRemButton, cc.xy(14, lastLine));
        
        builder.addSeparator("", cc.xyw(2, lastLine+=2, 13));
        builder.add(okButton, cc.xy(4, lastLine+=2));
        builder.add(cancelButton, cc.xy(6, lastLine)); 
        
        //lastLine = line;
    }
    
    /**
     * Creates, intializes and configures the UI components. 
     * Real applications may further bind the components to underlying models. 
     */
    private void initComponents() {
        avpairAddButton = new JButton("Add");
        avpairAddButton.addActionListener(this);
        avpairRemButton = new JButton("Remove");
        avpairRemButton.addActionListener(this);
        constrAddButton = new JButton("Add");
        constrAddButton.addActionListener(this);
        constrRemButton = new JButton("Remove");
        constrRemButton.addActionListener(this);
        if (subscription == null)
            okButton = new JButton("Subscribe");
        else
            okButton = new JButton("Update");            
        okButton.addActionListener(this);
        cancelButton = new JButton("Cancel");
        cancelButton.addActionListener(this);        
    }    
            
    private void actionAvpairAdd(AvpairEditElement aee) {
        if (aee == null)
            aee = new AvpairEditElement(this);
            
        editElements.put(aee.getID(), aee);        

        if (lastAvpairLine >= lastConstrLine) {
            lastInsLine = lastAvpairLine;
            addElements(1);
        }
        
        CellConstraints cc = new CellConstraints();
        builder.add(aee.getSelCheck(), cc.xy(10,lastAvpairLine+=2));
        builder.add(aee.getAttrCB(), cc.xy(12,lastAvpairLine));
        builder.add(aee.getValTF(), cc.xy(14,lastAvpairLine));

        panel.updateUI();        
        pack();
    }
    
    private void actionConstrAdd(ConstraintEditElement cee) {
        if (cee == null) {
            cee = new ConstraintEditElement(this);
            setOperatorCB(cee.getOpCB(),0);
        }
            
        editElements.put(cee.getID(), cee);

        if (lastConstrLine >= lastAvpairLine) {
            lastInsLine = lastConstrLine;
            addElements(1);
        }
        
        CellConstraints cc = new CellConstraints();        
        builder.add(cee.getSelCheck(), cc.xy(2,lastConstrLine+=2));
        builder.add(cee.getAttrCB(), cc.xy(4,lastConstrLine));
        builder.add(cee.getOpCB(), cc.xy(6,lastConstrLine));
        builder.add(cee.getValTF(), cc.xy(8,lastConstrLine));
        
        panel.updateUI();
        pack();
    }
    
    private void actionAvpairRem() {
        Vector toDel = new Vector();
        
        for (Iterator it = editElements.keySet().iterator(); it.hasNext(); ) {
            Object obj = editElements.get(it.next());
            
            if (obj instanceof AvpairEditElement) {
                AvpairEditElement aee = (AvpairEditElement)obj;
                
                if (aee.getSelCheck().isSelected()) {
                    builder.getContainer().remove(aee.getSelCheck());
                    builder.getContainer().remove(aee.getAttrCB());
                    builder.getContainer().remove(aee.getValTF());
                    toDel.addElement(aee.getID());                    
                }
            }
        }
 
        for (Iterator it = toDel.iterator(); it.hasNext(); ) {
            if ( editElements.remove((Integer)it.next()) == null)
                System.err.println("Error removing AVPair.");
        }
        
        panel.updateUI();        
        pack();
    }
    
    private void actionConstrRem() {
        Vector toDel = new Vector();
        
        for (Iterator it = editElements.keySet().iterator(); it.hasNext(); ) {
            Object obj = editElements.get(it.next());
            
            if (obj instanceof ConstraintEditElement) {
                ConstraintEditElement cee = (ConstraintEditElement)obj;
                if (cee.getSelCheck().isSelected()) {
                    builder.getContainer().remove(cee.getSelCheck());
                    builder.getContainer().remove(cee.getAttrCB());
                    builder.getContainer().remove(cee.getOpCB());
                    builder.getContainer().remove(cee.getValTF());
                    toDel.addElement(cee.getID());
                }
            }
        }
        
        for (Iterator it = toDel.iterator(); it.hasNext(); ) {
            if ( editElements.remove((Integer)it.next()) == null)
                System.err.println("Error removing Constraint.");
        }
        
        panel.updateUI();        
        pack();
    }
    
    private void addElements(int cnt) {
        for (int i = 0; i < cnt; i++) {
            //lastInsLine+=2;            
            layout.insertRow(lastInsLine+=1, new RowSpec("6dlu"));    
            layout.insertRow(lastInsLine+=1, new RowSpec("p"));
        }
    }
    
    private boolean consolidate() {
        subscription.clear();
        for (Iterator it = editElements.keySet().iterator(); it.hasNext(); ) {
            Object obj = editElements.get(it.next());
            
            if (obj instanceof ConstraintEditElement) {
                ConstraintEditElement cee = (ConstraintEditElement)obj;
                int attrID = constrIDs[cee.getAttrCB().getSelectedIndex()];
                int [] opIDs = PSSubscription.getOperationIDs(attrID);
                long value = -1;
                try {
                    value = Long.parseLong(cee.getValTF().getText());
                } catch (NumberFormatException e) {                      
                    JOptionPane.showMessageDialog(null, 
                            "The value of " + PSSubscription.getAttribName(attrID) + " is not numeric",
                            "Number Format Error",
                            JOptionPane.ERROR_MESSAGE);
                    
                    return false;                  
                }
                
                if (value < PSSubscription.getAttribMin(attrID) || value > PSSubscription.getAttribMax(attrID)) {
                    JOptionPane.showMessageDialog(null, 
                            "The value of " + PSSubscription.getAttribName(attrID) 
                            + " is not in the allowed range " + PSSubscription.getAttribMin(attrID)
                            + " .. " + PSSubscription.getAttribMax(attrID),
                            "Range Error",
                            JOptionPane.ERROR_MESSAGE);
                    
                    return false;
                }
                
                Constraint constraint = new Constraint(attrID, 
                        opIDs[cee.getOpCB().getSelectedIndex()], value);
                subscription.addConstraint(constraint);
            }
            
            if (obj instanceof AvpairEditElement) {
                AvpairEditElement aee = (AvpairEditElement)obj;
                int attrID = avIDs[aee.getAttrCB().getSelectedIndex()];
                long value = -1;
                
                try {
                    value = Long.parseLong(aee.getValTF().getText());
                } catch (NumberFormatException e) {                    
                    JOptionPane.showMessageDialog(null, 
                            "The value of " + PSSubscription.getAttribName(attrID) + " is not numeric",
                            "Number Format Error",
                            JOptionPane.ERROR_MESSAGE);
                    
                    return false;                    
                }
                
                if (value < PSSubscription.getAttribMin(attrID) || value > PSSubscription.getAttribMax(attrID)) {
                    JOptionPane.showMessageDialog(null, 
                            "The value of " + PSSubscription.getAttribName(attrID) 
                            + " is not in the allowed range " + PSSubscription.getAttribMin(attrID)
                            + " .. " + PSSubscription.getAttribMax(attrID),
                            "Range Error",
                            JOptionPane.ERROR_MESSAGE);
                    
                    return false;
                }
                
                Avpair avpair = new Avpair(attrID, 
                        value);
                subscription.addAvpair(avpair);
            }
        }
        return true;
    }    
    
    private void checkCB(Object eventObj, String actionCommand) {
        Integer editElementID = new Integer(actionCommand);
        Object obj = editElements.get(editElementID);
        
        if (obj == null)
            return;
        
        if (obj instanceof ConstraintEditElement) {
            ConstraintEditElement cee = (ConstraintEditElement)obj;
            JComboBox attrCB = cee.getAttrCB();
            JComboBox opCB = cee.getOpCB();
                        
            if (attrCB != eventObj)
                return;
                       
            setOperatorCB(opCB,attrCB.getSelectedIndex());
            opCB.setSelectedIndex(0);
            panel.updateUI();        
        }
        
        if (obj instanceof AvpairEditElement) {
            
        }
    }
    
    private void setOperatorCB(JComboBox opCB, int attrCBindex) {
            
        if (attrCBindex > -1) {            
            int attrID = constrIDs[attrCBindex];
            int [] opIds = PSSubscription.getOperationIDs(attrID);
             
            if (opIds != null) {            
                opCB.removeAllItems();
                for (int opIndex=0; opIndex < opIds.length; opIndex++) {                
                    opCB.addItem(PSSubscription.getOperationName(attrID, opIds[opIndex]));
                }
            }
        }
    }
    
    private int getIndexByAttrID(int attrID) {

        for (int index = 0; index < avIDs.length; index++ )
            if (avIDs[index] == attrID)
                return index;

        for (int index = 0; index < constrIDs.length; index++ )
            if (constrIDs[index] == attrID)
                return index;
        
        return -1;
        
    }
    
    private int getIndexByOpID(int opID, int attrID) {
        int [] opIDs = PSSubscription.getOperationIDs(attrID);

        for (int index = 0; index < opIDs.length; index++)
            if (opIDs[index] == opID)
                return index;
        
        System.err.println("getIndexByOpID: Not found! opID=" + opID + ", attrID=" + attrID);
        return -1;
    }
    
    class ConstraintEditElement {
        private JCheckBox selCheck;
        private JComboBox attrCB;
        private JComboBox opCB;
        private JTextField valTF;
        
        private ConstraintEditElement() {
            eeID++;
        }
        public ConstraintEditElement(ActionListener listener) {
            this();
            
            selCheck = new JCheckBox();
            selCheck.addActionListener(listener);
            
            attrCB = new JComboBox();
            attrCB.addActionListener(listener);
            attrCB.setActionCommand(String.valueOf(eeID));
            
            opCB = new JComboBox();
            opCB.addActionListener(listener);
            opCB.setActionCommand(String.valueOf(eeID));
            
            valTF = new JTextField();
            valTF.addActionListener(listener);
            valTF.setText("0");            
            
            for (int attrIndex=0; attrIndex < constrIDs.length; attrIndex++)
                attrCB.addItem(PSSubscription.getAttribName(constrIDs[attrIndex]));
                        
        }
        
        public ConstraintEditElement(JCheckBox selCheck, JComboBox attrCB, JComboBox opCB, JTextField valTF) {
            this();
            
            this.selCheck = selCheck;
            this.attrCB = attrCB;
            this.opCB = opCB;
            this.valTF = valTF;            
        }
        
        ConstraintEditElement(ActionListener listener, boolean selChecked, int attrCBindex, int opCBindex, String valTFtext) {
            this(listener);
            
            selCheck.setSelected(selChecked);
            attrCB.setSelectedIndex(attrCBindex);
            setOperatorCB(opCB,attrCBindex);
            opCB.setSelectedIndex(opCBindex);
            valTF.setText(valTFtext);
        }
        
        public ConstraintEditElement(ActionListener listener, Constraint constraint) {
            this(listener, false, 
                    getIndexByAttrID(constraint.getAttributeID()), 
                    getIndexByOpID(constraint.getOperationID(),constraint.getAttributeID()), 
                    Long.toString(constraint.getValue()));
        }
        
        public JCheckBox getSelCheck() {
            return selCheck;
        }
        
        public JComboBox getAttrCB() {
            return attrCB;
        }
        
        public JComboBox getOpCB() {
            return opCB;
        }
        
        public JTextField getValTF() {
            return valTF;
        }
        
        public Integer getID() {
            return new Integer(eeID);
        }        
    }
    
    class AvpairEditElement {
        private JCheckBox selCheck;
        private JComboBox attrCB;
        private JTextField valTF;

        private AvpairEditElement() {
            eeID++;
        }
        
        public AvpairEditElement(ActionListener listener) {
            this();
            selCheck = new JCheckBox();
            selCheck.addActionListener(listener);

            attrCB = new JComboBox();
            attrCB.addActionListener(listener);
            attrCB.setActionCommand(String.valueOf(eeID));
            
            valTF = new JTextField();
            valTF.addActionListener(listener);
            valTF.setText("0");
                        
            for (int attrIndex=0; attrIndex< avIDs.length; attrIndex++)
                attrCB.addItem(PSSubscription.getAttribName(avIDs[attrIndex]));            
        }
        
        public AvpairEditElement(JCheckBox selCheck, JComboBox attrCB, JTextField valTF) {
            this();
            this.selCheck = selCheck;
            this.attrCB = attrCB;
            this.valTF = valTF;
        }
        
        public AvpairEditElement(ActionListener listener, boolean selChecked, int attrCBindex, String valTFtext) {
            this(listener);

            selCheck.setSelected(selChecked);
            attrCB.setSelectedIndex(attrCBindex);
            valTF.setText(valTFtext);        
        }
        
        public AvpairEditElement(ActionListener listener, Avpair avpair) {
            this(listener, false, getIndexByAttrID(avpair.getAttributeID()), Long.toString(avpair.getValue()));
        }
        
        public JCheckBox getSelCheck() {
            return selCheck;
        }
        
        public JComboBox getAttrCB() {
            return attrCB;
        }
                
        public JTextField getValTF() {
            return valTF;
        }
        
        public Integer getID() {
            return new Integer(eeID);
        }
    }
}
