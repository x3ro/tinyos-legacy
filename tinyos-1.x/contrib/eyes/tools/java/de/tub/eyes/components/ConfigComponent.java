/*
 * ConfigComponent.java
 *
 * Created on 2. Mai 2005, 13:29
 */

package de.tub.eyes.components;

import java.util.*;
import java.util.regex.*;

import java.awt.Component;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;

import javax.swing.*;
import javax.swing.event.*;
import javax.swing.border.CompoundBorder;
import javax.swing.border.EmptyBorder;

import com.jgoodies.forms.builder.DefaultFormBuilder;
import com.jgoodies.forms.layout.CellConstraints;
import com.jgoodies.forms.layout.FormLayout;

import org.nfunk.jep.*;

import de.tub.eyes.apps.demonstrator.*;
import de.tub.eyes.gui.customelements.CaptionBorder;
import de.tub.eyes.apps.PS.PSSubscription;
import de.tub.eyes.gui.customelements.EGraphPanel;

/**
 *
 * @author Till Wimmer
 */
public class ConfigComponent extends AbstractComponent
        implements ActionListener, SnapshotHandler {
    
        
    private static PSSubscription subscr = new PSSubscription();
    public static int numConstraints = subscr.getConstraintIDs().length;
    public static int [] constrIDs = subscr.getConstraintIDs();

    public static final int TYPE_NONE = 0;    
    public static final int TYPE_TXT = 1;
    public static final int TYPE_NUM = 2;
    public static final int TYPE_BAR = 3;    
    public static final int TYPE_BG = 4;    
    public static final int TYPE_DOT = 5;
    public static final String [] types = new String[6];
    { 
        types[TYPE_NONE] = "none";
        types[TYPE_TXT] = "txt";
        types[TYPE_NUM] = "number";
        types[TYPE_BAR] = "bar";
        types[TYPE_BG] = "background";
        types[TYPE_DOT] = "dot";
        
     }
                    
    private JCheckBox [] enableCheck;
    private JCheckBox [] oscopeCheck;
    private JComboBox [] typeCombo;
    private JTextField [] minField;
    private JTextField [] maxField;
    private JTextField [] conversionField;    
    private JButton applyButton, loadButton, saveButton, snapshotSaveButton, snapshotRestoreButton;
    private ButtonGroup checkboxGroup;
    private static Map configMap = new TreeMap();
    private static int bgAttribute = -1;
    private static int oscopeAttribute = -1;    
    
    private JPanel panel=null;
    private JToggleButton tButton;
    private DefaultFormBuilder builder;
    private FormLayout layout;    
    
    /** Creates a new instance of ConfigComponent */
    public ConfigComponent() {
        if (panel == null)
            buildUI();
            
        //setDefault();
        Snapshot.addSnapshotHandler(this);
    }
 
    /**
     * Returns the UI for this Component. In this case it is a JPanel
     * @see de.tub.eyes.components.AbstractComponent#getUI()
     */
    public Component getUI() {
        CompoundBorder b = new CompoundBorder(new CaptionBorder(
                "Configuration Panel"), new EmptyBorder(10, 10, 10, 10));
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
    
    /**
     * Reacts on the Buttons and the Combo
     * @see java.awt.event.ActionListener#actionPerformed(java.awt.event.ActionEvent)
     */
    public void actionPerformed(ActionEvent e) {
        if (e.getSource() == loadButton) {
            loadConfig();
        }
        
        if (e.getSource() == saveButton) {
            saveConfig();
        }
        
        if (e.getSource() == applyButton ) {
            apply();
        }
        
        if (e.getSource() == snapshotSaveButton) {
            Snapshot.fireSnapshot(Snapshot.SNAPSHOT_NORMAL);            
        }

        if (e.getSource() == snapshotRestoreButton) {
            Snapshot.fireRestore();
        }        
    }    
    
    /**
     * Creates the UI
     *
     */
    private void buildUI() {
        initComponents();
        
        tButton = new JToggleButton("<html>Config<br>Panel");
        tButton.setHorizontalAlignment(JButton.LEFT);        
        tButton.setActionCommand("configpanel");
        panel = new JPanel();
        String layoutFormatColumns = "6dlu,p,12dlu,p,6dlu,p, 6dlu,p,6dlu,p,6dlu,p,6dlu,p";
        String layoutFormatRows =  "3dlu,p,3dlu,p,3dlu,p";
        for (int row = 0; row < numConstraints; row++)
            layoutFormatRows += ",6dlu,p";

        layoutFormatRows += ",12dlu,p,15dlu,p,12dlu,p";
        //System.out.println(layoutFormatRows);
        
        layout = new FormLayout(layoutFormatColumns, layoutFormatRows);
        layout.setColumnGroups(new int[][]{ {2, 4, 6} });        
        
        builder = new DefaultFormBuilder(panel, layout);
        
        // Obtain a reusable constraints object to place components in the grid.
        CellConstraints cc = new CellConstraints();
        int line = 2;
        builder.addSeparator("ATTRIBUTE VIEWS", cc.xyw(1, line, 14));        
        builder.addLabel("Display", cc.xy(2,line+=2));
        builder.addLabel("Oscope", cc.xy(4,line));        
        builder.addLabel("Attribute", cc.xy(6,line));
        builder.addLabel("Display Type", cc.xy(8,line));
        builder.addLabel("Min", cc.xy(10,line));
        builder.addLabel("Max", cc.xy(12,line));
        builder.addLabel("Conversion", cc.xy(14,line));        
        builder.addSeparator("", cc.xyw(1, line+=2, 14));
 
        for (int attrIndex=0; attrIndex < numConstraints; attrIndex++) {                       
            builder.add(enableCheck[attrIndex], cc.xy(2,line+=2));
            builder.add(oscopeCheck[attrIndex], cc.xy(4,line));            
            builder.addLabel(PSSubscription.getAttribName(constrIDs[attrIndex]), cc.xy(6,line));
            builder.add(typeCombo[attrIndex], cc.xy(8,line));
            builder.add(minField[attrIndex], cc.xy(10,line));
            builder.add(maxField[attrIndex], cc.xy(12,line));  
            builder.add(conversionField[attrIndex], cc.xy(14,line));                        
        }             

        builder.add(loadButton, cc.xy(2, line+=2));
        builder.add(saveButton, cc.xy(4, line));
        builder.add(applyButton, cc.xy(6, line));
        builder.addSeparator("SNAPSHOT", cc.xyw(1, line+=2, 14));
        builder.add(snapshotSaveButton, cc.xy(2, line+=2));
        builder.add(snapshotRestoreButton, cc.xy(4, line));
    }
    
    /**
     * Creates, intializes and configures the UI components. 
     * Real applications may further bind the components to underlying models. 
     */
    private void initComponents() {               
        enableCheck = new JCheckBox[numConstraints];
        checkboxGroup = new ButtonGroup();
        oscopeCheck = new JCheckBox[numConstraints];
        minField = new JTextField[numConstraints];        
        typeCombo = new JComboBox[numConstraints];
        maxField = new JTextField[numConstraints];
        conversionField = new JTextField[numConstraints];
        
        for (int attrIndex=0; attrIndex < numConstraints; attrIndex++) {
            int id = constrIDs[attrIndex];
            enableCheck[attrIndex] = new JCheckBox();
            oscopeCheck[attrIndex] = new JCheckBox();
            checkboxGroup.add(oscopeCheck[attrIndex]);
            typeCombo[attrIndex] = new JComboBox();
            for (int typeIndex=0; typeIndex < types.length; typeIndex++) {
                typeCombo[attrIndex].addItem(types[typeIndex]);
                if (PSSubscription.getPreferrredVisualization(id).equals(types[typeIndex]))
                    typeCombo[attrIndex].setSelectedIndex(typeIndex);
            }
            minField[attrIndex] = new JTextField(8);
            minField[attrIndex].setText(String.valueOf(PSSubscription.getAttribMin(id)));
            maxField[attrIndex] = new JTextField(8);
            maxField[attrIndex].setText(String.valueOf(PSSubscription.getAttribMax(id)));
            conversionField[attrIndex] = new JTextField(8);
            conversionField[attrIndex].setText(PSSubscription.getMetricConversion(id));
            
        }
          
        loadButton = new JButton("load");
        loadButton.addActionListener(this);
        saveButton = new JButton("save");
        saveButton.addActionListener(this);
        applyButton = new JButton("Apply");
        applyButton.addActionListener(this);
        snapshotSaveButton = new JButton("Save");
        snapshotSaveButton.addActionListener(this);
        snapshotRestoreButton = new JButton("Restore");
        snapshotRestoreButton.addActionListener(this);
 
    }
    
    void saveConfig () {                        
        JFileChooser fChooser = new JFileChooser();
	File cfgFile;        
	FileWriter dataOut = null;

        if (fChooser.showOpenDialog(null) == JFileChooser.APPROVE_OPTION) {            		
            cfgFile = fChooser.getSelectedFile();
            try {
                dataOut = new FileWriter( cfgFile );
            }
            catch (IOException e) {
                System.err.println("Open " + cfgFile + ": " + e.getMessage());
                return;
            }
            
            try {
                for (int attrIndex = 0; attrIndex < numConstraints; attrIndex++) {            
                    dataOut.write(attrIndex + "\t" 
                            + enableCheck[attrIndex].isSelected() 
                            + "\t" + oscopeCheck[attrIndex].isSelected() 
                            + "\t" + typeCombo[attrIndex].getSelectedIndex()
                            + "\t" + minField[attrIndex].getText() 
                            + "\t" + maxField[attrIndex].getText() 
                            + "\t" + conversionField[attrIndex].getText() + "\n");
                }
            }
            catch (IOException e) {
                System.err.println("Write:" + e.getMessage());
            }
            try {
                dataOut.close();
            }
            catch (IOException e) {
                System.err.println("Close " + cfgFile.getName() + ": " + e.getMessage());
            }
        }
        
    }
    
    void loadConfig () {
        JFileChooser fChooser = new JFileChooser();
	File cfgFile;
        
        if (fChooser.showOpenDialog(null) == JFileChooser.APPROVE_OPTION) {
            cfgFile = fChooser.getSelectedFile();
            try {
                FileReader dataIn = new FileReader(cfgFile);
                BufferedReader in = new BufferedReader(dataIn);
                String line;
                while ((line = in.readLine()) != null) {

                    String [] data  = Pattern.compile("\t").split(line);
                    if (data.length < 6) {
                        System.err.println ("loadConfig(): Parse error");
                        continue;
                    }
                    int attrIndex = Integer.parseInt(data[0]);
                    
                    if (attrIndex >= numConstraints) {
                        continue;
                    }
                    
                    if (data[1].equals("true"))
                        enableCheck[attrIndex].setSelected(true);
                    else
                        enableCheck[attrIndex].setSelected(false);

                    if (data[2].equals("true"))
                        oscopeCheck[attrIndex].setSelected(true);
                    else
                        oscopeCheck[attrIndex].setSelected(false);
                    
                    typeCombo[attrIndex].setSelectedIndex(Integer.parseInt(data[3]));
                    minField[attrIndex].setText(data[4]);
                    maxField[attrIndex].setText(data[5]);
                    
                    if (data.length == 7)
                        conversionField[attrIndex].setText(data[6]);
                    else
                        conversionField[attrIndex].setText("");
                }
                dataIn.close();
            }
            catch (FileNotFoundException e) {
                System.err.println("Error loading file: " + e.getMessage());
            }
            catch (IOException e) {
                System.err.println(e.getMessage());
            }            
        }
        
    }
    
    public static int getType (int attrID) {
        Config config = (Config)configMap.get(new Integer(attrID));        
        if (config != null)
            return config.type;
        else
            return -1;
    }
    
    public static double getMin (int attrID) {
        Config config = (Config)configMap.get(new Integer(attrID));
        if (config != null)
            return config.min;
        else
            return -1;        
    }
    
    public static double getMax (int attrID) {
        Config config = (Config)configMap.get(new Integer(attrID));
        if (config != null)
            return config.max;
        else
            return -1;
    }
    
    public static boolean isEnabled (int attrID) {
        Config config = (Config)configMap.get(new Integer(attrID));              
        if (config != null)
            return config.display;
        else
            return false;
    }
    
    public static boolean isDefined (int attrID) {
        Config config = (Config)configMap.get(new Integer(attrID));      
        if (config != null)
            return true;
        else
            return false;     
    }
    
    public static JEP getJepObject (int attrID) {
        Config config = (Config)configMap.get(new Integer(attrID));      
        if (config != null)
            return config.jepObject;
        else
            return null;     
    }    
    
    public static int getBackgroundAttribute () {
        return bgAttribute;
    }
    
    public static int getOscopeAttribute () {
        return oscopeAttribute;
    }
    
    public static void dump() {
        for (Iterator it = configMap.keySet().iterator(); it.hasNext();) {
            Integer key = (Integer)it.next();
            Config conf = (Config)configMap.get(key);
            System.out.println("key = " + key + "; type = " + conf.type + "; display = " + conf.display
                    + "; min = " + conf.min + "; max = " + conf.max);
        }
        
    }
    
    void apply () {
        int bgCount = 0;
        int dotCount = 0;
        for (int attrIndex = 0; attrIndex < numConstraints; attrIndex++) {
            int attrID = constrIDs[attrIndex];
            
            if (oscopeCheck[attrIndex].isSelected())
                oscopeAttribute = attrID;
            
            Config conf = new Config();
            conf.display = enableCheck[attrIndex].isSelected();
            conf.type = typeCombo[attrIndex].getSelectedIndex();
            conf.conversion = conversionField[attrIndex].getText();
            
            if (conf.display && conf.type == TYPE_BG) {
                bgCount++;
                if (bgCount > 1) {
                    JOptionPane.showMessageDialog(null, 
                            "You have selected more than ONE background attribute!",
                            "Warning",
                            JOptionPane.WARNING_MESSAGE);
                    return;                    
                }
                bgAttribute = attrID;
            }

            if (conf.display && conf.type == TYPE_DOT) {
                dotCount++;
                if (dotCount > 1) {
                    JOptionPane.showMessageDialog(null, 
                            "You have selected more than ONE dot attribute!",
                            "Warning",
                            JOptionPane.WARNING_MESSAGE);
                    return;                    
                }
            }
            
            if (conf.conversion.length() > 0) {
                JEP jep = new JEP();
                jep.addStandardFunctions();
                jep.addStandardConstants();
                jep.setImplicitMul(true);
                jep.addVariable("x", 0);
                jep.parseExpression(conf.conversion.toLowerCase());
            
                if (jep.hasError()) {
                    JOptionPane.showMessageDialog(null, 
                            "There's an error in the metric conversion: " + jep.getErrorInfo(),
                            "Error " + PSSubscription.getAttribName(attrID),
                            JOptionPane.WARNING_MESSAGE);
                    return;                
                }
                conf.jepObject = jep;
            }
            else
                conf.jepObject = null;
            
            try {
                if (conf.jepObject != null) {
                
                    conf.jepObject.addVariable("x", Double.parseDouble(minField[attrIndex].getText()));
                    conf.min = conf.jepObject.getValue();                
                
                    conf.jepObject.addVariable("x", Double.parseDouble(maxField[attrIndex].getText()));
                    conf.max = conf.jepObject.getValue();
                }
                else {
                    conf.min = Double.parseDouble(minField[attrIndex].getText());
                    conf.max = Double.parseDouble(maxField[attrIndex].getText());
                }
            }
            catch (Exception e) {
                System.err.println("Ungueltiger Wert (min, max): " + e.getMessage());
                continue;
            }
            configMap.put(new Integer(attrID), conf);
        }
        EGraphPanel.reset();
    }
    
    void setDefault () {
                
        for (int attrIndex = 0; attrIndex < numConstraints; attrIndex++) { 
            
            for (int typeIndex=0; typeIndex < types.length; typeIndex++) {
                int attrID = constrIDs[attrIndex];
                //System.out.println("Pref Viz = " + PSSubscription.getPreferrredVisualization(attrID));
                if ( types[typeIndex].equals(PSSubscription.getPreferrredVisualization(attrID)) ) {
                            
                    configMap.put(new Integer(attrID), new Config(true,typeIndex,0,4096, "", null) );
                    typeCombo[attrIndex].setSelectedIndex(typeIndex);
                    enableCheck[attrIndex].setSelected(true);
                }
            }
        }


        //oscopeCheck[LIGHT].setSelected(true);
    }
    
    class Config {
        Config () { }
        
        Config (boolean display, int type, double min, double max, String conversion, JEP jepObject) {
            this.display = display;
            this.type = type;
            this.min = min;
            this.max = max;
            this.conversion = conversion;
            this.jepObject = jepObject;
        }
        
        boolean display;
        int type;
        double min;
        double max;
        String conversion;
        JEP jepObject;
    }
    
    public TreeMap getSnapshot() {
        TreeMap data = new TreeMap();
        data.put("arraySize", new Integer(numConstraints));
        boolean [] enableSet = new boolean[numConstraints];
        boolean [] oscopeSet = new boolean[numConstraints];
        int [] typeIndex = new int[numConstraints];
        String [] minValue = new String[numConstraints];
        String [] maxValue = new String[numConstraints];
        String [] conversionValue = new String[numConstraints];
        
        for (int attrIndex = 0; attrIndex < numConstraints; attrIndex++) {
            enableSet[attrIndex] = enableCheck[attrIndex].isSelected();
            oscopeSet[attrIndex] = oscopeCheck[attrIndex].isSelected();
            typeIndex[attrIndex] = typeCombo[attrIndex].getSelectedIndex();
            minValue[attrIndex] = minField[attrIndex].getText();
            maxValue[attrIndex] = maxField[attrIndex].getText();
            conversionValue[attrIndex] = conversionField[attrIndex].getText();            
        }
                
        data.put("enableSet", enableSet);
        data.put("oscopeSet", oscopeSet);
        data.put("typeIndex", typeIndex);
        data.put("minValue", minValue);
        data.put("maxValue", maxValue);
        data.put("conversionValue", conversionValue);
        
        return data;
    }
    
    public void restoreSnapshot(TreeMap data) {
        //System.out.println("called restoreSnapshot");
        int arraySize = -1;
        Object obj = null;
        
        if ( (obj=data.get("arraySize")) != null && (obj instanceof Integer) )
            arraySize = ((Integer)obj).intValue();
        else
            return;
        
        boolean [] enableSet = new boolean[arraySize];
        boolean [] oscopeSet = new boolean[arraySize];
        int [] typeIndex = new int[arraySize];
        String [] minValue = new String[arraySize];
        String [] maxValue = new String[arraySize];
        String [] conversionValue = new String[arraySize];        

        if ( (obj=data.get("enableSet")) != null && (obj instanceof boolean[]) )
            enableSet = (boolean[])obj;
        else
            return;
        
        if ( (obj=data.get("oscopeSet")) != null && (obj instanceof boolean[]) )
            oscopeSet = (boolean[])obj;
        else
            return;
        
        if ( (obj=data.get("typeIndex")) != null && (obj instanceof int[]) )
            typeIndex = (int[])obj;
        else
            return;
        
        if ( (obj=data.get("minValue")) != null && (obj instanceof String[]) )
            minValue = (String[])obj;
        else
            return;
        
        if ( (obj=data.get("maxValue")) != null && (obj instanceof String[]) )
            maxValue = (String[])obj; 
        else
            return;
        
        if ( (obj=data.get("conversionValue")) != null && (obj instanceof String[]) )
            conversionValue = (String[])obj;
        else
            return;

        for (int attrIndex = 0; attrIndex < numConstraints; attrIndex++) {

            enableCheck[attrIndex].setSelected(enableSet[attrIndex]);
            oscopeCheck[attrIndex].setSelected(oscopeSet[attrIndex]);
            typeCombo[attrIndex].setSelectedIndex(typeIndex[attrIndex]);
            minField[attrIndex].setText(minValue[attrIndex]);
            maxField[attrIndex].setText(maxValue[attrIndex]);
            conversionField[attrIndex].setText(conversionValue[attrIndex]);
        }
        
        panel.updateUI();
        apply();
    }
}
