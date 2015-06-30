//$Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/Spotlight/Celestron/CelestronGUI.java,v 1.1.1.1 2005/05/10 23:37:05 rsto99 Exp $

/* "Copyright (c) 2000-2004 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Author: Radu Stoleru
// Date: 3/26/2005

import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.GridLayout;
import java.awt.Insets;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import java.text.DecimalFormat;
import java.util.List;
import java.util.Observable;
import java.util.Observer;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.border.TitledBorder;

/*******************************************************************/
public class CelestronGUI extends JFrame implements Observer {

	Localizer      localizer;
	DecimalFormat  fmt;
	private JLabel node1Alt, node1Az, node2Alt, node2Az;
	private JLabel node3Alt, node3Az, node4Alt, node4Az;
	private JLabel node5Alt, node5Az, node6Alt, node6Az;
	private JLabel node7Alt, node7Az, node8Alt, node8Az;
	private JLabel node9Alt, node9Az, node10Alt, node10Az;
	private JLabel localizationDuration;
	private JTextField thresholdField, deltaField;
	
	private JLabel[] nodeArray = new JLabel[10];
	private JLabel[] altArray = new JLabel[10];
	private JLabel[] azArray = new JLabel[10];
	private JButton[] gotoArray = new JButton[10];
	
	// The speed is 2 the bytes representation of the tracking rate
	// tracking rate = arcseconds/second * 4
	// example: speed of 1 deg/sec
	//          1deg/sec=3600arcsec/sec.
	//          tracking rate = 3600*4=14400
	//          speed = 0x38 0x40
	// Notation: 1x = 60arcseconds/sec
	private byte[][] speed = {
			{(byte)0x00, (byte) 0xf0}, {(byte) 0x01, (byte) 0xe0}, 
			{(byte) 0x07, (byte) 0x80}, {(byte) 0x0f, (byte) 0x00}, 
			{(byte) 0x1e, (byte) 0x00}, {(byte) 0x38, (byte) 0x40}, 
			{(byte) 0x54, (byte) 0x60}, {(byte) 0x70, (byte) 0x80}, 
			{(byte) 0x8c, (byte) 0xa0}, {(byte) 0xa8, (byte) 0xc0}};
	private String[] speedStrings = {"4x", "16x", "32x", "64x", "128x", 
			"1deg/sec", "1.5deg/sec", "2deg/sec", "2.5deg/sec", "3deg/sec"};
	private JComboBox scanningSpeed = new JComboBox(speedStrings);
	
