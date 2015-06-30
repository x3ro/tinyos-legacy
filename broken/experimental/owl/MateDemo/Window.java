// $Id: Window.java,v 1.2 2005/01/11 22:37:08 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* This code is horrible. Do not reuse. */

import java.io.*;
import javax.swing.*;
import javax.swing.text.*;
import java.awt.*;
import java.awt.event.*;
import net.tinyos.util.*;

public class Window extends JPanel implements WindowListener, Messenger {
    final static int msize = 20;
    final static int bsize = 16;

    JScrollPane   sourcePanel           = new JScrollPane();
    JEditorPane   sourceArea		= new JEditorPane();
    JPanel	  pnlMain		= new JPanel();
    JScrollPane   mssgPanel             = new JScrollPane();
    JTextArea     mssgArea              = new JTextArea();
    JTextField	  sqlField		= new JTextField();
    JTextField	  motllePCField		= new JTextField();
    JLabel	  sqlLabel		= new JLabel("TinySQL query:");
    JPanel        pnlButtons            = new JPanel();
    JPanel	  sqlPanel		= new JPanel();
    JButton       bGenerate             = new JButton();
    JButton       bExecute              = new JButton();
    JButton       bClear                = new JButton();
    JButton       bQuit                 = new JButton();
    JFrame 	  mainFrame;

    Spawn motlle;

    public Window() {
	try {
	    mainFrame = new JFrame("MateDemo");

	    jbInit();
	    mainFrame.setSize(getPreferredSize());
	    mainFrame.getContentPane().add("Center", this);
	    mainFrame.show();
	    mainFrame.addWindowListener(this);

	    motlle = new Spawn(this);
	    motlle.startMotlle();
	    motlle.exec("load(\"init.mt\")");
	}
	catch(Exception e) {
	    e.printStackTrace();
	    System.exit(2);
	}
    }

