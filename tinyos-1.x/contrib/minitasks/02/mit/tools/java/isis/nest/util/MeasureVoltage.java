/*
 * Copyright (c) 2003, Vanderbilt University
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
 */
/*									tab:4
 *  MeasureVoltage.java - Java application for visualizing battery voltage
 *
 *  Authors:  Peter Volgyesi, Gabor Pap
 *  Date:     03/21/2002
 *
 *  TODO: use only last n samples
 *
 */
package isis.nest.util;

import java.util.*;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

import net.tinyos.util.*;

/** 
 *  MeasureVoltage class is the main application class for the
 *  battery tester application. Its main method
 *  creates a top level (BatteryFrame) window.
 *  @author Peter Volgyesi
 *  @author ISIS, Vanderbilt University
 *  @see BatteryFrame
 *
 */
public class MeasureVoltage {

	static BatteryFrame bframe;
	
	public static void main(String[] args) {
		if (!process_command_line(args)) {
			usage();
			return;
		}
		bframe = new BatteryFrame();	
		bframe.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		bframe.setVisible(true);
		bframe.start();
	}
	
	protected static void usage() {
		String usage_msg = "\n" +
		"Usage: java MeasureVoltage [OPTION]...\n" +
		"\n" +
		"  Options:\n" +
		"\n" +
		"       -help                 print this help message.\n" +
		"       -minval INT           set the digital value of the minimum voltage.\n" +
		"       -maxval INT           set the digital value of the maximum voltage.\n" +
		"       -minvoltage DOUBLE    set the minimum displayed voltage.\n" +
		"       -maxvoltage DOUBLE    set the maximum displayed voltage.\n" +
		"       -lowvoltage DOUBLE    set the critical battery voltage (in volts).\n" +
		"       -normvoltage DOUBLE   set the minimum normal battery voltage (in volts).\n" +
		"       -serialport STRING    the name of the serial port to be used.\n" +
		"       -width INT            the width of the main window (in pixels).\n" +
		"       -height INT           the height of the main window (in pixels).\n" +
		"";
		System.out.println(usage_msg);
	}
	
	protected static boolean process_command_line(String[] args) {
		
		try {
			for (int i = 0; i < args.length; i++) {
				String arg = args[i];
				
				if (arg.compareTo("-help") == 0) {
					return false;
				}
				else if (arg.compareTo("-minval") == 0) {
					MIN_VAL = Integer.parseInt(args[++i]);
				}
				else if (arg.compareTo("-maxval") == 0) {
					MAX_VAL = Integer.parseInt(args[++i]);
				}
				else if (arg.compareTo("-minvoltage") == 0) {
					MIN_VOLTAGE = Double.parseDouble(args[++i]);
				}
				else if (arg.compareTo("-maxvoltage") == 0) {
					MAX_VOLTAGE = Double.parseDouble(args[++i]);
				}
				else if (arg.compareTo("-lowvoltage") == 0) {
					LOW_VOLTAGE = Double.parseDouble(args[++i]);
				}
				else if (arg.compareTo("-normvoltage") == 0) {
					NORM_VOLTAGE = Double.parseDouble(args[++i]);
				}
				else if (arg.compareTo("-serialport") == 0) {
					SERIALPORT_NAME = args[++i];
				}
				else if (arg.compareTo("-width") == 0) {
					TRACKING_DEFAULT_WIDTH = Integer.parseInt(args[++i]);
				}
				else if (arg.compareTo("-height") == 0) {
					TRACKING_DEFAULT_HEIGHT = Integer.parseInt(args[++i]);
				}
				else {
					return false;
				}
			} 
		}
		catch (NumberFormatException e) {
			System.err.println(e.toString());
			return false;
		}
		catch (ArrayIndexOutOfBoundsException e) {
			System.err.println(e.toString());
			return false;
		}
		SCALE_VAL = (MAX_VOLTAGE - MIN_VOLTAGE) / (MAX_VAL - MIN_VAL);
		return true;
	}
		
	// Configuration parameters
	static int    MIN_VAL = 0;
	static int    MAX_VAL = 1024; // Comment: it was 1024, but it seems to work with 256
	static double MIN_VOLTAGE = 0.0;
	static double MAX_VOLTAGE = 3.034;
	static double LOW_VOLTAGE = 1.6;  // Duracell: 2 x 0.8 cut-off voltage
	static double NORM_VOLTAGE = 2.3; //
	static double SCALE_VAL;
	
	static String SERIALPORT_NAME = "COM1";
	
	static int    TRACKING_DEFAULT_WIDTH = 800;
	static int    TRACKING_DEFAULT_HEIGHT = 600;
}


