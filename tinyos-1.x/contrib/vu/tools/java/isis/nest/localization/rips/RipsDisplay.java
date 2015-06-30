/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy,	modify,	and	distribute this	software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided	that the above copyright notice, the following
 * two paragraphs and the author appear	in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT	UNIVERSITY BE LIABLE TO	ANY	PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS	ANY	WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF	MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR	PURPOSE.  THE SOFTWARE PROVIDED	HEREUNDER IS
 * ON AN "AS IS" BASIS,	AND	THE	VANDERBILT UNIVERSITY HAS NO OBLIGATION	TO
 * PROVIDE MAINTENANCE,	SUPPORT, UPDATES, ENHANCEMENTS,	OR MODIFICATIONS.
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @modified 04/11/05
 */


package isis.nest.localization.rips;

import java.awt.Color;
import java.awt.Component;
import java.awt.GridLayout;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;
import java.awt.event.MouseEvent;
import java.io.File;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.Arrays;
import java.util.prefs.Preferences;

import javax.swing.JCheckBox;
import javax.swing.JPanel;
import javax.swing.JTextField;

import net.tinyos.mcenter.MessageCenterInternalFrame;
import net.tinyos.mcenter.RemoteControl;
import net.tinyos.mcenter.SerialConnector;
import net.tinyos.packet.PacketListenerIF;

public class RipsDisplay extends MessageCenterInternalFrame implements PacketListenerIF, MeasurementEndedCallback{

	private class ChannelListener implements java.awt.event.ActionListener {
        int idx;
        public ChannelListener(int i){ idx = i;}
		public void actionPerformed(java.awt.event.ActionEvent evt) {
            chTextFieldActionPerformed(evt, idx);
        }
	}
	    
    private class MyColorRenderer extends javax.swing.JLabel implements javax.swing.table.TableCellRenderer{

        public Component  getTableCellRendererComponent(javax.swing.JTable aTable, 
                Object aNumberValue, 
                boolean aIsSelected, 
                boolean aHasFocus, 
                int aRow, int aColumn) {
        	if (aNumberValue == null)
        		setText("null");
        	else{
        		setText(aNumberValue.toString());

	        	if (showColors){
		        	LocalizationData.SlaveEntry sE = tableModel.getSlaveEntryByRow(aRow); 
		        	if (sE!=null && sE.valid){
		        		setForeground(Color.green.darker());
		        		return this;
		        	}
	        	}
        	}
        	setForeground(Color.lightGray.darker());
			return this;
		}
    }
    private class MyBackgroundRenderer extends javax.swing.JLabel implements javax.swing.table.TableCellRenderer{

        public Component  getTableCellRendererComponent(javax.swing.JTable aTable, 
                Object aNumberValue, 
                boolean aIsSelected, 
                boolean aHasFocus, 
                int aRow, int aColumn) {
        	if (aNumberValue == null)
        		setText("null");
        	else{
            	setText(aNumberValue.toString());
        	
            	if (showColors){
    	        	LocalizationData.SlaveEntry sE = tableModel.getSlaveEntryByRow(aRow);
    	        	if (sE!=null){
    	            	LocalizationData.ChannelEntry chE = sE.channels[aColumn-5];
    	            	if (chE!=null && chE.valid){
    	            		setOpaque(true);
    	            		setBackground(Color.cyan.brighter());
    	            		setForeground(Color.darkGray.brighter());
    	            		return this;
    	            	}
    	        	}
            	}
            }
        	
    		setBackground(Color.WHITE);
    		setForeground(Color.lightGray.darker());
			return this;
		}
    }
	
    static final int PACKET_TYPE = 2;    
    static final int PACKET_LENGTH_BYTE = 4;
	static final int PACKET_DATA = 5;
	static final int PACKET_ROUTING_TYPE = 5;
    static final byte RIPS_APP_ID = (byte)0x11;
    static final int MAX_SEQ_NUM = 127;
    static final String BASE_DIRECTORY = "c:\\tmp\\rips\\data";
	protected int ACTIVE_MESSAGE = 130;
    
    private RipsDisplay instance = null;
    
	private Preferences prefs = null;
    
    private LocalizationData localizationData = null;
    private MeasurementThread measurementThread = null;
	private MoteQueryLogic moteQueryLogic = null;
	private RipsDataTableModel tableModel = null;
	private ABCDTableModel abcdTableModel = null;
	private MotesTableModel motesTableModel = null;
    private MoteParams moteParams = null;
    
    private boolean showColors = false;
    //private int LocalizationData.minimumFreqScore = 3; 
    //private int maxFreqError = 3;
    //private int minimumChanScore = 11;
    //TODO make these settable from GUI
    
    protected String currentFileName = new String("std.out");
           
    public static final int VERSION = 060315;
    /** Creates new form RipsDisplay */
    public RipsDisplay() {
        super("Rips Routing Message Display");
        instance = this;
        localizationData = new LocalizationData();
    	tableModel = new RipsDataTableModel(localizationData);
    	abcdTableModel = new ABCDTableModel(localizationData);
    	motesTableModel = new MotesTableModel(localizationData);
    	measurementThread = new MeasurementThread();
    	moteQueryLogic = new MoteQueryLogic(motesTableModel);
		
        measurementThread.setSequenceNumber( 0 );

        prefs = Preferences.userNodeForPackage(this.getClass());
    	prefs = prefs.node(prefs.absolutePath() + "/RipsDisplay");

    	measurementThread.setMeasurementSleepTime(prefs.getInt("measurementSleepTime",measurementThread.getMeasurementSleepTime()));
    	for (int i=0; i<RipsDataTableModel.NUM_CHANNELS; i++)
    		if (i<localizationData.channels.length)
    			localizationData.channels[i] = prefs.getInt("ch"+i,localizationData.channels[i]);

    	moteParams = MoteParams.getInstance();
    	
    	if (prefs.getInt("moteParams.version",0) != VERSION){
    	    //if old version, keep the default params no matter what prefs contain
    	    prefs.putInt("moteParams.version",VERSION);
        	prefs.putInt("moteParams.masterPower",moteParams.masterPower);
        	prefs.putInt("moteParams.assistPower",moteParams.assistPower);
            prefs.putInt("moteParams.algorithmType",moteParams.algorithmType);
            prefs.putInt("moteParams.interferenceFreq",moteParams.interferenceFreq);
            prefs.putInt("moteParams.tsNumHops",moteParams.tsNumHops);
            prefs.putInt("moteParams.tsNumHops",moteParams.tsNumHops);
            prefs.putInt("moteParams.channelA",moteParams.channelA);
            prefs.putInt("moteParams.initialTuning",moteParams.initialTuning); 
            prefs.putInt("moteParams.tuningOffset",moteParams.tuningOffset); 
            prefs.putInt("moteParams.numTuneHops",moteParams.numTuneHops);
            prefs.putInt("moteParams.numChanHops",moteParams.numChanHops);
    	}
    	else{
        	moteParams.masterPower = prefs.getInt("moteParams.masterPower",moteParams.masterPower);
        	moteParams.assistPower = prefs.getInt("moteParams.assistPower",moteParams.assistPower);
            moteParams.algorithmType = prefs.getInt("moteParams.algorithmType",moteParams.algorithmType);
            moteParams.interferenceFreq = prefs.getInt("moteParams.interferenceFreq",moteParams.interferenceFreq);
            moteParams.tsNumHops = prefs.getInt("moteParams.tsNumHops",moteParams.tsNumHops);
            moteParams.tsNumHops = prefs.getInt("moteParams.tsNumHops",moteParams.tsNumHops);
            moteParams.channelA = prefs.getInt("moteParams.channelA",moteParams.channelA);
            moteParams.initialTuning = prefs.getInt("moteParams.initialTuning",moteParams.initialTuning); 
            moteParams.tuningOffset = prefs.getInt("moteParams.tuningOffset",moteParams.tuningOffset); 
            moteParams.numTuneHops = prefs.getInt("moteParams.numTuneHops",moteParams.numTuneHops);
            moteParams.numChanHops = prefs.getInt("moteParams.numChanHops",moteParams.numChanHops);
        }
		
        initComponents();
        setTables();
    	setFileStructure();
        SerialConnector.instance().registerPacketListener(this,ACTIVE_MESSAGE);
        this.addInternalFrameListener(new javax.swing.event.InternalFrameAdapter(){
            public void internalFrameClosing(javax.swing.event.InternalFrameEvent e){
                SerialConnector.instance().removePacketListener(instance,ACTIVE_MESSAGE);
            	if (measurementThread != null ){
            		measurementThread.finish();
            		measurementThread.interrupt();
            	}           		
            }
        });
		System.out.print("isis-contrib:\t");
    }
       
