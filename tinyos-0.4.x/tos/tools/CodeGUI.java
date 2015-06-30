/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Authors:		Phil Levis
 * Date:        Jul 25 2001
 * Desc:        Top-level class for network programming GUI
 *
 */

import java.awt.*;
import java.io.*;
import javax.comm.*;
import javax.swing.*;

import codeGUI.*;

public class CodeGUI extends JFrame {

    private CodeInjector injector;
    private MotePanel motes;
    private ButtonPanel buttons;
    private LogPanel log;
    private JMenuBar menu;
    
    private Thread injectorThread;
    
    public CodeGUI(byte group) throws Exception {
	super("Malkuth");
	motes = new MotePanel(group);
	log = new LogPanel();
	
	//Create and initialize the CodeInjector
	injector = new CodeInjector(motes, log, "COM1");
	injector.setGroupID(group);
	codeGUI.SerialPortReader spr = injector.getReader();
	spr.Open();
	spr.registerPacketListener(injector);
	injectorThread = new Thread(injector);
	//injectorThread.setDaemon(true);
	injectorThread.setPriority(Thread.MAX_PRIORITY);
	injectorThread.start();
	
	//Create and arrange the sub-panels
	buttons = new ButtonPanel(motes, log, injector);
	
	GridBagLayout bag = new GridBagLayout();
        GridBagConstraints constraints = new GridBagConstraints();
        getContentPane().setLayout(bag);
	
	constraints.gridwidth = GridBagConstraints.REMAINDER;
	constraints.weighty = 0.45;
	bag.setConstraints(motes, constraints);
        constraints.weighty = 0.45;
        bag.setConstraints(log, constraints);
	constraints.weighty = 0.1;
        bag.setConstraints(buttons, constraints);
	
	getContentPane().add(motes);
	getContentPane().add(buttons);
	getContentPane().add(log);

	menu = new CodeGUIMenuBar();
	setJMenuBar(menu);
	
	connectSystemStreams(log);
	
	pack();
	setVisible(true);
	
	Font f = getFont();
	setFont(f.deriveFont((float)6.0));
	
	setSize(getPreferredSize());
    }
	
    private void connectSystemStreams(LogPanel log) {
	try {
	    PipedInputStream input = new PipedInputStream();
	    PrintStream ps = new PrintStream(new PipedOutputStream(input));
	    System.setOut(ps);
	    //System.setErr(ps);
	    
	    Thread readerThread = new ReaderThread(input, log);
	    readerThread.start();
	}
	catch (Exception exception) {}
    }
    
    private class ReaderThread extends Thread {
	private PipedInputStream input;
	private LogPanel log;
	
	public ReaderThread(PipedInputStream input, LogPanel log) {
	    this.log = log;
	    this.input = input;
	}
	
	public void run() {
	    byte[] buffer = new byte[256];
	    
	    try {
		while(true) {
		    int len = input.read(buffer);
		    log.write(buffer, len);
		}
	    }
	    catch (IOException exception) {
		System.err.println("Logging pipe broken:");
		exception.printStackTrace(System.err);
	    }
	}
    }
    
    public static void main(String[] args) {
	try {
	    CodeGUI gui;
	    if (args.length == 0) {
		gui = new CodeGUI((byte)0x13);
	    }
	    else if (args.length == 1) {
		byte val = Byte.valueOf(args[0]).byteValue();
		gui = new CodeGUI(val);
	    }

	    System.out.println("Malkuth: Mote Network Progamming Interface");
	    System.out.println("Please make sure a generic_base mote is plugged in.");
	    Thread.sleep(Integer.MAX_VALUE);
	}
	catch (Exception e) {
	    System.out.println(e);
	    e.printStackTrace();
	}
    }
}
