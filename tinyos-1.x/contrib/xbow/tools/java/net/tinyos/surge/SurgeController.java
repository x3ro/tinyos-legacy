package net.tinyos.surge;

import java.util.*;
import net.tinyos.util.*;
import net.tinyos.message.*;
import net.tinyos.surge.messages.*;
import java.awt.*;
import java.awt.event.*;
import java.io.*;
import javax.swing.*;
import javax.swing.event.*;


public class SurgeController extends javax.swing.JFrame {

    public static MoteIF moteIF;
    
    private short seqno = 0;

    public SurgeController(int groupID) {

	System.err.println("Starting mote listener...");
	moteIF = new MoteIF(PrintStreamMessenger.err);

	setTitle("SurgeController");

	getContentPane().setLayout(new FlowLayout());
	JButton sendBeepButton = new JButton("Start Beeping");
	getContentPane().add(sendBeepButton);
	
	sendBeepButton.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    System.out.println("Sending Beep Message");

		    sendCommand(7, 0);
		}
	    });


	JButton sendBeepOffButton = new JButton("Stop Beeping");
	getContentPane().add(sendBeepOffButton);
	
	sendBeepOffButton.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    System.out.println("Sending Beep Off Message");
		    
		    sendCommand(8,0);
		}
	    });

	JButton sendPeriod = new JButton("Set Tick Length");
	getContentPane().add(sendPeriod);

	final JTextField periodField = new JTextField("512", 4);
	getContentPane().add(periodField);

	sendPeriod.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    System.out.println("Sending Period: " + periodField.getText());
		    
		    sendCommand(2, Integer.parseInt(periodField.getText()));
		}
	    });


	JButton sendPower = new JButton("Set Power Level");
	getContentPane().add(sendPower);

	final JTextField powerField = new JTextField("15", 4);
	getContentPane().add(powerField);

	sendPower.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    System.out.println("Sending Power: " + powerField.getText());
		    
		    sendCommand(9, Integer.parseInt(powerField.getText()));
		}
	    });


	JButton sendDark = new JButton("Set Darkness Threshhold");
	getContentPane().add(sendDark);

	final JTextField darkField = new JTextField("176", 4);
	getContentPane().add(darkField);

	sendDark.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    System.out.println("Sending Dark: " + darkField.getText());
		    
		    sendCommand(10, Integer.parseInt(darkField.getText()));
		}
	    });


	JButton easyMode = new JButton("Easy Mode");
	getContentPane().add(easyMode);

	easyMode.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    System.out.println("Sending Easy");
		    
		    sendCommand(11, 0);
		}
	    });

	
	JButton hardMode = new JButton("Hard Mode");
	getContentPane().add(hardMode);

	hardMode.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    System.out.println("Sending Hard");
		    
		    sendCommand(12, 0);
		}
	    });

	
	pack();
	setVisible(true);
    }

    public void sendCommand(int type, int value) {

	BcastMsg bc = new BcastMsg(8);
	bc.set_seqno(seqno++);
	
	SurgeCmdMsg cmd = new SurgeCmdMsg(bc, bc.offset_data(0));
	//cmd.set_type((short) type);
	//cmd.set_value((short) value);
	
	try {
	    System.out.println(bc);
	    System.out.println(cmd);
	    moteIF.send(0xffff, bc);
	} catch (java.lang.Exception ex) {
	}
    }

    private static void usage() {
	System.err.println("Usage: java net.tinyos.surge.SurgeController <group_id>");
	System.exit(-1);
    }

    public static void main(String args[]) {
	try {
	    if (args.length != 1) usage();
	    int groupID;
	    if (args[0].startsWith("0x") || args[0].startsWith("0X")) {
		groupID = Integer.parseInt(args[0].substring(2), 16);
	    } else {
		groupID = Integer.parseInt(args[0]);
	    }
	    System.err.println("Using AM group ID "+groupID+" (0x"+Integer.toHexString(groupID)+")");
	    SurgeController sc = new SurgeController(groupID);
	    sc.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
	} catch (Exception e) {
	    System.err.println("main() got exception: "+e);
	    e.printStackTrace();
	    System.exit(-1);
	}
    }

}