	/*******************************************************************/
	public CelestronGUI() {
		super("Celestron GUI V0.1");
		setSize(450, 700);
		setResizable(false);
		setDefaultCloseOperation(EXIT_ON_CLOSE);
		
		localizer = new Localizer();
		localizer.connect();
		localizer.addObserver(this);
		
		fmt = new DecimalFormat("#0.00");
		
		JButton start = new JButton("Start");
		start.setToolTipText("Start Localization");
		JButton stop = new JButton("Stop");
		stop.setToolTipText("Stop Localization");
		JButton reset = new JButton("Restart");
		reset.setToolTipText("Restart System");
		JButton query = new JButton("Query");
		query.setToolTipText("Manually Query Nodes");
		JButton setConfig = new JButton("Config");
		setConfig.setToolTipText("Change Node Configuration");
		
		for(int i = 0; i < 10; i++) {
			nodeArray[i] = new JLabel("Node " + (i+1));
			altArray[i] = new JLabel("Alt: __d __' __.__\"");
			azArray[i] = new JLabel("Alt: __d __' __.__\"");
			gotoArray[i] = new JButton("GoTo");
		}
			
			
		thresholdField = new JTextField((new Integer(
				Constants.DEFAULT_THRESHOLD)).toString(), 3);
		deltaField = new JTextField((new Integer(
				Constants.DEFAULT_DELTA)).toString(), 3);
		
		start.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				localizationDuration.setText("0s");
				for(int i = 0; i < 10; i++) {
					altArray[i].setText("Alt: __d __' __.__\"");
					azArray[i].setText("Alt: __d __' __.__\"");
				}
								
				System.out.println("Scanning with speeds:" +
						"index=" + scanningSpeed.getSelectedIndex() + "  " +
						speed[scanningSpeed.getSelectedIndex()][0] +
						"  " + speed[scanningSpeed.getSelectedIndex()][1]);
				localizer.startLocalization(speed[scanningSpeed.getSelectedIndex()]);
			}
		});
		stop.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				System.out.println("STOP TRACKING");
				localizer.stop();
			}
		});
		reset.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				System.out.println("RESTART SYSTEM");
				localizer.restartSystem();
			}
		});
		query.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				System.out.println("QUERY NODES");
				localizer.queryNodes();
			}
		});
		setConfig.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				System.out.println("CONFIG NODES");
				try {
					Integer delta = new Integer(deltaField.getText());
					Byte threshold = new Byte(thresholdField.getText());
					localizer.configNodes(delta.shortValue(), threshold);
				} catch (NumberFormatException e) {
					deltaField.setText(new Integer(
							Constants.DEFAULT_DELTA).toString());
					thresholdField.setText(new Integer(
							Constants.DEFAULT_THRESHOLD).toString());
					System.out.println("Invalid Entry");
				}		
			}
		});		

		GridBagConstraints gbc = new GridBagConstraints();
		gbc.insets = new Insets(10, 10, 10, 10);
		gbc.anchor = GridBagConstraints.FIRST_LINE_START;
		gbc.weightx = 0.8;
        gbc.weighty = 0.8;
        gbc.gridx = 0;
        gbc.gridy = 0;
		

		gotoArray[0].addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				localizer.GoTo(1);
			}
		});
		gotoArray[1].addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				localizer.GoTo(2);
			}
		});
		gotoArray[2].addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				localizer.GoTo(3);
			}
		});
		gotoArray[3].addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				localizer.GoTo(4);
			}
		});
		gotoArray[4].addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				localizer.GoTo(5);
			}
		});
		gotoArray[5].addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				localizer.GoTo(6);
			}
		});
		gotoArray[6].addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				localizer.GoTo(7);
			}
		});
		gotoArray[7].addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				localizer.GoTo(8);
			}
		});
		gotoArray[8].addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				localizer.GoTo(9);
			}
		});
		gotoArray[9].addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent arg0) {
				localizer.GoTo(10);
			}
		});
		
		localizationDuration = new JLabel("__s");
		
		JPanel mainPanel = new JPanel(new GridBagLayout());
		
		//int y = 0;
		for(int i = 0, y = 0; i < 10; i++) {
			gbc.gridx = 0;
	        gbc.gridy = y;
			mainPanel.add(nodeArray[i], gbc);
	        gbc.gridx = 1;
	        gbc.gridy = y;
			mainPanel.add(altArray[i], gbc);
	        gbc.gridx = 2;
	        gbc.gridy = y;
	        mainPanel.add(azArray[i], gbc);
			gbc.gridx = 3;
	        gbc.gridy = y++;        
			mainPanel.add(gotoArray[i], gbc);
		}

        JPanel mountPanel = new JPanel(new GridLayout(3, 2));
        TitledBorder title;
        title = BorderFactory.createTitledBorder("Scan Info");
        mountPanel.setBorder(title);

		mountPanel.add(new JLabel("Duration:   "));
		mountPanel.add(localizationDuration);
		mountPanel.add(new JLabel("Scan Speed:"));
		scanningSpeed.setSelectedIndex(5);
		mountPanel.add(scanningSpeed);

		gbc.gridx = 0;
        gbc.gridy = 10;
        gbc.gridwidth = 2;
		mainPanel.add(mountPanel, gbc);
		
        JPanel configPanel = new JPanel(new GridLayout(2, 1));
        title = BorderFactory.createTitledBorder("Sensor Config");
        configPanel.setBorder(title);
        JPanel configPanelTop = new JPanel(new GridLayout(2, 3));
        configPanelTop.add(new JLabel("Threshold:          "));		
        configPanelTop.add(thresholdField);
        configPanelTop.add(new JLabel("Delta:"));
        configPanelTop.add(deltaField);
        configPanel.add(configPanelTop);
        JPanel configPanelBottom = new JPanel();
		configPanelBottom.add(setConfig);
		configPanel.add(configPanelBottom);
		
		gbc.gridx = 2;
        gbc.gridy = 10;
        gbc.gridwidth = 2;
        mainPanel.add(configPanel, gbc);
				
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.gridwidth = 1;
		setLayout(new GridBagLayout());
		add(mainPanel, gbc);
		
		JPanel southPanel = new JPanel(new GridBagLayout());
		gbc.anchor = GridBagConstraints.SOUTH;
		gbc.gridx = 0;
        gbc.gridy = 0;
        southPanel.add(reset, gbc);
		gbc.gridx = 1;
        gbc.gridy = 0;        
        southPanel.add(start, gbc);
        gbc.gridx = 2;
        gbc.gridy = 0;
		southPanel.add(stop, gbc);		
        gbc.gridx = 3;
        gbc.gridy = 0;
		southPanel.add(query, gbc);
		
        gbc.gridx = 0;
        gbc.gridy = 1;
		add(southPanel, gbc);
		
	}
		
	/*******************************************************************/
	public void update(Observable arg0, Object arg1) {
		List nodesList = (List) arg1;

		localizationDuration.setText(localizer.getLocalizationDuration() + "s");
		
		for(int i = 0; i < nodesList.size(); i++) {
			Node n = (Node) nodesList.get(i);
			
			altArray[n.id-1].setText("Alt: " + n.altDeg() + "d " + n.altMin() +
					"' " + fmt.format(n.altSec()) + "\"");
			azArray[n.id-1].setText("Az: " + n.azDeg() + "d " + n.azMin() +
					"' " + fmt.format(n.azSec()) + "\"");
						
			repaint();
		}
	}

	
	/*******************************************************************/
	public static void main(String[] args) {
		CelestronGUI gui = new CelestronGUI();
		gui.setVisible(true);
	}

}