// ========================================================================
//  Inner classes
// ========================================================================

/**
 *  GraphPanel is the main area of the application window. It shows the
 *  nodes, connections, handles mouse events (dragging) and collects
 *  data from the router network through the Serial Port (in a separate thread).
 *  @author Peter Volgyesi
 *  @author ISIS, Vanderbilt University
 *  @see BatteryFrame
 *  @see PacketListenerIF
 *  @see SerialPortStub
 *
 */
class GraphPanel extends javax.swing.JPanel	implements Runnable, PacketListenerIF {
		
	static final Color tickColor = Color.black;
	static final Color criticalColor = Color.red;
	static final Color lowColor = Color.yellow;
	static final Color normColor = Color.green;
	
	static final int MIN_DEG = 30;
	static final int MAX_DEG = 150;
	static final int BUFFER_SIZE = 6;
	
	/** Reference to the parent frame window */
	BatteryFrame bframe;
	Thread msg_processor;
	
	/** Calculated mean voltage value */
	double mean_voltage = 0.0;
	CircularBuffer buffer = new CircularBuffer(BUFFER_SIZE);
	int numberOfSamples = 0;
	int sumOfSamples = 0;
	
	/** Offscreen buffer for the tester background */
	Image offscreen;
    Dimension offscreensize;
    Graphics2D offgraphics;
	
	GraphPanel(BatteryFrame bframe) {
		this.bframe = bframe;
	}
	
	/** run() is called when the message processing thread has been started. 
	 *  It creates a SerialPortStub object, registers itself as a packer
	 *  listener and call the read() method of the port reader, which never 
	 *  returns.
	 *  @see SerialPortStub
	 *  @see PacketListenerIF
	 */
	public void	run() {
		SerialPortStub sp = new SerialPortStub(MeasureVoltage.SERIALPORT_NAME);
		try {
			sp.Open();
			sp.registerPacketListener(this);
			sp.Read();
		} 
		catch(Exception e) {
			bframe.DisplayMsg("Unable to open serial port: " + e.toString());
			e.printStackTrace();
		}
	}

    /** packetReceived() is called by the SerialPortStub object. After
     *  the message processing we force the update of the screen.
     */
	synchronized public void packetReceived(byte[] packet) {
		int sample_value;
		
		sample_value = packet[6] << 8;
		sample_value |= packet[5] & 0xff;
		
		System.out.println("Sample_value: "+sample_value);
		
		sample_value = Math.max(sample_value, MeasureVoltage.MIN_VAL);
		sample_value = Math.min(sample_value, MeasureVoltage.MAX_VAL);
		
		sumOfSamples += sample_value;
		if (numberOfSamples != BUFFER_SIZE){
			numberOfSamples++;
		}
		Integer newInt = new Integer(sample_value);
		Integer oldInt = (Integer)buffer.insert(newInt);
		if (oldInt != null){
			sumOfSamples -= oldInt.intValue();
		}
		mean_voltage = (sumOfSamples/numberOfSamples * MeasureVoltage.SCALE_VAL) + MeasureVoltage.MIN_VOLTAGE;
		
	    bframe.DisplayVoltage(mean_voltage);
	    repaint();
	}

	/** paintStick will draw the stick (staff) on the tester based on the mean voltage
	 */
	public void	paintStick(Graphics g, int tc_x, int tc_y, int rad) {
		
		g.setColor(tickColor);
		// TODO: draw the stick
		rad = (15 * rad) / 14;
		double scale_deg = (MAX_DEG - MIN_DEG) / (MeasureVoltage.MAX_VOLTAGE - MeasureVoltage.MIN_VOLTAGE);
		int stick_deg = MIN_DEG + (int)(scale_deg * mean_voltage);
		int x = tc_x - (int)(Math.cos(Math.toRadians(stick_deg)) * rad);
		int y = tc_y - (int)(Math.sin(Math.toRadians(stick_deg)) * rad);
		g.drawLine(tc_x, tc_y, x, y);
		// g.fillArc(tc_x - rad, tc_y - rad, 2 * rad, 2 * rad, 180 - stick_deg , 1);
	}
	
	/** repainting method, it copies the tester background from an offscreen buffer
	 *  and repaints the staff.
	 *  It uses antialiasing and quality rendering.
	 *
	 */
	public synchronized	void paintComponent(Graphics g)	{
		super.paintComponent(g); //paint background - do we need this ???

		Graphics2D g2 = (Graphics2D) g;		
		g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                            RenderingHints.VALUE_ANTIALIAS_ON);
        g2.setRenderingHint(RenderingHints.KEY_RENDERING,
                            RenderingHints.VALUE_RENDER_QUALITY);