	private void setFileStructure(){
	    java.text.SimpleDateFormat dateFormat = new java.text.SimpleDateFormat("yy-DDD-HH-mm-ss");

		try{
	    	//setting up file structure
	    	File tmpFile = new java.io.File(BASE_DIRECTORY);
	    	if (! tmpFile.exists())
	    		tmpFile.mkdirs();

	    	currentFileName = tmpFile.getAbsolutePath()+"\\"+dateFormat.format(new java.util.Date());
	    	System.out.println("New name base: "+currentFileName+".*");
	    	fileName.setText(currentFileName);
    	}
    	catch(Exception e){
    		System.out.println("problem with setting up c:\\tmp\\rips path structure!");
    	}
	}
	
	private void initComponents() {
    	java.awt.GridBagConstraints gridBagConstraints;

        tabbedPanel = new javax.swing.JPanel();
        tabbedPane = new javax.swing.JTabbedPane();
        tabbedPanel.setLayout(new java.awt.BorderLayout());
        tabbedPanel.setMinimumSize(new java.awt.Dimension(500, 260));
        tabbedPanel.setPreferredSize(new java.awt.Dimension(800, 500));

//RIPS DATA PANEL
        dataPanel = new javax.swing.JPanel();

        dataSubPanel = new javax.swing.JPanel();
        checkBoxPanel = new javax.swing.JPanel();
        dataChooserComboBox = new javax.swing.JComboBox();
        dataChooserComboBox.setMinimumSize(new java.awt.Dimension(100,20));
        collapseMotesCheckBox = new javax.swing.JCheckBox();
        collapseMotesCheckBox.setMinimumSize(new java.awt.Dimension(100,20));
        colorsCheckBox = new javax.swing.JCheckBox();
        colorsCheckBox.setMinimumSize(new java.awt.Dimension(100,20));
        resetButton = new javax.swing.JButton();
        fileName = new javax.swing.JTextField();
        loadFileButton = new javax.swing.JButton();
        saveFileButton = new javax.swing.JButton();

        rowCount = new javax.swing.JTextField();
        dataScrollPanel = new javax.swing.JScrollPane();

        dataSubPanel2 = new javax.swing.JPanel();
        table = new javax.swing.JTable();

//      ABCD DATA PANEL
        abcdPanel = new javax.swing.JPanel();

        abcdSubPanel = new javax.swing.JPanel();
        filterCheckBox = new javax.swing.JCheckBox();
        abcdResetButton = new javax.swing.JButton();
        abcdRowCount = new javax.swing.JTextField();
        locRoundCount = new JTextField();
        abcdScrollPanel = new javax.swing.JScrollPane();

        abcdSubPanel2 = new javax.swing.JPanel();
        abcdTable = new javax.swing.JTable();

//		MOTES panel        
        motesScrollPane = new javax.swing.JScrollPane();
        motePanel = new javax.swing.JPanel();
        motesTable = new javax.swing.JTable();
        
//      LOCALIZATION panel
        localizationPanel = new GALocDisplay2(localizationData);     

//		SEND PANEL
        sendPanel = new javax.swing.JPanel();
        commandPanel = new javax.swing.JPanel();
        resetRCCommandButton = new javax.swing.JButton();
        resetChanCommandButton = new javax.swing.JButton();
        startCommandButton = new javax.swing.JButton();
        stopCommandButton = new javax.swing.JButton();
        sendChannelCommandButton = new javax.swing.JButton();
        sendMoteParamsCommandButton = new javax.swing.JButton();

//		PARAMETERS PANEL        
        parametersPanel = new javax.swing.JPanel();
        parametersSubPanelProgram = new javax.swing.JPanel();
        measurementWaitLabel = new javax.swing.JLabel();
        measurementWaitTextField = new javax.swing.JTextField();
        
        parametersSubPanelChannels = new javax.swing.JPanel();
        chLabel = new javax.swing.JLabel();
        chTextFields = new javax.swing.JTextField[RipsDataTableModel.NUM_CHANNELS];

        parametersSubPanelMote = new javax.swing.JPanel();
        powerMasterLabel = new javax.swing.JLabel();
        powerAssistLabel = new javax.swing.JLabel();
        algorithmTypeLabel = new javax.swing.JLabel();
        interferenceFreqLabel = new javax.swing.JLabel();
        tsNumHopsLabel = new javax.swing.JLabel();
        channelALabel = new javax.swing.JLabel();
        initialTuningLabel = new javax.swing.JLabel();
        tuningOffsetLabel = new javax.swing.JLabel();
        numTuneHopsLabel = new javax.swing.JLabel();
        numChanHopsLabel = new javax.swing.JLabel();
        initialChannelLabel = new javax.swing.JLabel();
        channelOffsetLabel = new javax.swing.JLabel();
        
        powerMasterTextField = new javax.swing.JTextField();
        powerAssistTextField = new javax.swing.JTextField();
        algorithmTypeComboBox = new javax.swing.JComboBox();
        interferenceFreqTextField = new javax.swing.JTextField();
        tsNumHopsTextField = new javax.swing.JTextField();
        channelATextField = new javax.swing.JTextField();
        initialTuningTextField = new javax.swing.JTextField();
        tuningOffsetTextField = new javax.swing.JTextField();
        numTuneHopsTextField = new javax.swing.JTextField();
        numChanHopsTextField = new javax.swing.JTextField();
        initialChannelTextField = new javax.swing.JTextField();
        channelOffsetTextField = new javax.swing.JTextField();

        setTitle("Rips Routing Message Display");
/* end */

        
//RIPS
        dataPanel.setLayout(new java.awt.GridBagLayout());

        dataSubPanel.setLayout(new java.awt.GridBagLayout());
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.anchor = java.awt.GridBagConstraints.WEST;
        gridBagConstraints.insets = new java.awt.Insets(0, 3, 0, 3);
        dataChooserComboBox.setMinimumSize(new java.awt.Dimension(70, 20));
        dataChooserComboBox.setPreferredSize(new java.awt.Dimension(100, 20));
        dataChooserComboBox.addItem("Phase");
        dataChooserComboBox.addItem("Frequency");
        dataChooserComboBox.setMaximumRowCount(2);
        dataChooserComboBox.setToolTipText("show frequencies or phase offsets for each channel");
        dataChooserComboBox.addActionListener(new java.awt.event.ActionListener() {
                public void actionPerformed(java.awt.event.ActionEvent evt) {
                        dataChooserComboBoxActionPerformed(evt);
                }});
        dataSubPanel.add(dataChooserComboBox, gridBagConstraints);

        checkBoxPanel.setLayout(new GridLayout(1,2));
        collapseMotesCheckBox.setMinimumSize(new java.awt.Dimension(60, 18));
        collapseMotesCheckBox.setPreferredSize(new java.awt.Dimension(70, 18));
        collapseMotesCheckBox.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 10));
        collapseMotesCheckBox.setText("MOTES");
        collapseMotesCheckBox.addItemListener(new java.awt.event.ItemListener() {
            public void itemStateChanged(java.awt.event.ItemEvent evt) {
                collapseMotesCheckBoxItemStateChanged(evt);
            }
        });
        checkBoxPanel.add(collapseMotesCheckBox, gridBagConstraints);
        colorsCheckBox.setMinimumSize(new java.awt.Dimension(60, 18));
        colorsCheckBox.setPreferredSize(new java.awt.Dimension(70, 18));
        colorsCheckBox.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 10));
        colorsCheckBox.setText("COLORS");
        colorsCheckBox.addItemListener(new java.awt.event.ItemListener() {
            public void itemStateChanged(java.awt.event.ItemEvent evt) {
                colorsCheckBoxItemStateChanged(evt);
            }
        });
        checkBoxPanel.add(colorsCheckBox);
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.insets = new java.awt.Insets(0, 0, 0, 0);
        dataSubPanel.add(checkBoxPanel, gridBagConstraints);
        

        javax.swing.JPanel tmpPanel = new javax.swing.JPanel();

        tmpPanel.setLayout(new java.awt.GridBagLayout());
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.insets = new java.awt.Insets(0, 2, 0, 2);
        javax.swing.JLabel tmpLabel = new javax.swing.JLabel("row count: ");
        tmpLabel.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 11));
        tmpLabel.setHorizontalAlignment( javax.swing.JLabel.RIGHT );
        tmpPanel.add(tmpLabel, gridBagConstraints);

        rowCount.setEditable(false);
        rowCount.setText("0");
        rowCount.setMinimumSize(new java.awt.Dimension(30, 14));
        rowCount.setPreferredSize(new java.awt.Dimension(88, 16));
        rowCount.setHorizontalAlignment( javax.swing.JLabel.RIGHT );
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.anchor = java.awt.GridBagConstraints.EAST;
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.insets = new java.awt.Insets(0, 2, 0, 0);
        tmpPanel.add(rowCount, gridBagConstraints);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.insets = new java.awt.Insets(0, 2, 0, 2);
        tmpLabel = new javax.swing.JLabel("saving to: ");
        tmpLabel.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 11));
        tmpLabel.setHorizontalAlignment( javax.swing.JLabel.RIGHT );
        tmpPanel.add(tmpLabel, gridBagConstraints);

        fileName.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 11));
        fileName.setEditable(false);
        fileName.setText("std.out");
        fileName.setMinimumSize(new java.awt.Dimension(30, 14));
        fileName.setPreferredSize(new java.awt.Dimension(88, 16));
        fileName.setHorizontalAlignment( javax.swing.JLabel.RIGHT );
