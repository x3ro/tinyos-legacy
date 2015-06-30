package net.tinyos.tinydb;

import java.util.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import net.tinyos.message.*;

/** Command frame presents a simple UI for sending
    a variety of TinyDB control messages into the
    network.  See CommandMsgs for more info.
    
    @author smadden
*/
public class CmdFrame extends JFrame {
    static final short BCAST_ADDR = (short)-1;
    MoteIF mif;

    public CmdFrame(MoteIF mif) {
	super("Mote Commands");

	this.mif=mif;

	JButton resetButton = new JButton("Reset Motes");
	// JButton useFixedCommButton = new JButton("Fix Communication");
	// JButton unfixCommButton = new JButton("Unfix Communication");
	// JButton useFixedTopoButton = new JButton("Fix Topology");
	// JButton unfixTopoButton = new JButton("Unfix Topology");
	JButton setCommRadiusButton = new JButton("Set Radio Strength");
	JButton stopMagButton = new JButton("Stop Magnetometer");
	JButton chgBaseBcastIntvButton = new JButton("Change Base Bcast Interval");
	JButton sounderOnButton = new JButton("Sounder On");
	JButton addAttrButton = new JButton("Add Attribute");

	getContentPane().setLayout(new GridLayout(6,1));
	getContentPane().add(resetButton);
	// getContentPane().add(useFixedCommButton);
	// getContentPane().add(unfixCommButton);
	// getContentPane().add(useFixedTopoButton);
	// getContentPane().add(unfixTopoButton);
	getContentPane().add(setCommRadiusButton);
	getContentPane().add(stopMagButton);
	getContentPane().add(chgBaseBcastIntvButton);
	getContentPane().add(sounderOnButton);
	getContentPane().add(addAttrButton);

	setSize(255,200);

	resetButton.addActionListener( new ActionListener() {
	    public void actionPerformed(ActionEvent evt) {
		sendMsg(CommandMsgs.resetCmd(BCAST_ADDR));
	    }
	  });

	/*
	useFixedCommButton.addActionListener( new ActionListener() {
	    public void actionPerformed(ActionEvent evt) {
		sendMsg(CommandMsgs.setFixedComm(BCAST_ADDR, true));
	    }
	  });

	unfixCommButton.addActionListener( new ActionListener() {
	    public void actionPerformed(ActionEvent evt) {
		sendMsg(CommandMsgs.setFixedComm(BCAST_ADDR, false));
	    }
	  });

        useFixedTopoButton.addActionListener( new ActionListener() {
	    public void actionPerformed(ActionEvent evt) {
		sendMsg(CommandMsgs.setFanout(BCAST_ADDR, (char)2));
	    }
	  });

	unfixTopoButton.addActionListener( new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
		    sendMsg(CommandMsgs.setFanout(BCAST_ADDR, (char)0xFF));
	    }
	  });
	 */

	setCommRadiusButton.addActionListener( new ActionListener() {
		public void actionPerformed(ActionEvent evt) {     
		    Object[] possibleValues = { new Integer(0), new Integer(10), new Integer(50), new Integer(90), new Integer(100) };
		    Object selectedValue = JOptionPane.showInputDialog(null,
								       "Select signal strength:", "Pot setting:",
								       JOptionPane.INFORMATION_MESSAGE, null,
								       possibleValues, possibleValues[1]);
		    if (selectedValue != null) 
			sendMsg(CommandMsgs.setPot(BCAST_ADDR, (char)((Integer)selectedValue).intValue()));
		}
	    });

	stopMagButton.addActionListener( new ActionListener() {
	    public void actionPerformed(ActionEvent evt) {
		sendMsg(CommandMsgs.stopMagCmd(BCAST_ADDR));
	    }
	  });

	chgBaseBcastIntvButton.addActionListener( new ActionListener() {
		public void actionPerformed(ActionEvent evt) {     
		    Object[] possibleValues = { new Integer(125), new Integer(250), new Integer(500), new Integer(1000), new Integer(1700) };
		    Object selectedValue = JOptionPane.showInputDialog(null,
								       "Select Base Bcast Interval (millisec):", "Current Interval:",
								       JOptionPane.INFORMATION_MESSAGE, null,
								       possibleValues, new Integer(TinyDBNetwork.getBaseBcastInterval()));
		    if (selectedValue != null) 
			        TinyDBNetwork.setBaseBcastInterval(((Integer)selectedValue).intValue());
		}
	    });
	sounderOnButton.addActionListener( new ActionListener() {
		public void actionPerformed(ActionEvent evt) {     
			sendMsg(CommandMsgs.setSounderCmd(BCAST_ADDR));
		}
	    });
	
	addAttrButton.addActionListener( new ActionListener() {
		public void actionPerformed(ActionEvent evt) {
		    doAddAttr();
		}
	    });


    }

    public void doAddAttr() {
	AddAttrPanel p = new AddAttrPanel(this);
	Message m = p.askForCommand();
	if (m != null)
	    sendMsg(m);
    }

    public void sendMsg(Message msg) {
	try {
	    System.out.print(msg);
	    System.out.println("");
	    mif.send( (short)-1,msg);
	} catch (Exception e) {
	    System.out.println("Error sending message.");
	    e.printStackTrace();
	}
    }

}