    private void jbInit() throws Exception {
	this.setMinimumSize(new Dimension(800, 60));
	this.setPreferredSize(new Dimension(800, 600));
	this.setLayout(new BorderLayout());
	this.add(pnlMain, BorderLayout.CENTER);
	this.add(pnlButtons, BorderLayout.EAST);

	pnlMain.setLayout(new BorderLayout());
	pnlMain.add(sqlPanel, BorderLayout.NORTH);
	JPanel pnlMotlle = new JPanel();
	pnlMotlle.setLayout(new GridLayout(2, 1));
	pnlMotlle.add(sourcePanel);
	pnlMotlle.add(mssgPanel);
	pnlMain.add(pnlMotlle, BorderLayout.CENTER);
	JPanel pnlMotllePC = new JPanel();
	pnlMain.add(pnlMotllePC, BorderLayout.SOUTH);
	pnlMotllePC.setLayout(new BorderLayout());
	pnlMotllePC.add(motllePCField, BorderLayout.CENTER);
        motllePCField.setFont(new java.awt.Font("Dialog", 1, bsize));
	JLabel foo = new JLabel("PC Motlle:");
        foo.setFont(new java.awt.Font("Dialog", 1, bsize));
	pnlMotllePC.add(foo, BorderLayout.WEST);
	
	motllePCField.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    motlle.exec(motllePCField.getText());
		    motllePCField.setText("");
		}
	    });

	sqlPanel.setLayout(new BorderLayout());
	sqlPanel.add(sqlLabel, BorderLayout.WEST);
	sqlPanel.add(sqlField, BorderLayout.CENTER);
        sqlLabel.setFont(new java.awt.Font("Dialog", 1, bsize));
        sqlField.setFont(new java.awt.Font("Dialog", 1, bsize));

	sourceArea.setFont(new java.awt.Font("Monospaced", Font.PLAIN, msize));
	sourcePanel.getViewport().add(sourceArea, null);
	sourcePanel.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED);
	sourcePanel.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
	sourcePanel.setAutoscrolls(true);


	mssgArea.setFont(new java.awt.Font("Monospaced", Font.PLAIN, msize));
	mssgPanel.getViewport().add(mssgArea, null);
	mssgPanel.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
	mssgPanel.setAutoscrolls(true);

	bQuit.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    shutdown();
		}
	    });
        bQuit.setText("Quit");
        bQuit.setFont(new java.awt.Font("Dialog", 1, bsize));

	bClear.addActionListener(new java.awt.event.ActionListener() {
		public synchronized void actionPerformed(ActionEvent e) {
		    mssgArea.setText("");
		}
	    });
        bClear.setText("Clear Output");
        bClear.setFont(new java.awt.Font("Dialog", 1, bsize));

	bExecute.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    exec(sourceArea.getText());
		}
	    });
        bExecute.setText("Execute");
        bExecute.setFont(new java.awt.Font("Dialog", 1, bsize));

	bGenerate.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    sqlGenerate(sqlField.getText());
		}
	    });
        bGenerate.setText("Compile SQL");
        bGenerate.setFont(new java.awt.Font("Dialog", 1, bsize));

	GridLayout gridLayout1 = new GridLayout();
	pnlButtons.setLayout(gridLayout1);
	pnlButtons.setMinimumSize(new Dimension(150, 75));
	pnlButtons.setPreferredSize(new Dimension(150, 75));

	gridLayout1.setRows(13);

	// Main Panel Setup
        pnlButtons.add(bGenerate, null);
        pnlButtons.add(bExecute, null);
	pnlButtons.add(new JLabel(""));
	pnlButtons.add(samplecode("Clear Code", "samples/empty.mt"));
	pnlButtons.add(samplecode("Blink Yellow", "samples/yellowled.mt"));
	pnlButtons.add(samplecode("Count to Leds", "samples/cnttoleds.mt"));
	pnlButtons.add(samplecode("Oscilloscope", "samples/oscilloscope.mt"));
	pnlButtons.add(new JLabel(""));
        pnlButtons.add(bClear, null);
        pnlButtons.add(bQuit, null);

    }

    void error(String s) {
	JOptionPane.showMessageDialog(mainFrame, s + " - exiting");
	System.exit(2);
    }

    String fileToString(String file) {
	try {
	    FileInputStream f = new FileInputStream(file);
	    int size = f.available();
	    byte[] data = new byte[size];
	    f.read(data);
	    
	    return new String(data);
	}
	catch (Exception e) { 
	    error("Couldn't read from " + file);
	    return null;
	}
    }

    void stringToFile(String file, String s) {
	try {
	    PrintStream f = new PrintStream(new FileOutputStream(file));

	    f.print(s);
	    f.close();
	}
	catch (FileNotFoundException e) {
	    error("Couldn't write to " + file);
	}
    }

    JButton samplecode(String name, String file) {
	return makeButton(name, fileToString(file));
    }

    JButton makeButton(String name, final String contents) {
	JButton button = new JButton();
	button.addActionListener(new java.awt.event.ActionListener() {
	    public void actionPerformed(ActionEvent e) {
		sourceArea.setText(contents);
	    }
	 });
        button.setText(name);
        button.setFont(new java.awt.Font("Dialog", 1, bsize));
	    
	return button;
    }

    public synchronized void windowClosing (WindowEvent e) {
	shutdown();
    }

    public void windowClosed      (WindowEvent e) { }
    public void windowActivated   (WindowEvent e) { }
    public void windowIconified   (WindowEvent e) { }
    public void windowDeactivated (WindowEvent e) { }
    public void windowDeiconified (WindowEvent e) { }
    public void windowOpened      (WindowEvent e) { }

    public synchronized void message(String mssg) {
	mssgArea.append(mssg);
	mssgArea.setCaretPosition(mssgArea.getDocument().getLength());
    }

    public static void main(String[] args) {
	Window w = new Window();
    }

    void shutdown() {
	System.exit(0);
    }

    void exec(String s) {
	stringToFile("source", s);
	motlle.exec("moteload(\"source\")");
    }

    void sqlGenerate(String query) {
	stringToFile("query", query);
	try {
	    Process gen = Runtime.getRuntime().exec("./msqlgen");
	    gen.waitFor();
	    String code = fileToString("mquery");
	    if (code.charAt(0) == '/')
		sourceArea.setText(code);
	    else
		JOptionPane.showMessageDialog(mainFrame, code);
	}
	catch (Exception e) {
	    error("SQL generation problem");
	}
    }
}