//        fileName.setBorder(new javax.swing.border.EmptyBorder(new java.awt.Insets(1, 1, 1, 1)));
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.anchor = java.awt.GridBagConstraints.EAST;
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.insets = new java.awt.Insets(0, 2, 0, 0);
        tmpPanel.add(fileName, gridBagConstraints);
        
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        dataSubPanel.add(tmpPanel, gridBagConstraints);
        
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.anchor = java.awt.GridBagConstraints.NORTH;
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 0.0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        dataPanel.add(dataSubPanel, gridBagConstraints);

        dataSubPanel2.setLayout(new java.awt.GridBagLayout());
        dataSubPanel2.setBorder(new javax.swing.border.TitledBorder("Table"));

        dataScrollPanel.setBorder(new javax.swing.border.EmptyBorder(new java.awt.Insets(1, 1, 1, 1)));
        dataScrollPanel.setMinimumSize(new java.awt.Dimension(300, 103));
        dataScrollPanel.setPreferredSize(new java.awt.Dimension(300, 150));
        table.setAutoResizeMode(javax.swing.JTable.AUTO_RESIZE_OFF);
        table.setModel(tableModel);
        dataScrollPanel.setViewportView(table);
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        dataSubPanel2.add(dataScrollPanel, gridBagConstraints);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.SOUTH;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        dataPanel.add(dataSubPanel2, gridBagConstraints);
        
        tabbedPane.addTab("Rcvd data", dataPanel);
//ABCD
        abcdPanel.setLayout(new java.awt.GridBagLayout());

        abcdSubPanel.setLayout(new java.awt.GridBagLayout());

        filterCheckBox.setMinimumSize(new java.awt.Dimension(50, 18));
        filterCheckBox.setPreferredSize(new java.awt.Dimension(60, 18));
        filterCheckBox.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 8));
        filterCheckBox.setText("Filter");
        filterCheckBox.addItemListener(new java.awt.event.ItemListener() {
            public void itemStateChanged(java.awt.event.ItemEvent evt) {
                filterCheckBoxItemStateChanged(evt);
            }
        });
        abcdSubPanel.add(filterCheckBox);

        abcdResetButton.setPreferredSize(new java.awt.Dimension(105, 20));
        abcdResetButton.setMinimumSize(new java.awt.Dimension(75, 20));
        abcdResetButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 12));
        abcdResetButton.setText("Recalculate");
        abcdResetButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	abcdResetButtonActionPerformed(evt);
            }
        });                       
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.insets = new java.awt.Insets(0, 4, 0, 0);
        abcdSubPanel.add(abcdResetButton, gridBagConstraints);
        
        javax.swing.JButton analDistButton = new javax.swing.JButton();        
        analDistButton.setPreferredSize(new java.awt.Dimension(105, 20));
        analDistButton.setMinimumSize(new java.awt.Dimension(75, 20));
        analDistButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 12));
        analDistButton.setText("Analyze dist");
        analDistButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                int sel = abcdTable.getSelectedRow();
                
                if( sel >=0 )
                {
                    ABCDMeasurement m = (ABCDMeasurement)localizationData.abcd_measurements.get(sel);
                    
                    PrintStream log = null;
                    try
                    {
                        log = new PrintStream(new FileOutputStream(new File("C:/temp/ranging.txt")));
                    }
                    catch(Exception e)
                    {
                        e.printStackTrace();
                    }                    
                    m.computeDist(log);
                    //m.computeDist(System.out);    // there is an extra empty line if i copy it to excel:(    
                    if( log!=null )
                        log.close();
                }
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.insets = new java.awt.Insets(0, 4, 0, 0);
        abcdSubPanel.add(analDistButton, gridBagConstraints);
                
        javax.swing.JPanel tmp1Panel = new javax.swing.JPanel();

        tmp1Panel.setLayout(new java.awt.GridBagLayout());
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.insets = new java.awt.Insets(0, 2, 0, 2);
        javax.swing.JLabel tmp1Label = new javax.swing.JLabel("row count: ");
        tmp1Label.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 11));
        tmp1Label.setHorizontalAlignment( javax.swing.JLabel.RIGHT );
        tmp1Panel.add(tmp1Label, gridBagConstraints);
        
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.insets = new java.awt.Insets(0, 2, 0, 2);
        javax.swing.JLabel tmp2Label = new javax.swing.JLabel("round count: ");
        tmp2Label.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 11));
        tmp2Label.setHorizontalAlignment( javax.swing.JLabel.RIGHT );
        tmp1Panel.add(tmp2Label, gridBagConstraints);

        abcdRowCount.setEditable(false);
        abcdRowCount.setText("0");
        abcdRowCount.setMinimumSize(new java.awt.Dimension(30, 14));
        abcdRowCount.setPreferredSize(new java.awt.Dimension(88, 16));
        abcdRowCount.setHorizontalAlignment( javax.swing.JLabel.RIGHT );
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.anchor = java.awt.GridBagConstraints.EAST;
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.insets = new java.awt.Insets(0, 2, 0, 0);
        tmp1Panel.add(abcdRowCount, gridBagConstraints);
        
        locRoundCount.setEditable(false);
        locRoundCount.setText("0");
        locRoundCount.setMinimumSize(new java.awt.Dimension(30, 14));
        locRoundCount.setPreferredSize(new java.awt.Dimension(88, 16));
        locRoundCount.setHorizontalAlignment( javax.swing.JLabel.RIGHT );
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.anchor = java.awt.GridBagConstraints.EAST;
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.insets = new java.awt.Insets(0, 2, 0, 0);
        tmp1Panel.add(locRoundCount, gridBagConstraints);
		
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        abcdSubPanel.add(tmp1Panel, gridBagConstraints);
        
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.anchor = java.awt.GridBagConstraints.NORTH;
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 0.0;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        abcdPanel.add(abcdSubPanel, gridBagConstraints);

        abcdSubPanel2.setLayout(new java.awt.GridBagLayout());
        abcdSubPanel2.setBorder(new javax.swing.border.TitledBorder("ABCD measurements"));

        abcdScrollPanel.setBorder(new javax.swing.border.EmptyBorder(new java.awt.Insets(1, 1, 1, 1)));
        abcdScrollPanel.setMinimumSize(new java.awt.Dimension(300, 103));
        abcdScrollPanel.setPreferredSize(new java.awt.Dimension(300, 150));
        abcdTable.setAutoResizeMode(javax.swing.JTable.AUTO_RESIZE_OFF);
        abcdTable.setModel(abcdTableModel);
        abcdScrollPanel.setViewportView(abcdTable);
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        abcdSubPanel2.add(abcdScrollPanel, gridBagConstraints);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.SOUTH;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        abcdPanel.add(abcdSubPanel2, gridBagConstraints);
        
        tabbedPane.addTab("Ranging", abcdPanel);
      
