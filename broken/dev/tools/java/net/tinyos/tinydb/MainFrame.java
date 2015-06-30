package net.tinyos.tinydb;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import net.tinyos.tinydb.awtextra.*;

public class MainFrame extends JFrame {
    //Layout constants
    static final int TAB_PANE_WID = 575;  //width of the tabbed pane
    static final int BUT_SEP = 10; //seperator between buttons
    static final int FRAME_HEIGHT = 535;
    static final int BUT_PANEL_WID = 200;
    static final int BUT_HEIGHT = 30;
    
    static final int BUT_PANEL_LEFT = TAB_PANE_WID + BUT_SEP;
    static final int SEND_BUTTON_TOP = 25;
    static final int TOPO_BUTTON_TOP = SEND_BUTTON_TOP + BUT_HEIGHT + BUT_SEP;
    static final int MAGNET_BUTTON_TOP = TOPO_BUTTON_TOP + BUT_HEIGHT + BUT_SEP;

    static final int LOGO_WID= 128; //size of tinydb logo
    static final int LOGO_HEIGHT = 108;

    static final int LOGO_LEFT = 0;
    static final int LOGO_TOP = MAGNET_BUTTON_TOP + BUT_HEIGHT + BUT_SEP;

    public MainFrame(TinyDBNetwork nw, boolean startGuiInterface) {
	super("Query Constructor");
	this.nw = nw;

	/*
	  KeyboardFocusManager kb = KeyboardFocusManager.getCurrentKeyboardFocusManager();
	  kb.addKeyEventPostProcessor(nw);
	*/


	initComponents(startGuiInterface);
    }
	
    private void initComponents(boolean startGuiInterface) {
        addWindowListener(new WindowAdapter() {
		public void windowClosing(WindowEvent evt) {
		    exitForm(evt);
		}
	    });


	guiPanel = new GuiPanel(nw);
	textPanel = new TextPanel(nw);

	tabPanel = new JTabbedPane();
	tabPanel.addTab("Graphical Interface", guiPanel);
	tabPanel.addTab("Text Interface", textPanel);

	tabPanel.setSelectedIndex(startGuiInterface?0:1);

	sendButton = new JButton("Send Query");
	sendButton.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    if (tabPanel.getSelectedIndex() == 0)
			guiPanel.sendQuery();
		    else if (tabPanel.getSelectedIndex() == 1)
			textPanel.sendQuery();
		}
	    });

	displayTopologyButton = new JButton("Display Topology");
	displayTopologyButton.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    guiPanel.displayTopology();
		}
	    });

	magnetDemoButton = new JButton("Magnet Demo");
	magnetDemoButton.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    guiPanel.magnetDemo();
		}
	    });

	buttonPanel = new JPanel(new AbsoluteLayout());
	buttonPanel.add(sendButton, new AbsoluteConstraints(0, SEND_BUTTON_TOP, -1, BUT_HEIGHT));
	buttonPanel.add(displayTopologyButton, new AbsoluteConstraints(0, TOPO_BUTTON_TOP, -1, BUT_HEIGHT));
	buttonPanel.add(magnetDemoButton, new AbsoluteConstraints(0, MAGNET_BUTTON_TOP, -1, BUT_HEIGHT));
	logoLabel = new JLabel(new ImageIcon("images/tinydblogo.jpg"));
	buttonPanel.add(logoLabel, new AbsoluteConstraints(LOGO_LEFT, LOGO_TOP, LOGO_WID, LOGO_HEIGHT));

	
	contentPane.setLayout(new AbsoluteLayout());
	contentPane.add(tabPanel, new AbsoluteConstraints(0, 0, TAB_PANE_WID, FRAME_HEIGHT));
	contentPane.add(buttonPanel, new AbsoluteConstraints(BUT_PANEL_LEFT, 0, BUT_PANEL_WID, FRAME_HEIGHT));


	pack();
    }
	
    private void exitForm(WindowEvent evt) {
	System.exit(0);
    }

        
    /** Allocate a query ID for a new query
	WARNING:  There could be serious problems here 
	on wrap-around.  We aren't dealing with this.
    */
    public static byte allocateQID()
    {
	return curId++;
    }

    GuiPanel guiPanel;
    TextPanel textPanel;
    TinyDBNetwork nw;
    Container contentPane = getContentPane();
    JTabbedPane tabPanel;
    JPanel buttonPanel;
    private JLabel logoLabel;
    JButton sendButton, displayTopologyButton, magnetDemoButton;
    static byte curId = 0;
}	

