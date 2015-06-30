/* "Copyright (c) 2001 and The Regents of the University  
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
* Authors:   Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created 7/22/2001 
* Authors:   Wei Hong, modified for tinydb
*/

package net.tinyos.tinydb.topology;

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import net.tinyos.tinydb.*;
import net.tinyos.tinydb.topology.GraphDisplayPanel;
import net.tinyos.tinydb.topology.Dialog.*;
import net.tinyos.tinydb.topology.PacketAnalyzer.*;
import net.tinyos.tinydb.topology.Packet.*;
import net.tinyos.amhandler.*;

              //This class has been created completely by visualCafe, and essentially
              //holds all the GUI information.
/**
 * A basic JFC 1.1 based application.
 */
public class MainFrame extends javax.swing.JFrame  
{
    TinyDBNetwork nw = null;

	public MainFrame()
	{
		// setDefaultCloseOperation(javax.swing.WindowConstants.DISPOSE_ON_CLOSE);
		QueryFrame.topologyWindowUp = true;
		setTitle("Sensor Network Topology");
		getContentPane().setLayout(new BorderLayout(0,0));
		setSize(700,500);
		setVisible(false);
		MainPanel.setLayout(new FlowLayout(FlowLayout.LEFT,0,0));
		getContentPane().add(BorderLayout.NORTH, MainPanel);
		MainToolBar.setAlignmentY(0.222222F);
		MainToolBar.setDoubleBuffered(true);
		MainPanel.add(MainToolBar);
		SymWindow aSymWindow = new SymWindow();
		this.addWindowListener(aSymWindow);
		SymAction lSymAction = new SymAction();
		fitNetworkNowButton.addActionListener(lSymAction);
		fitNetworkNowButton.setToolTipText("Fit Network to Screen");
		MainToolBar.add(fitNetworkNowButton);
		vizLightButton.addActionListener(lSymAction);
		vizLightButton.setToolTipText("Visualize Light Readings");
		MainToolBar.add(vizLightButton);
		vizTempButton.addActionListener(lSymAction);
		vizTempButton.setToolTipText("Visualize Temperature Readings");
		MainToolBar.add(vizTempButton);
		vizVoltageButton.addActionListener(lSymAction);
		vizVoltageButton.setToolTipText("Visualize Voltage Readings");
		MainToolBar.add(vizVoltageButton);
		stopQueryButton.addActionListener(lSymAction);
		stopQueryButton.setToolTipText("Stop Query");
		MainToolBar.add(stopQueryButton);
		resendQueryButton.addActionListener(lSymAction);
		resendQueryButton.setToolTipText("Resend Query");
		MainToolBar.add(resendQueryButton);
		readingTypeLabel.setText("      Light Reading");
		readingTypeLabel.setToolTipText("This is the current reading type");
		MainToolBar.add(readingTypeLabel);
		getContentPane().add(BorderLayout.CENTER, MainScrollPane);
		MainScrollPane.setOpaque(true);
		MainScrollPane.setViewportView(GraphDisplayPanel);		
		MainScrollPane.getViewport().add(GraphDisplayPanel);
		GraphDisplayPanel.setBounds(0,0,430,270);
		GraphDisplayPanel.setLayout(null);
		GraphDisplayPanel.setAutoscrolls(true);
		//GraphDisplayPanel.setBounds(0,0,100,100);
		//GraphDisplayPanel.setPreferredSize(new Dimension(100,100));
		MainScrollPane.getViewport().add(GraphDisplayPanel);
	}

    /**
     * Creates a new instance of JFrame1 with the given title.
     * @param sTitle the title for the new frame.
     * @see #JFrame1()
     */
	public MainFrame(String sTitle, TinyDBNetwork nw)
	{
		this();
		setTitle(sTitle);
		this.nw = nw;
	}
	
    /**
     * Notifies this component that it has been added to a container
     * This method should be called by <code>Container.add</code>, and 
     * not by user code directly.
     * Overridden here to adjust the size of the frame if needed.
     * @see java.awt.Container#removeNotify
     */
     