// LOCALIZATION                             
        tabbedPane.addTab("Localization", localizationPanel);                
        
//MOTE
        motesPopupMenu = new javax.swing.JPopupMenu();
		
		deleteMoteMenuItem = new javax.swing.JMenuItem();
		deleteMoteMenuItem.setText("Delete Selected");
		deleteMoteMenuItem.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
				    	int[] selection = motesTable.getSelectedRows();
				    	Arrays.sort(selection);
				    	for(int i = selection.length-1; i >= 0; i--){
				    		if(selection[i] < motesTableModel.getNumberOfMotes())
				    			motesTableModel.removeRow(selection[i]);
				    	}
				    	motesTableModel.fireTableDataChanged();
					}
				});
		motesPopupMenu.add(deleteMoteMenuItem);
		
		queryMotesMenuItem = new javax.swing.JMenuItem();
		queryMotesMenuItem.setText("Query Motes");
		queryMotesMenuItem.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
						moteQueryLogic.doQuery();
					}
				});
		motesPopupMenu.add(queryMotesMenuItem);
		
		toggleMotesMenuItem = new javax.swing.JMenuItem();
		toggleMotesMenuItem.setText("Toggle Motes");
		toggleMotesMenuItem.addActionListener(new java.awt.event.ActionListener() {
					public void actionPerformed(java.awt.event.ActionEvent evt) {
				    	int[] selection = motesTable.getSelectedRows();
				    	Arrays.sort(selection);
				    	for(int i = selection.length-1; i >= 0; i--){
				    		if(selection[i] < motesTableModel.getNumberOfMotes()){
				    			LocalizationData.Sensor mote = ((LocalizationData.Sensor)(motesTableModel.getMoteInRow(selection[i])));
				    			mote.setSender(!mote.isSender());
				    		}
				    	}
				    	motesTableModel.fireTableDataChanged();
					}
				});
		motesPopupMenu.add(toggleMotesMenuItem);

        motesTable.setModel(motesTableModel);
        motesTable.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                motesTableMouseClicked(evt);
            }
        });
        motesTable.addKeyListener(new KeyAdapter(){
        	public void keyPressed(KeyEvent e){
        		if (e.isControlDown() && e.getKeyCode() == 84){
			    	for(int i = 0; i<localizationData.sensors.size(); i++)
		    			((LocalizationData.Sensor)localizationData.sensors.values().toArray()[i]).setSender(true);
			    	motesTableModel.fireTableDataChanged();
        		}
        	}
        });

        motesScrollPane.setPreferredSize(new java.awt.Dimension(500, 150));
        motesScrollPane.setViewportView(motesTable);

        motePanel.setLayout(new java.awt.BorderLayout());
        motePanel.setPreferredSize(new java.awt.Dimension(500, 100));
        motePanel.add(motesScrollPane, java.awt.BorderLayout.CENTER);

        sendPanel.setLayout(new java.awt.BorderLayout());
        sendPanel.add(motePanel, java.awt.BorderLayout.CENTER);

        tabbedPane.addTab("Motes", sendPanel);
        
//PARAMTERES
        parametersPanel.setLayout(new java.awt.BorderLayout());

        parametersSubPanelProgram.setLayout(new java.awt.GridLayout(1, 2, 10, 5));
        parametersSubPanelProgram.setBorder(new javax.swing.border.TitledBorder("Java Program Params:"));
        
        measurementWaitLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        measurementWaitLabel.setText("Measurement wait time(ms):");
        parametersSubPanelProgram.add(measurementWaitLabel);

        measurementWaitTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                measurementWaitTextFieldActionPerformed(evt);
            }
        });
        measurementWaitTextField.setText((new Integer(measurementThread.getMeasurementSleepTime())).toString());
        parametersSubPanelProgram.add(measurementWaitTextField);

        parametersPanel.add(parametersSubPanelProgram, java.awt.BorderLayout.NORTH);

        parametersSubPanelChannels.setLayout(new java.awt.GridBagLayout());
        parametersSubPanelChannels.setBorder(new javax.swing.border.TitledBorder("Chanels:"));
        for (int i=0; i<RipsDataTableModel.NUM_CHANNELS; i++){
        	chLabel = new javax.swing.JLabel();
        	chLabel.setText(""+(i+1));
        	gridBagConstraints = new java.awt.GridBagConstraints();
        	gridBagConstraints.weighty = 0; 
        	gridBagConstraints.weightx = 1.0;
        	gridBagConstraints.insets = new java.awt.Insets(3,3,3,3);
        	if (i==RipsDataTableModel.NUM_CHANNELS-1)
        		gridBagConstraints.gridwidth = java.awt.GridBagConstraints.REMAINDER;
        	parametersSubPanelChannels.add(chLabel, gridBagConstraints);
        }
        for (int i=0; i<RipsDataTableModel.NUM_CHANNELS; i++){
        	chTextFields[i] = new javax.swing.JTextField();
        	chTextFields[i].setMinimumSize(new java.awt.Dimension(25,20));
        	chTextFields[i].setPreferredSize(new java.awt.Dimension(25,20));
        	chTextFields[i].addActionListener(new ChannelListener(i));
        	if (i<localizationData.channels.length)
        		chTextFields[i].setText(""+localizationData.channels[i]);
        	else
        		chTextFields[i].setText("0");
        	gridBagConstraints = new java.awt.GridBagConstraints();
        	gridBagConstraints.weighty = 0; 
        	gridBagConstraints.weightx = 1.0;
        	gridBagConstraints.insets = new java.awt.Insets(3,2,3,2);
        	if (i==RipsDataTableModel.NUM_CHANNELS-1){
        		gridBagConstraints.gridwidth = java.awt.GridBagConstraints.REMAINDER;
        	}
        	parametersSubPanelChannels.add(chTextFields[i], gridBagConstraints);
        }
        javax.swing.JScrollPane channelsScroll = new javax.swing.JScrollPane(parametersSubPanelChannels);
        parametersPanel.add(channelsScroll, java.awt.BorderLayout.CENTER);

        GridLayout gL = new java.awt.GridLayout(6, 4, 10, 5);
        parametersSubPanelMote.setLayout(gL);
        parametersSubPanelMote.setBorder(new javax.swing.border.TitledBorder("Mote Params:"));

        powerMasterLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        powerMasterLabel.setText("Master power(1):");
        parametersSubPanelMote.add(powerMasterLabel);
        powerMasterTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	powerMasterTextFieldActionPerformed(evt);
            }
        });
        powerMasterTextField.setPreferredSize(new java.awt.Dimension(50,20));
        powerMasterTextField.setText((new Integer(moteParams.masterPower)).toString());
        parametersSubPanelMote.add(powerMasterTextField);

        powerAssistTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	powerAssistTextFieldActionPerformed(evt);
            }
        });
        powerAssistTextField.setPreferredSize(new java.awt.Dimension(50,20));
        powerAssistTextField.setText((new Integer(moteParams.assistPower)).toString());
        powerAssistLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        powerAssistLabel.setText("Assistant power(1):");
        parametersSubPanelMote.add(powerAssistLabel);
        parametersSubPanelMote.add(powerAssistTextField);
        
        algorithmTypeComboBox.setPreferredSize(new java.awt.Dimension(100,20));
        algorithmTypeComboBox.setMaximumRowCount(3);
        algorithmTypeComboBox.addItem("Exact channels");
        algorithmTypeComboBox.addItem("Channel hop");
        algorithmTypeComboBox.addItem("Raw data");

        algorithmTypeComboBox.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	algorithmTypeActionPerformed(evt);
            }
        });
        
        algorithmTypeLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        algorithmTypeLabel.setText("Algorithm type(53):");
        //reset channel values to exact channels
        for (int i=0; i<localizationData.default_channels.length; i++){
            localizationData.channels[i] = localizationData.default_channels[i];
            chTextFields[i].setText(""+localizationData.channels[i]);
        }
        parametersSubPanelMote.add(algorithmTypeLabel);
        parametersSubPanelMote.add(algorithmTypeComboBox);

        interferenceFreqTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	interferenceFreqActionPerformed(evt);
            }
        });
        interferenceFreqTextField.setPreferredSize(new java.awt.Dimension(50,20));
        interferenceFreqTextField.setText((new Integer(moteParams.interferenceFreq)).toString());
        interferenceFreqLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        interferenceFreqLabel.setText("Interference freq(350):");
        parametersSubPanelMote.add(interferenceFreqLabel);
        parametersSubPanelMote.add(interferenceFreqTextField);

        tsNumHopsTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	tsNumHopsActionPerformed(evt);
            }
        });
        tsNumHopsTextField.setPreferredSize(new java.awt.Dimension(50,20));
        tsNumHopsTextField.setText((new Integer(moteParams.tsNumHops)).toString());
        tsNumHopsLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        tsNumHopsLabel.setText("TS num hops (3):");
        parametersSubPanelMote.add(tsNumHopsLabel);
        parametersSubPanelMote.add(tsNumHopsTextField);

        channelATextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	channelAActionPerformed(evt);
            }
        });
        channelATextField.setPreferredSize(new java.awt.Dimension(50,20));
        channelATextField.setText((new Integer(moteParams.channelA)).toString());
        channelALabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        channelALabel.setText("Tune channel (40):");
        parametersSubPanelMote.add(channelALabel);
        parametersSubPanelMote.add(channelATextField);

        initialTuningTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	initialTuningActionPerformed(evt);
            }
        });
        initialTuningTextField.setPreferredSize(new java.awt.Dimension(50,20));
        initialTuningTextField.setText((new Integer(moteParams.initialTuning)).toString());
        initialTuningLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        initialTuningLabel.setText("Initial tuning(-60):");
        parametersSubPanelMote.add(initialTuningLabel);
        parametersSubPanelMote.add(initialTuningTextField);

        tuningOffsetTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	tuningOffsetActionPerformed(evt);
            }
        });
        tuningOffsetTextField.setPreferredSize(new java.awt.Dimension(50,20));
        tuningOffsetTextField.setText((new Integer(moteParams.tuningOffset)).toString());
        tuningOffsetLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        tuningOffsetLabel.setText("Tune step(5):");
        parametersSubPanelMote.add(tuningOffsetLabel);
        parametersSubPanelMote.add(tuningOffsetTextField);

        numTuneHopsTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	numTuneHopsActionPerformed(evt);
            }
        });
        numTuneHopsTextField.setPreferredSize(new java.awt.Dimension(50,20));
        numTuneHopsTextField.setText((new Integer(moteParams.numTuneHops)).toString());
        numTuneHopsLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        numTuneHopsLabel.setText("Tune hops(24):");
        parametersSubPanelMote.add(numTuneHopsLabel);
        parametersSubPanelMote.add(numTuneHopsTextField);

        numChanHopsTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	numChanHopsActionPerformed(evt);
            }
        });
        numChanHopsTextField.setPreferredSize(new java.awt.Dimension(50,20));
        numChanHopsTextField.setText((new Integer(moteParams.numChanHops)).toString());
        numChanHopsLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        numChanHopsLabel.setText("Channel hops(19):");
        parametersSubPanelMote.add(numChanHopsLabel);
        parametersSubPanelMote.add(numChanHopsTextField);
        
        initialChannelTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	initialChannelActionPerformed(evt);
            }
        });
        initialChannelTextField.setPreferredSize(new java.awt.Dimension(50,20));
        initialChannelTextField.setText((new Integer(moteParams.initialChannel)).toString());
        initialChannelLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        initialChannelLabel.setText("Initial Channel(-55):");
        parametersSubPanelMote.add(initialChannelLabel);
        parametersSubPanelMote.add(initialChannelTextField);
        
        channelOffsetTextField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
            	channelOffsetActionPerformed(evt);
            }
        });
        channelOffsetTextField.setPreferredSize(new java.awt.Dimension(50,20));
        channelOffsetTextField.setText((new Integer(moteParams.channelOffset)).toString());
        channelOffsetLabel.setHorizontalAlignment(javax.swing.SwingConstants.CENTER);
        channelOffsetLabel.setText("Channel Offset(6):");
        parametersSubPanelMote.add(channelOffsetLabel);
        parametersSubPanelMote.add(channelOffsetTextField);
        
        parametersPanel.add(parametersSubPanelMote, java.awt.BorderLayout.SOUTH);
        
        
        tabbedPane.addTab("Params", parametersPanel);

        tabbedPanel.add(tabbedPane, java.awt.BorderLayout.CENTER);