		// Create offscreen buffer on-demand
		Dimension d = getSize();
		int tc_x = d.width / 2;
		int tc_y = (d.height * 3) / 4;
		int rad = Math.min(d.width, d.height) / 2;
		
		if ((offscreen == null) || (d.width != offscreensize.width) || (d.height != offscreensize.height)) {
		    offscreen = createImage(d.width, d.height);
		    offscreensize = d;
		    if (offgraphics != null) {
		        offgraphics.dispose();
		    }
		    offgraphics = (Graphics2D) offscreen.getGraphics();
		    
		    double scale_deg = (MAX_DEG - MIN_DEG) / (MeasureVoltage.MAX_VOLTAGE - MeasureVoltage.MIN_VOLTAGE);
		    int crit_deg = (int)(MeasureVoltage.LOW_VOLTAGE * scale_deg);
		    int low_deg = (int)(MeasureVoltage.NORM_VOLTAGE * scale_deg) - crit_deg;
		    int norm_deg = (MAX_DEG - MIN_DEG) - (low_deg + crit_deg);
		    
		    offgraphics.setColor(criticalColor);
		    offgraphics.fillArc(tc_x - rad, tc_y - rad, 2 * rad, 2 * rad, 180 - MIN_DEG, -crit_deg);

		    offgraphics.setColor(lowColor);
		    offgraphics.fillArc(tc_x - rad, tc_y - rad, 2 * rad, 2 * rad, 180 - (MIN_DEG + crit_deg), -low_deg);
		    
		    offgraphics.setColor(normColor);
		    offgraphics.fillArc(tc_x- rad, tc_y - rad, 2 * rad, 2 * rad, 180 - (MIN_DEG + crit_deg + low_deg), -norm_deg);
		    
		    int inrad = (8 * rad) / 10;
		    offgraphics.setColor(getBackground());
		    offgraphics.fillArc(tc_x- inrad, tc_y - inrad, 2 * inrad, 2 * inrad, 180 - MIN_DEG, (MIN_DEG - MAX_DEG));
		    
		    //TODO: finish the tester background (make it fancy...)
		    
		}
	
		// Copy the background
		g2.drawImage(offscreen, 0, 0, null);
		
		
		paintStick(g2, tc_x, tc_y, rad);
	}

	

	/** start method starts a new thread for message processing */
	public void	start()	{	
		msg_processor = new Thread(this);
		msg_processor.start();
	}

}

/**
 *  BatteryFrame is the top level window of the battery tester application.
 *  It creates an area for the tester on the top, and a small area for
 *  some controls on the bottom side of the top level window.
 *  It handles all the events of the controls.
 *  @author Peter Volgyesi
 *  @author ISIS, Vanderbilt University
 *  @see GraphPanel
 *
 */
class BatteryFrame extends JFrame implements ActionListener {
		
	public GraphPanel gpanel;
	JPanel controlPanel;
	 
	/** Clear all previous measured data from the application */ 
	JButton b_clear;
	
	/** Label for status messages */
	JLabel l_status;
	
	/** The constructor creates the GraphPanel for the tester and
	 *  the panel for the controls.
	 */
	public BatteryFrame() {
		super("Battery Tester");
		b_clear = new JButton("Re-Test");
		l_status = new JLabel("Connecting...");
		
		setSize(MeasureVoltage.TRACKING_DEFAULT_WIDTH, MeasureVoltage.TRACKING_DEFAULT_HEIGHT);
		getContentPane().setLayout(new BorderLayout());
		
		gpanel = new GraphPanel(this);
		getContentPane().add("Center", gpanel);
		controlPanel = new JPanel();
		getContentPane().add("South", controlPanel);
		
		controlPanel.add(b_clear);	b_clear.addActionListener(this);
		controlPanel.add(l_status);
	}
	
	/** Button handler */
	public void	actionPerformed(ActionEvent	e) {
		Object src = e.getSource();

		if (src	== b_clear) {
			gpanel.mean_voltage = 0.0;
			gpanel.buffer = new CircularBuffer(gpanel.BUFFER_SIZE);
			gpanel.numberOfSamples = 0;
			gpanel.sumOfSamples = 0;
			gpanel.repaint();
			return;
		}
	}
	
	public void	start()	{
		gpanel.start();
	}
	
	/** Display received message counter in the status area */
	public void DisplayVoltage(double voltage) {
		double tvoltage = ((int)(voltage * 100)) / 100.0;
		String msg = "Battery: " + String.valueOf(tvoltage) + " V";
		DisplayMsg(msg);
	}
	
	/** Display message in the status area */
	public void DisplayMsg(String msg) {
		l_status.setText(msg);
	}
}