	public void addNotify()
	{
		// Record the size of the window prior to calling parents addNotify.
		Dimension size = getSize();
		
		super.addNotify();
		
		if (frameSizeAdjusted)
			return;
		frameSizeAdjusted = true;
		
		// Adjust size of frame according to the insets and menu bar
		javax.swing.JMenuBar menuBar = getRootPane().getJMenuBar();
		int menuBarHeight = 0;
		if (menuBar != null)
		    menuBarHeight = menuBar.getPreferredSize().height;
		Insets insets = getInsets();
		setSize(insets.left + insets.right + size.width, insets.top + insets.bottom + size.height + menuBarHeight);
	}

	// Used by addNotify
	boolean frameSizeAdjusted = false;

	javax.swing.JPanel MainPanel = new javax.swing.JPanel();
	javax.swing.JToolBar MainToolBar = new javax.swing.JToolBar();
	javax.swing.JScrollPane MainScrollPane = new javax.swing.JScrollPane();
	net.tinyos.tinydb.topology.GraphDisplayPanel GraphDisplayPanel = new net.tinyos.tinydb.topology.GraphDisplayPanel();
	JButton fitNetworkNowButton = new JButton("Fit Network");
	JButton vizLightButton = new JButton("Light");
	JButton vizTempButton = new JButton("Temperature");
	JButton vizVoltageButton = new JButton("Voltage");
	JButton stopQueryButton = new JButton("Stop Query");
	JButton resendQueryButton = new JButton("Resend Query");
	javax.swing.JLabel readingTypeLabel = new javax.swing.JLabel();

	class SymWindow extends java.awt.event.WindowAdapter
	{
		public void windowClosing(java.awt.event.WindowEvent event)
		{
			Object object = event.getSource();
			if (object == MainFrame.this)
				MainFrame_windowClosing(event);
		}
	}

	void MainFrame_windowClosing(java.awt.event.WindowEvent event)
	{
		QueryFrame.topologyWindowUp = false;
		MainClass.displayManager.stopDisplayThread();
		try {
			nw.abortQuery(MainClass.topologyQuery);
			TinyDBMain.notifyRemovedQuery(MainClass.topologyQuery);
		} catch (Exception e) {
		}
	}

	class SymAction implements java.awt.event.ActionListener
	{
		public void actionPerformed(java.awt.event.ActionEvent event)
		{
			Object object = event.getSource();
			if (object == fitNetworkNowButton)
				fitNetworkNowMenuItem_action(event);
			else if (object == vizLightButton)
				displayLightMenuItem_action(event);
			else if (object == vizTempButton)
				displayTempMenuItem_action(event);
			else if (object == vizVoltageButton)
				displayVoltageMenuItem_action(event);
			else if (object == stopQueryButton)
			{
				MainClass.topologyQueryRunning = false;
				try {
					nw.abortQuery(MainClass.topologyQuery);
				} catch (Exception e) {
				}
			}
			else if (object == resendQueryButton)
			{
				nw.sendQuery(MainClass.topologyQuery);
				MainClass.topologyQueryRunning = true;
			}
		}
	}

	public net.tinyos.tinydb.topology.GraphDisplayPanel GetGraphDisplayPanel()
	{
		return GraphDisplayPanel;
	}

	public javax.swing.JScrollPane GetMainScrollPane()
	{
		return MainScrollPane;
	} 

	void displayLightMenuItem_action(java.awt.event.ActionEvent event)
	{
		Packet.setCurrentValueIdx(Packet.LIGHT_IDX);
		readingTypeLabel.setText("      Light Reading");
	}

	void displayTempMenuItem_action(java.awt.event.ActionEvent event)
	{
		Packet.setCurrentValueIdx(Packet.TEMP_IDX);
		readingTypeLabel.setText("      Temperature Reading");
	}

	void displayVoltageMenuItem_action(java.awt.event.ActionEvent event)
	{
		Packet.setCurrentValueIdx(Packet.VOLTAGE_IDX);
		readingTypeLabel.setText("      Voltage Reading");
	}

	void fitNetworkNowMenuItem_action(java.awt.event.ActionEvent event)
	{
		try {
			net.tinyos.tinydb.topology.MainClass.mainFrame.GetGraphDisplayPanel().FitToScreen();
		} catch (java.lang.Exception e) {
		}
	}

}