//COMMAND PANEL        
//        commandPanel.setBorder(new javax.swing.border.TitledBorder("Commands"));
        commandPanel.setMinimumSize(new java.awt.Dimension(400, 70));
        commandPanel.setPreferredSize(new java.awt.Dimension(400, 70));
        commandPanel.setLayout(new java.awt.GridBagLayout());
        
        JPanel tmp2Panel = new JPanel();
        tmp2Panel.setLayout(new java.awt.GridBagLayout());
        tmp2Panel.setBorder(new javax.swing.border.TitledBorder("Mote measurement"));
        tmp2Panel.setMinimumSize(new java.awt.Dimension(120, 55));
        tmp2Panel.setPreferredSize(new java.awt.Dimension(150, 55));
	        startCommandButton.setPreferredSize(new java.awt.Dimension(60, 20));
	        startCommandButton.setMinimumSize(new java.awt.Dimension(50, 20));
	        startCommandButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 11));
	        startCommandButton.setText("Start");
	        startCommandButton.addActionListener(new java.awt.event.ActionListener() {
	            public void actionPerformed(java.awt.event.ActionEvent evt) {
	                startCommandButtonActionPerformed(evt);
	            }
	        });
	        gridBagConstraints = new java.awt.GridBagConstraints();
	        gridBagConstraints.insets = new java.awt.Insets(2, 6, 2, 2);
	        tmp2Panel.add(startCommandButton, gridBagConstraints);
	
	        stopCommandButton.setPreferredSize(new java.awt.Dimension(60, 20));
	        stopCommandButton.setMinimumSize(new java.awt.Dimension(50, 20));
	        stopCommandButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 11));
	        stopCommandButton.setText("Stop");
	        stopCommandButton.addActionListener(new java.awt.event.ActionListener() {
	            public void actionPerformed(java.awt.event.ActionEvent evt) {
	                stopCommandButtonActionPerformed(evt);
	            }
	        });
	        gridBagConstraints = new java.awt.GridBagConstraints();
	        gridBagConstraints.insets = new java.awt.Insets(2, 6, 2, 2);
	        tmp2Panel.add(stopCommandButton, gridBagConstraints);
        commandPanel.add(tmp2Panel);

        JPanel tmp4Panel = new JPanel();
        tmp4Panel.setLayout(new java.awt.GridBagLayout());
        tmp4Panel.setBorder(new javax.swing.border.TitledBorder("Data load/save"));
        tmp4Panel.setMinimumSize(new java.awt.Dimension(190, 55));
        tmp4Panel.setPreferredSize(new java.awt.Dimension(230, 55));
        	resetButton.setPreferredSize(new java.awt.Dimension(65, 20));
	        resetButton.setMinimumSize(new java.awt.Dimension(55, 20));
	        resetButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 12));
	        resetButton.setText("Clear");
	        resetButton.addActionListener(new java.awt.event.ActionListener() {
	            public void actionPerformed(java.awt.event.ActionEvent evt) {
	                resetButtonActionPerformed(evt);
	            }
	        });
	        gridBagConstraints = new java.awt.GridBagConstraints();
	        gridBagConstraints.insets = new java.awt.Insets(0, 4, 0, 0);
	        tmp4Panel.add(resetButton, gridBagConstraints);
	
	        loadFileButton.setPreferredSize(new java.awt.Dimension(65, 20));
	        loadFileButton.setMinimumSize(new java.awt.Dimension(55, 20));
	        loadFileButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 12));
	        loadFileButton.setText("Load");
	        loadFileButton.addActionListener(new java.awt.event.ActionListener() {
	            public void actionPerformed(java.awt.event.ActionEvent evt) {
	            	loadFileButtonActionPerformed(evt);
	            }
	        });
	        gridBagConstraints = new java.awt.GridBagConstraints();
	        gridBagConstraints.insets = new java.awt.Insets(0, 4, 0, 0);
	        tmp4Panel.add(loadFileButton, gridBagConstraints);
	
	        saveFileButton.setPreferredSize(new java.awt.Dimension(65, 20));
	        saveFileButton.setMinimumSize(new java.awt.Dimension(55, 20));
	        saveFileButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 12));
	        saveFileButton.setText("Save");
	        saveFileButton.addActionListener(new java.awt.event.ActionListener() {
	            public void actionPerformed(java.awt.event.ActionEvent evt) {
	            	saveFileButtonActionPerformed(evt);
	            }
	        });
	        gridBagConstraints = new java.awt.GridBagConstraints();
	        gridBagConstraints.insets = new java.awt.Insets(0, 4, 0, 0);
	        tmp4Panel.add(saveFileButton, gridBagConstraints);
	    commandPanel.add(tmp4Panel);

        JPanel tmp3Panel = new JPanel();
        tmp3Panel.setLayout(new java.awt.GridBagLayout());
        tmp3Panel.setBorder(new javax.swing.border.TitledBorder("Send parameters"));
        tmp3Panel.setMinimumSize(new java.awt.Dimension(260, 55));
        tmp3Panel.setPreferredSize(new java.awt.Dimension(400, 55));
	        sendChannelCommandButton.setPreferredSize(new java.awt.Dimension(90, 20));
	        sendChannelCommandButton.setMinimumSize(new java.awt.Dimension(55, 20));
	        sendChannelCommandButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 11));
	        sendChannelCommandButton.setText("Channels");
	        sendChannelCommandButton.addActionListener(new java.awt.event.ActionListener() {
	            public void actionPerformed(java.awt.event.ActionEvent evt) {
	            	sendChannelButtonActionPerformed(evt);
	            }
	        });
	        gridBagConstraints = new java.awt.GridBagConstraints();
	        gridBagConstraints.insets = new java.awt.Insets(2, 6, 2, 2);
	        tmp3Panel.add(sendChannelCommandButton, gridBagConstraints);
	
	        sendMoteParamsCommandButton.setPreferredSize(new java.awt.Dimension(80, 20));
	        sendMoteParamsCommandButton.setMinimumSize(new java.awt.Dimension(55, 20));
	        sendMoteParamsCommandButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 11));
	        sendMoteParamsCommandButton.setText("Params");
	        sendMoteParamsCommandButton.addActionListener(new java.awt.event.ActionListener() {
	            public void actionPerformed(java.awt.event.ActionEvent evt) {
	            	sendMoteParamsButtonActionPerformed(evt);
	            }
	        });
	        gridBagConstraints = new java.awt.GridBagConstraints();
	        gridBagConstraints.insets = new java.awt.Insets(2, 6, 2, 2);
	        tmp3Panel.add(sendMoteParamsCommandButton, gridBagConstraints);
	
	        resetRCCommandButton.setPreferredSize(new java.awt.Dimension(85, 20));
	        resetRCCommandButton.setMinimumSize(new java.awt.Dimension(55, 20));
	        resetRCCommandButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 11));
	        resetRCCommandButton.setText("ResetRC");
	        resetRCCommandButton.addActionListener(new java.awt.event.ActionListener() {
	            public void actionPerformed(java.awt.event.ActionEvent evt) {
	            	resetRCCommandButtonActionPerformed(evt);
	            }
	        });
	        gridBagConstraints = new java.awt.GridBagConstraints();
	        gridBagConstraints.insets = new java.awt.Insets(2, 6, 2, 2);
	        tmp3Panel.add(resetRCCommandButton, gridBagConstraints);

	        resetChanCommandButton.setPreferredSize(new java.awt.Dimension(95, 20));
	        resetChanCommandButton.setMinimumSize(new java.awt.Dimension(55, 20));
	        resetChanCommandButton.setFont(new java.awt.Font("Arial", java.awt.Font.BOLD, 11));
	        resetChanCommandButton.setText("ResetChan");
	        resetChanCommandButton.addActionListener(new java.awt.event.ActionListener() {
	            public void actionPerformed(java.awt.event.ActionEvent evt) {
	            	resetChanCommandButtonActionPerformed(evt);
	            }
	        });
	        gridBagConstraints = new java.awt.GridBagConstraints();
	        gridBagConstraints.insets = new java.awt.Insets(2, 6, 2, 2);
	        tmp3Panel.add(resetChanCommandButton, gridBagConstraints);
	        commandPanel.add(tmp3Panel);

        tabbedPanel.add(commandPanel, java.awt.BorderLayout.SOUTH);
        
        getContentPane().add(tabbedPanel, java.awt.BorderLayout.CENTER);

        pack();
    }

    private void setTables(){
        tableModel.resetEntries();
        abcdTableModel.resetEntries();
        motesTableModel.fireTableDataChanged();
        
		javax.swing.table.TableColumnModel tc = table.getColumnModel();
		
		for (int i=0; i<tc.getColumnCount(); i++)
		    if (i==0)
		        tc.getColumn(i).setMaxWidth(55);
		    else if (i<5)
		        tc.getColumn(i).setMaxWidth(40);
            else{
		        tc.getColumn(i).setMaxWidth(35);
		        tc.getColumn(i).setCellRenderer(new MyBackgroundRenderer());
            }
        tc.getColumn(4).setCellRenderer(new MyColorRenderer());
        rowCount.setText(""+(tableModel.getRowCount()));
        
              

        javax.swing.table.TableColumnModel abcdTC = abcdTable.getColumnModel();
		for (int i=0; i<abcdTC.getColumnCount(); i++)
	        abcdTC.getColumn(i).setMaxWidth(55);
        abcdRowCount.setText(""+(abcdTableModel.getRowCount()));                      
    }        

	private void dataChooserComboBoxActionPerformed(java.awt.event.ActionEvent evt) {
		if( dataChooserComboBox.getSelectedIndex() < 0 )
			return;
		String name = (String)dataChooserComboBox.getSelectedItem();
	    if (name == "Frequency")
            tableModel.showPhase = false;
        else
            tableModel.showPhase = true;
/*        tableModel.resetEntries();
        tableModel.writeRows();
        setTables();*/
        setTables();
        tableModel.writeRows();
	}

    private void collapseMotesCheckBoxItemStateChanged(java.awt.event.ItemEvent evt) {
        if (evt.getStateChange() == java.awt.event.ItemEvent.SELECTED) {
            tableModel.collapseMotes = true;
        } else if(evt.getStateChange() == java.awt.event.ItemEvent.DESELECTED) {
            tableModel.collapseMotes = false;
        }
        /*        tableModel.resetEntries();
        tableModel.writeRows();
        setTables();*/
        setTables();
        tableModel.writeRows();
    }

    private void colorsCheckBoxItemStateChanged(java.awt.event.ItemEvent evt) {
        if (evt.getStateChange() == java.awt.event.ItemEvent.SELECTED) {
            showColors = true;
        } else if(evt.getStateChange() == java.awt.event.ItemEvent.DESELECTED) {
            showColors = false;
        }
        table.repaint();
    }
    
    private void filterCheckBoxItemStateChanged(java.awt.event.ItemEvent evt) {
        if (evt.getStateChange() == java.awt.event.ItemEvent.SELECTED) {
            abcdTableModel.setFilterOutBad(true);
        } else if(evt.getStateChange() == java.awt.event.ItemEvent.DESELECTED) {
        	abcdTableModel.setFilterOutBad(false);
        }
        table.repaint();
    }

    private void resetButtonActionPerformed(java.awt.event.ActionEvent evt) {
    	try {
    	    saveFileButtonActionPerformed(null);
	    	setFileStructure();
    	}
    	catch(Exception e){
    		System.out.println("File setting problem!");
    	}
    	measurementThread.setSequenceNumber(0);
    	tableModel.resetTable();
    	abcdTableModel.resetTable();
		localizationData.measurements.clear();
		//localizationData.sensors.clear();
		localizationData.abcd_measurements.clear();
    	
        setTables();
    }

    private void abcdResetButtonActionPerformed(java.awt.event.ActionEvent evt) {
        localizationPanel.reset();
        localizationData.abcd_measurements.clear();
    	abcdTableModel.resetTable();
    	abcdTableModel.recalculateAll();
    	setTables();
        abcdRowCount.setText(""+(abcdTableModel.getRowCount()));
        
        localizationData.printRangeStat();                
               

    	//TODO -> needs to recalculate, however the measurement can be runing (possible duplication of data)
    	// may have map of offset arrays in abcd measurement that maps {seqNumber} -> {array of offsets}
    	// this would solve the duplicates
    	// or catch the next measurement ended and recalculate there
    }
            
    private void loadFileButtonActionPerformed(java.awt.event.ActionEvent evt) {
        javax.swing.JFileChooser chooser = new javax.swing.JFileChooser(BASE_DIRECTORY);
        chooser.setDialogTitle("Choose File to load");
        int returnVal = chooser.showSaveDialog(this);
        String tmpFileName = new String("");
        int tmpIdx = -1;
        if(returnVal == javax.swing.JFileChooser.APPROVE_OPTION)
        	tmpFileName = chooser.getSelectedFile().getAbsolutePath();//getName();
        
        boolean readRanges = false;
        if ( (tmpIdx = tmpFileName.indexOf(".freq")) > 0 ||
        	 (tmpIdx = tmpFileName.indexOf(".phase")) > 0)
        	tmpFileName = tmpFileName.substring(0,tmpIdx);
        else if ((tmpIdx = tmpFileName.indexOf(".ranges")) > 0){
        	tmpFileName = tmpFileName.substring(0,tmpIdx);
        	readRanges = true;
        }
        else
        	System.out.println("Click on either .freq,.phase, or .ranges file!");
        
        System.out.println("Reading fileBase:"+tmpFileName);

        try{
            localizationPanel.reset();            
    		localizationData.measurements.clear();
    		localizationData.sensors.clear();
        	
        	tableModel.readFromFile(tmpFileName, readRanges);
        	abcdTableModel.resetTable();
            
            // update channels
            for (int i=0; i<RipsDataTableModel.NUM_CHANNELS; i++)                        
                chTextFields[i].setText(""+localizationData.channels[i]);
        }
        catch (Exception e){
        	System.out.println("File reading problem!");
        	setFileStructure();
        	return;
        }
        
        if (readRanges)
        	abcdTableModel.writeAll();
        
        // update channels
        for (int i=0; i<RipsDataTableModel.NUM_CHANNELS; i++)                        
            chTextFields[i].setText(""+localizationData.channels[i]);
        //TODO this should be maximum seqNum in the file
        measurementThread.setSequenceNumber(0);
        setTables();
        
        currentFileName = tmpFileName;
        fileName.setText(currentFileName);
    }    

    private void saveFileButtonActionPerformed(java.awt.event.ActionEvent evt) {
        System.out.println("Saving to "+currentFileName+"!");
    	try{
        	tableModel.saveToFile(currentFileName);
        }
        catch (Exception e){
        	System.out.println("File saving problem!");
        	setFileStructure();
        }
    }    
    
    private void motesTableMouseClicked(java.awt.event.MouseEvent evt) {
       if (evt.getButton() == MouseEvent.BUTTON3) {
                motesPopupMenu.show(motesTable, evt.getX(), evt.getY());
        }
    }

    private void stopCommandButtonActionPerformed(java.awt.event.ActionEvent evt) {
    	if (measurementThread != null){
    		measurementThread.finish();
    		measurementThread.interrupt();
    	}
    }
    private void resetRCCommandButtonActionPerformed(java.awt.event.ActionEvent evt) {
    	RemoteControl.tuneSequenceNumber(64);
    }
    private void resetChanCommandButtonActionPerformed(java.awt.event.ActionEvent evt) {
        for (int i=0; i<localizationData.default_channels.length; i++){
            localizationData.channels[i] = localizationData.default_channels[i];
            chTextFields[i].setText(""+localizationData.channels[i]);
        }

    }
    private void startCommandButtonActionPerformed(java.awt.event.ActionEvent evt) {
    	if (measurementThread != null && measurementThread.getThreadState() == MeasurementThread.MT_STATE_RUNING){
	        System.out.println("Thread is already runing!");
	        return;
	    }
        
    	measurementThread = new MeasurementThread();
    	if (!measurementThread.init(localizationData.sensors.values().toArray(), this))
        	System.out.println("Couldn't start!");
        else{
            try{
                measurementThread.start();
            }
            catch(Exception e){
                System.out.println("Start thread exception");
                return;
            }
            System.out.println("Started!");
        }
    }

    private void sendChannelButtonActionPerformed(java.awt.event.ActionEvent evt) {
    	moteQueryLogic.sendChannels(localizationData.channels);
    }    
    private void sendMoteParamsButtonActionPerformed(java.awt.event.ActionEvent evt) {
    	moteQueryLogic.sendMoteParams(moteParams);
    }    
    
    private void measurementWaitTextFieldActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(measurementWaitTextField.getText());
    		prefs.putInt("measurementSleepTime",value);
    		measurementThread.setMeasurementSleepTime(value);
    	}catch(NumberFormatException nfe){
    		measurementWaitTextField.setText(Integer.toString(measurementThread.getMeasurementSleepTime()));
    	}
    }
    
    private void chTextFieldActionPerformed(java.awt.event.ActionEvent evt, int channelIdx) {
    	try{
    		int value = Integer.parseInt(chTextFields[channelIdx].getText());
    		prefs.putInt("ch"+channelIdx,value);
    		localizationData.channels[channelIdx] = value;
    	}catch(NumberFormatException nfe){
    		chTextFields[channelIdx].setText(Integer.toString(localizationData.channels[channelIdx]));
    	}
    }
    
    private void powerMasterTextFieldActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(powerMasterTextField.getText());
    		prefs.putInt("moteParams.masterPower",value);
    		moteParams.masterPower = value;
    	}catch(NumberFormatException nfe){
    		powerMasterTextField.setText(Integer.toString(moteParams.masterPower));
    	}
    }
    private void powerAssistTextFieldActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(powerAssistTextField.getText());
    		prefs.putInt("moteParams.assistPower",value);
    		moteParams.assistPower = value;
    	}catch(NumberFormatException nfe){
    		powerAssistTextField.setText(Integer.toString(moteParams.assistPower));
    	}
    }
    private void algorithmTypeActionPerformed(java.awt.event.ActionEvent evt) {
	    int value = 53;
	    
	    if (algorithmTypeComboBox.getSelectedIndex() == 1){
	    	value = 52;
            int channel = moteParams.initialChannel;
            for (int i=0; i<localizationData.default_channels.length; i++){
                if (i<=moteParams.numChanHops)
                    localizationData.channels[i] = channel;
                else
                    localizationData.channels[i] = 0;
                chTextFields[i].setText(""+localizationData.channels[i]);
	            channel+=moteParams.channelOffset;
	        }
	    }
	    else if (algorithmTypeComboBox.getSelectedIndex() == 0){
	    	value = 53;
	    	 for (int i=0; i<localizationData.default_channels.length; i++){
	            localizationData.channels[i] = localizationData.default_channels[i];
	            chTextFields[i].setText(""+localizationData.channels[i]);
	        }
	    }
	    else if (algorithmTypeComboBox.getSelectedIndex() == 2)
	    	value = 0;
	    else 
	        algorithmTypeComboBox.setSelectedIndex(0);
	    	

		moteParams.algorithmType = value;
    }
    private void interferenceFreqActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(interferenceFreqTextField.getText());
    		prefs.putInt("moteParams.interferenceFreq",value);
    		moteParams.interferenceFreq = value;
    	}catch(NumberFormatException nfe){
    		interferenceFreqTextField.setText(Integer.toString(moteParams.interferenceFreq));
    	}
    }
    private void tsNumHopsActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(tsNumHopsTextField.getText());
    		prefs.putInt("moteParams.tsNumHops",value);
    		moteParams.tsNumHops = value;
    	}catch(NumberFormatException nfe){
    		tsNumHopsTextField.setText(Integer.toString(moteParams.tsNumHops));
    	}
    }
    
    private void channelAActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(channelATextField.getText());
    		prefs.putInt("moteParams.moteParams.channelA",value);
    		moteParams.channelA = value;
    	}catch(NumberFormatException nfe){
    		channelATextField.setText(Integer.toString(moteParams.channelA));
    	}
    }
    private void initialTuningActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(initialTuningTextField.getText());
    		prefs.putInt("moteParams.initialTuning",value);
    		moteParams.initialTuning = value;
    	}catch(NumberFormatException nfe){
    		initialTuningTextField.setText(Integer.toString(moteParams.initialTuning));
    	}
    }
    private void tuningOffsetActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(tuningOffsetTextField.getText());
    		prefs.putInt("moteParams.tuningOffset",value);
    		moteParams.tuningOffset = value;
    	}catch(NumberFormatException nfe){
    		tuningOffsetTextField.setText(Integer.toString(moteParams.tuningOffset));
    	}
    }
    private void numTuneHopsActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(numTuneHopsTextField.getText());
    		prefs.putInt("moteParams.numTuneHops",value);
    		moteParams.numTuneHops = value;
    	}catch(NumberFormatException nfe){
    		numTuneHopsTextField.setText(Integer.toString(moteParams.numTuneHops));
    	}
    }
    private void numChanHopsActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(numChanHopsTextField.getText());
    		prefs.putInt("moteParams.numChanHops",value);
    		moteParams.numChanHops = value;
    	}catch(NumberFormatException nfe){
    		numChanHopsTextField.setText(Integer.toString(moteParams.numChanHops));
    	}
    }
    
    private void initialChannelActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(initialChannelTextField.getText());
    		prefs.putInt("moteParams.initialChannel",value);
    		moteParams.initialChannel = value;
    	}catch(NumberFormatException nfe){
    		initialChannelTextField.setText(Integer.toString(moteParams.initialChannel));
    	}
    }
    
    private void channelOffsetActionPerformed(java.awt.event.ActionEvent evt) {
    	try{
    		int value = Integer.parseInt(channelOffsetTextField.getText());
    		prefs.putInt("moteParams.channelOffset",value);
    		moteParams.channelOffset = value;
    	}catch(NumberFormatException nfe){
    		channelOffsetTextField.setText(Integer.toString(moteParams.channelOffset));
    	}
    }
    
    public void measurementEnded(int masterID, int sequenceNumber) {
    	LocalizationData.MeasurementEntry mE = (LocalizationData.MeasurementEntry) 
					(localizationData.measurements.get(LocalizationData.getMeasurementKey(masterID, sequenceNumber)));
    	if (mE!=null){
    		localizationData.validateFrequencies(mE);
    		localizationData.filterMeasurementsWithFreqency();
    		abcdTableModel.addMeasurementEntry(mE);
            abcdRowCount.setText(""+(abcdTableModel.getRowCount()));        
    	}
        table.repaint();
    }
    
    // the first 5 bytes are: addr(2), type(1), group(1), length(1)
    public void packetReceived(byte[] packet) {
        if( (packet[PACKET_TYPE]&0xff)!=ACTIVE_MESSAGE ){
            System.out.println("wrong message id!");
            return;
        }
        
		int headerLength = 3;
		int msgLength = packet[PACKET_LENGTH_BYTE] & 0xFF;
		int dataLength = 0;

		if ( (packet[PACKET_ROUTING_TYPE]&0xff)==RIPS_APP_ID )
    		dataLength = RipsDataTableModel.PACKET_LENGTH;
        else if ( (packet[PACKET_ROUTING_TYPE]&0xff)==RIPS_APP_ID+1 )
    		System.out.println("Old mote software running!");
    	else
    	    return;

		byte[] slice = new byte[PACKET_DATA + headerLength + dataLength];
				
		if ((msgLength-headerLength) % dataLength != 0)
			return;

		for(int i = headerLength; i < msgLength; i += dataLength)
		{
			slice[PACKET_LENGTH_BYTE] = (byte)(dataLength);
			System.arraycopy(packet, PACKET_DATA + i, slice, PACKET_DATA, dataLength);
		    tableModel.addPacket(measurementThread.getSequenceNumber(), 
		    						measurementThread.getMasterID(), 
									measurementThread.getAssistantID(), 
									measurementThread.getMoteSequenceNumber(), 
									slice
								);
		}
        rowCount.setText(""+tableModel.getRowCount());        		
    }

    private javax.swing.JPanel tabbedPanel;
    private javax.swing.JTabbedPane tabbedPane;

    private javax.swing.JPanel dataPanel;    
        private javax.swing.JPanel dataSubPanel;
        private javax.swing.JPanel checkBoxPanel;
        private javax.swing.JCheckBox collapseMotesCheckBox;
        private javax.swing.JCheckBox colorsCheckBox;
        private javax.swing.JComboBox dataChooserComboBox;
        private javax.swing.JButton resetButton;
        private javax.swing.JTextField fileName;
        private javax.swing.JButton loadFileButton;
        private javax.swing.JButton saveFileButton;

        private javax.swing.JTextField rowCount;
        private javax.swing.JPanel dataSubPanel2;
        private javax.swing.JTable table;
        private javax.swing.JScrollPane dataScrollPanel;
        
    private javax.swing.JPanel abcdPanel;    
        private javax.swing.JPanel abcdSubPanel;
        private JCheckBox filterCheckBox;
        private javax.swing.JButton abcdResetButton;
        private javax.swing.JTextField abcdRowCount;
        private javax.swing.JTextField locRoundCount;

        private javax.swing.JPanel abcdSubPanel2;
        private javax.swing.JTable abcdTable;
        private javax.swing.JScrollPane abcdScrollPanel;
        
    private GALocDisplay2 localizationPanel;             

    private javax.swing.JPanel sendPanel;    
        private javax.swing.JPanel motePanel;
        private javax.swing.JTable motesTable;
        private javax.swing.JScrollPane motesScrollPane;
    	private javax.swing.JPopupMenu motesPopupMenu;
    	private javax.swing.JMenuItem deleteMoteMenuItem;
    	private javax.swing.JMenuItem queryMotesMenuItem;
    	private javax.swing.JMenuItem toggleMotesMenuItem;
    
        private javax.swing.JPanel commandPanel;
        private javax.swing.JButton startCommandButton;
        private javax.swing.JButton resetRCCommandButton;
        private javax.swing.JButton resetChanCommandButton;
        private javax.swing.JButton stopCommandButton;
        private javax.swing.JButton sendChannelCommandButton;
        private javax.swing.JButton sendMoteParamsCommandButton;

    private javax.swing.JPanel parametersPanel;
        private javax.swing.JPanel parametersSubPanelProgram;
        private javax.swing.JLabel measurementWaitLabel;
        private javax.swing.JTextField measurementWaitTextField;

        private javax.swing.JPanel parametersSubPanelChannels;
        private javax.swing.JLabel chLabel;
        private javax.swing.JTextField chTextFields[];
        
        private javax.swing.JPanel parametersSubPanelMote;
        private javax.swing.JLabel powerMasterLabel;
        private javax.swing.JLabel powerAssistLabel;
        private javax.swing.JLabel algorithmTypeLabel;
        private javax.swing.JLabel interferenceFreqLabel;
        private javax.swing.JLabel tsNumHopsLabel;
        private javax.swing.JLabel channelALabel;
        private javax.swing.JLabel initialTuningLabel;
        private javax.swing.JLabel tuningOffsetLabel;
        private javax.swing.JLabel numTuneHopsLabel;
        private javax.swing.JLabel numChanHopsLabel;
        private javax.swing.JLabel initialChannelLabel;
        private javax.swing.JLabel channelOffsetLabel;
        
        private javax.swing.JTextField powerMasterTextField;
        private javax.swing.JTextField powerAssistTextField;
        private javax.swing.JComboBox algorithmTypeComboBox;
        private javax.swing.JTextField interferenceFreqTextField;
        private javax.swing.JTextField tsNumHopsTextField;
        private javax.swing.JTextField channelATextField;
        private javax.swing.JTextField initialTuningTextField;
        private javax.swing.JTextField tuningOffsetTextField;
        private javax.swing.JTextField numTuneHopsTextField;
        private javax.swing.JTextField numChanHopsTextField;
        private javax.swing.JTextField initialChannelTextField;
        private javax.swing.JTextField channelOffsetTextField;
        
}
