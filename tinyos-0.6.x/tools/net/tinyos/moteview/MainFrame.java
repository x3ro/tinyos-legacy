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
*/

package net.tinyos.moteview;

import java.util.*;
import java.net.URL;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import net.tinyos.moteview.GraphDisplayPanel;
import net.tinyos.moteview.Dialog.*;
import net.tinyos.moteview.PacketRecievers.*;
import net.tinyos.moteview.PacketAnalyzers.*;


/**
 * A basic JFC 1.1 based application.
 */
public class MainFrame extends javax.swing.JFrame //implements java.io.Serializable
{
	public MainFrame()
	{
		//{{INIT_CONTROLS
		setDefaultCloseOperation(javax.swing.JFrame.DO_NOTHING_ON_CLOSE);
		setJMenuBar(MainMenuBar);
		getContentPane().setLayout(new BorderLayout(0,0));
		setSize(700,500);
		setVisible(false);

                // initialize icons
                newIcon = new ImageIcon("net/tinyos/moteview/images/new.gif");
		openIcon = new ImageIcon("net/tinyos/moteview/images/open.gif");
		saveIcon = new ImageIcon("net/tinyos/moteview/images/save.gif");
		cutIcon = new ImageIcon("net/tinyos/moteview/images/cut.gif");
		copyIcon = new ImageIcon("net/tinyos/moteview/images/copy.gif");
		pasteIcon = new ImageIcon("net/tinyos/moteview/images/paste.gif");
		aboutIcon = new ImageIcon("net/tinyos/moteview/images/about.gif");
		selectIcon = new ImageIcon("net/tinyos/moteview/images/palette_select.gif");
		handIcon = new ImageIcon("net/tinyos/moteview/images/palette_hand.gif");
		zoomIcon = new ImageIcon("net/tinyos/moteview/images/palette_zoom.gif");
		fitIcon = new ImageIcon("net/tinyos/moteview/images/palette_magnify.gif");

                saveFileDialog.setMode(FileDialog.SAVE);
		saveFileDialog.setTitle("Save");
		//$$ saveFileDialog.move(24,336);
		openFileDialog.setMode(FileDialog.LOAD);
		openFileDialog.setTitle("Open");
		//$$ openFileDialog.move(0,336);
		MainPanel.setLayout(new FlowLayout(FlowLayout.LEFT,0,0));
		getContentPane().add(BorderLayout.NORTH, MainPanel);
		MainToolBar.setAlignmentY(0.222222F);
//		MainToolBar.setDoubleBuffered(true);
		MainPanel.add(MainToolBar);
		newButton.setDefaultCapable(false);
		newButton.setToolTipText("Create a new document");
		newButton.setMnemonic((int)'N');
		MainToolBar.add(newButton);
		openButton.setDefaultCapable(false);
		openButton.setToolTipText("Open an existing document");
		openButton.setMnemonic((int)'O');
		MainToolBar.add(openButton);
		saveButton.setDefaultCapable(false);
		saveButton.setToolTipText("Save the active document");
		saveButton.setMnemonic((int)'S');
		MainToolBar.add(saveButton);
		MainToolBar.addSeparator();
                //MainToolBar.add(JToolBarSeparator1);
		cutButton.setDefaultCapable(false);
		cutButton.setToolTipText("Cut the selection and put it on the Clipboard");
		cutButton.setMnemonic((int)'T');
		MainToolBar.add(cutButton);
		copyButton.setDefaultCapable(false);
		copyButton.setToolTipText("Copy the selection and put it on the Clipboard");
		copyButton.setMnemonic((int)'C');
		MainToolBar.add(copyButton);
		pasteButton.setDefaultCapable(false);
		pasteButton.setToolTipText("Insert Clipboard contents");
		pasteButton.setMnemonic((int)'P');
		MainToolBar.add(pasteButton);
                MainToolBar.addSeparator();
		//MainToolBar.add(JToolBarSeparator2);
		aboutButton.setDefaultCapable(false);
		aboutButton.setToolTipText("Display program information, version number and copyright");
		aboutButton.setMnemonic((int)'A');
		MainToolBar.add(aboutButton);
                MainToolBar.addSeparator();
		//MainToolBar.add(JToolBarSeparator3);
		selectButton.setSelected(true);
		selectButton.setToolTipText("Use this to select and move nodes");
		selectButton.setMnemonic((int)'P');
		MainToolBar.add(selectButton);
		handButton.setToolTipText("Use this to scroll with the left mouse button");
		handButton.setMnemonic((int)'H');
		MainToolBar.add(handButton);
		zoomButton.setToolTipText("Use this to select a region and zoom with the left mouse button");
		zoomButton.setMnemonic((int)'Z');
		MainToolBar.add(zoomButton);
//		dragButtonGroup.add(selectButton);
//		dragButtonGroup.add(handButton);
//		dragButtonGroup.add(zoomButton);
//		dragButtonGroup.setSelected(selectButton, true);
                MainToolBar.addSeparator();
		//MainToolBar.add(JToolBarSeparator4);
		fitButton.setDefaultCapable(false);
		fitButton.setToolTipText("Fit all nodes onto the screen");
		fitButton.setMnemonic((int)'F');
		MainToolBar.add(fitButton);
                MainToolBar.addSeparator();
		//MainToolBar.add(JToolBarSeparator5);
		JSlider1.setMinimum(1);
		JSlider1.setMaximum(5);
		JSlider1.setToolTipText("Slide this to zoom");
		//JSlider1.setBorder(bevelBorder1);
		JSlider1.setValue(1);
		MainToolBar.add(JSlider1);
		//$$ bevelBorder1.move(0,115);
		JLabel3.setText("1.0");
		JLabel3.setToolTipText("This is the current zoom level");
		MainToolBar.add(JLabel3);
		JLabel3.setFont(new Font("Dialog", Font.BOLD, 16));
                MainToolBar.addSeparator();
		//MainToolBar.add(JToolBarSeparator6);
                JLabel4.setText("jlabel");
		JLabel4.setToolTipText("This is the current mouse position");
		MainToolBar.add(JLabel4);
		JLabel4.setSize(51,27);

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
		//$$ MainMenuBar.move(168,312);
		fileMenu.setText("File");
		fileMenu.setActionCommand("File");
		fileMenu.setMnemonic((int)'F');
		MainMenuBar.add(fileMenu);
		newItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_N, java.awt.Event.CTRL_MASK));
		newItem.setText("New");
		newItem.setActionCommand("New");
		newItem.setMnemonic((int)'N');
		fileMenu.add(newItem);
		openItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_O, java.awt.Event.CTRL_MASK));
		openItem.setText("Open...");
		openItem.setActionCommand("Open...");
		openItem.setMnemonic((int)'O');
		fileMenu.add(openItem);
		saveItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_S, java.awt.Event.CTRL_MASK));
		saveItem.setText("Save");
		saveItem.setActionCommand("Save");
		saveItem.setMnemonic((int)'S');
		fileMenu.add(saveItem);
		saveAsItem.setText("Save As...");
		saveAsItem.setActionCommand("Save As...");
		saveAsItem.setMnemonic((int)'A');
		fileMenu.add(saveAsItem);
		fileMenu.add(JSeparator1);
		exitItem.setText("Exit");
		exitItem.setActionCommand("Exit");
		exitItem.setMnemonic((int)'X');
		fileMenu.add(exitItem);
		editMenu.setText("Edit");
		editMenu.setActionCommand("Edit");
		editMenu.setMnemonic((int)'E');
		MainMenuBar.add(editMenu);
		JMenuItem2.setText("Surge Options");
		editMenu.add(JMenuItem2);
		editMenu.add(JSeparator2);
		cutItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_X, java.awt.Event.CTRL_MASK));
		cutItem.setText("Cut");
		cutItem.setActionCommand("Cut");
		cutItem.setMnemonic((int)'T');
		editMenu.add(cutItem);
		copyItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_C, java.awt.Event.CTRL_MASK));
		copyItem.setText("Copy");
		copyItem.setActionCommand("Copy");
		copyItem.setMnemonic((int)'C');
		editMenu.add(copyItem);
		pasteItem.setAccelerator(javax.swing.KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_V, java.awt.Event.CTRL_MASK));
		pasteItem.setText("Paste");
		pasteItem.setActionCommand("Paste");
		pasteItem.setMnemonic((int)'P');
		editMenu.add(pasteItem);
		DisplayMenu.setText("Display");
		DisplayMenu.setActionCommand("Display");
		MainMenuBar.add(DisplayMenu);
		JCheckBoxMenuItem8.setSelected(true);
		JCheckBoxMenuItem8.setToolTipText("Always keep the entire network visible (may cause jumping)");
		JCheckBoxMenuItem8.setText("Fit Network to Screen Automatically");
		JCheckBoxMenuItem8.setActionCommand("Fit Network to Screen Automatically");
		DisplayMenu.add(JCheckBoxMenuItem8);
		JMenuItem7.setText("Fit Network to Screen Now");
		JMenuItem7.setActionCommand("Fit Network to Screen");
		DisplayMenu.add(JMenuItem7);
		DisplayMenu.add(JSeparator4);
		JCheckBoxMenuItem7.setSelected(true);
		JCheckBoxMenuItem7.setToolTipText("Refreshing the screen slows processing significantly.  Use \"Refresh Screen Now\" to refresh manually.");
		JCheckBoxMenuItem7.setText("Refresh Screen Automatically");
		JCheckBoxMenuItem7.setActionCommand("Refresh Screen Automatically");
		DisplayMenu.add(JCheckBoxMenuItem7);
		JMenuItem8.setToolTipText("Use this to refresh the screen manually");
		JMenuItem8.setText("Refresh Screen Now");
		JMenuItem8.setActionCommand("Refresh Screen Now");
		DisplayMenu.add(JMenuItem8);
		PacketReadersMenu.setText("Packet Readers");
		PacketReadersMenu.setActionCommand("Packet Readers");
		MainMenuBar.add(PacketReadersMenu);
		PacketAnalyzersMenu.setText("Packet Analyzers");
		PacketAnalyzersMenu.setActionCommand("Packet Analyzers");
		MainMenuBar.add(PacketAnalyzersMenu);
		/*JMenu1.setText("Actions");
		JMenu1.setActionCommand("Actions");
		MainMenuBar.add(JMenu1);
		JMenuItem5.setText("Inject Packet");
		JMenuItem5.setActionCommand("Inject Packet");
		JMenu1.add(JMenuItem5);
		JMenu1.add(JSeparator13);
		JMenuItem6.setText("Set Transmission Strength");
		JMenuItem6.setActionCommand("Set Transmission Strength");
		JMenu1.add(JMenuItem6);*/
		helpMenu.setText("Help");
		helpMenu.setActionCommand("Help");
		helpMenu.setMnemonic((int)'H');
		MainMenuBar.add(helpMenu);
		aboutItem.setText("About...");
		aboutItem.setActionCommand("About...");
		aboutItem.setMnemonic((int)'A');
		helpMenu.add(aboutItem);
		//$$ JMenuBar1.move(168,312);
		saveButton.setIcon(saveIcon);
		newButton.setIcon(newIcon);
		cutItem.setIcon(cutIcon);
		newItem.setIcon(newIcon);
		openButton.setIcon(openIcon);
		openItem.setIcon(openIcon);
		aboutButton.setIcon(aboutIcon);
		selectButton.setIcon(selectIcon);
		handButton.setIcon(handIcon);
		zoomButton.setIcon(zoomIcon);
		fitButton.setIcon(fitIcon);
		pasteButton.setIcon(pasteIcon);
		saveItem.setIcon(saveIcon);
		pasteItem.setIcon(pasteIcon);
		copyItem.setIcon(copyIcon);
		cutButton.setIcon(cutIcon);
		copyButton.setIcon(copyIcon);
		aboutItem.setIcon(aboutIcon);
		//}}

		//{{INIT_MENUS
		//}}

		//{{REGISTER_LISTENERS
		SymWindow aSymWindow = new SymWindow();
		this.addWindowListener(aSymWindow);
		SymAction lSymAction = new SymAction();
		openItem.addActionListener(lSymAction);
		saveItem.addActionListener(lSymAction);
		exitItem.addActionListener(lSymAction);
		aboutItem.addActionListener(lSymAction);
		openButton.addActionListener(lSymAction);
		saveButton.addActionListener(lSymAction);
		aboutButton.addActionListener(lSymAction);
		selectButton.addActionListener(lSymAction);
		handButton.addActionListener(lSymAction);
		zoomButton.addActionListener(lSymAction);
		fitButton.addActionListener(lSymAction);
	//	SymFocus aSymFocus = new SymFocus();
	//	MainMenuBar.addFocusListener(aSymFocus);
		JMenuItem7.addActionListener(lSymAction);
		SymItem lSymItem = new SymItem();
		JCheckBoxMenuItem7.addItemListener(lSymItem);
		JMenuItem8.addActionListener(lSymAction);
		JCheckBoxMenuItem8.addItemListener(lSymItem);
		SymChange lSymChange = new SymChange();
		JSlider1.addChangeListener(lSymChange);
		JMenuItem2.addActionListener(lSymAction);
		//}}

                //JLabel4.setDoubleBuffered( false );
	}

    /**
     * Creates a new instance of JFrame1 with the given title.
     * @param sTitle the title for the new frame.
     * @see #JFrame1()
     */
	public MainFrame(String sTitle)
	{
		this();
		setTitle(sTitle);
	}

	/**
	 * The entry point for this application.
	 * Sets the Look and Feel to the System Look and Feel.
	 * Creates a new JFrame1 and makes it visible.
	 */
	//static public void main(String args[])
	//{
	//	try {
		    // Add the following code if you want the Look and Feel
		    // to be set to the Look and Feel of the native system.
		    /*
		    try {
		        UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
		    }
		    catch (Exception e) {
		    }
		    */

			//Create a new instance of our application's frame, and make it visible.
	//		(new MainFrame()).setVisible(true);
	//	}
	//	catch (Throwable t) {
	//		t.printStackTrace();
	//		//Ensure the application exits with an error condition.
	//		System.exit(1);
	//	}
	//}

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

	javax.swing.ImageIcon newIcon = null; //= new ImageIcon(new URL("images/new.gif"));
	javax.swing.ImageIcon openIcon = null; //= new ImageIcon(new URL("images/open.gif"));
	javax.swing.ImageIcon saveIcon = null; //= new ImageIcon(new URL("images/save.gif"));
	javax.swing.ImageIcon cutIcon = null; //= new ImageIcon(new URL("images/cut.gif"));
	javax.swing.ImageIcon copyIcon = null; //= new ImageIcon(new URL("images/copy.gif"));
	javax.swing.ImageIcon pasteIcon = null; //new ImageIcon(new URL("images/paste.gif"));
	javax.swing.ImageIcon aboutIcon = null; //new ImageIcon(new URL("images/about.gif"));
	javax.swing.ImageIcon selectIcon = null; //new ImageIcon(new URL("images/palette_select.gif"));
	javax.swing.ImageIcon handIcon = null; //new ImageIcon(new URL("images/palette_hand.gif"));
	javax.swing.ImageIcon zoomIcon = null; //new ImageIcon(new URL("images/palette_zoom.gif"));
	javax.swing.ImageIcon fitIcon = null; //new ImageIcon(new URL("images/palette_magnify.gif"));
	java.awt.FileDialog saveFileDialog = new java.awt.FileDialog(this);
	java.awt.FileDialog openFileDialog = new java.awt.FileDialog(this);
	javax.swing.JPanel MainPanel = new javax.swing.JPanel();
	javax.swing.JToolBar MainToolBar = new javax.swing.JToolBar();
	javax.swing.JButton newButton = new javax.swing.JButton();
	javax.swing.JButton openButton = new javax.swing.JButton();
	javax.swing.JButton saveButton = new javax.swing.JButton();
	//com.symantec.itools.javax.swing.JToolBarSeparator JToolBarSeparator1 = new com.symantec.itools.javax.swing.JToolBarSeparator();
	javax.swing.JButton cutButton = new javax.swing.JButton();
	javax.swing.JButton copyButton = new javax.swing.JButton();
	javax.swing.JButton pasteButton = new javax.swing.JButton();
	//com.symantec.itools.javax.swing.JToolBarSeparator JToolBarSeparator2 = new com.symantec.itools.javax.swing.JToolBarSeparator();
	javax.swing.JButton aboutButton = new javax.swing.JButton();
	//com.symantec.itools.javax.swing.JToolBarSeparator JToolBarSeparator3 = new com.symantec.itools.javax.swing.JToolBarSeparator();
	javax.swing.JToggleButton selectButton = new javax.swing.JToggleButton();
	javax.swing.JToggleButton handButton = new javax.swing.JToggleButton();
	javax.swing.JToggleButton zoomButton = new javax.swing.JToggleButton();
	//com.symantec.itools.javax.swing.JToolBarSeparator JToolBarSeparator4 = new com.symantec.itools.javax.swing.JToolBarSeparator();
	javax.swing.JButton fitButton = new javax.swing.JButton();
	//com.symantec.itools.javax.swing.JToolBarSeparator JToolBarSeparator5 = new com.symantec.itools.javax.swing.JToolBarSeparator();
	javax.swing.JSlider JSlider1 = new javax.swing.JSlider();
	javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
	//com.symantec.itools.javax.swing.JToolBarSeparator JToolBarSeparator6 = new com.symantec.itools.javax.swing.JToolBarSeparator();
	javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
	javax.swing.JScrollPane MainScrollPane = new javax.swing.JScrollPane();
	net.tinyos.moteview.GraphDisplayPanel GraphDisplayPanel = new net.tinyos.moteview.GraphDisplayPanel();
	javax.swing.JMenuBar MainMenuBar = new javax.swing.JMenuBar();
	javax.swing.JMenu fileMenu = new javax.swing.JMenu();
	javax.swing.JMenuItem newItem = new javax.swing.JMenuItem();
	javax.swing.JMenuItem openItem = new javax.swing.JMenuItem();
	javax.swing.JMenuItem saveItem = new javax.swing.JMenuItem();
	javax.swing.JMenuItem saveAsItem = new javax.swing.JMenuItem();
	javax.swing.JSeparator JSeparator1 = new javax.swing.JSeparator();
	javax.swing.JMenuItem exitItem = new javax.swing.JMenuItem();
	javax.swing.JMenu editMenu = new javax.swing.JMenu();
	javax.swing.JMenuItem JMenuItem2 = new javax.swing.JMenuItem();
	javax.swing.JSeparator JSeparator2 = new javax.swing.JSeparator();
	javax.swing.JMenuItem cutItem = new javax.swing.JMenuItem();
	javax.swing.JMenuItem copyItem = new javax.swing.JMenuItem();
	javax.swing.JMenuItem pasteItem = new javax.swing.JMenuItem();
	public javax.swing.JMenu DisplayMenu = new javax.swing.JMenu();
	javax.swing.JCheckBoxMenuItem JCheckBoxMenuItem8 = new javax.swing.JCheckBoxMenuItem();
	javax.swing.JMenuItem JMenuItem7 = new javax.swing.JMenuItem();
	javax.swing.JSeparator JSeparator4 = new javax.swing.JSeparator();
	javax.swing.JCheckBoxMenuItem JCheckBoxMenuItem7 = new javax.swing.JCheckBoxMenuItem();
	javax.swing.JMenuItem JMenuItem8 = new javax.swing.JMenuItem();
	public javax.swing.JMenu PacketReadersMenu = new javax.swing.JMenu();
	public javax.swing.JMenu PacketAnalyzersMenu = new javax.swing.JMenu();
	javax.swing.JMenu JMenu1 = new javax.swing.JMenu();
	javax.swing.JMenuItem JMenuItem5 = new javax.swing.JMenuItem();
	javax.swing.JSeparator JSeparator13 = new javax.swing.JSeparator();
	javax.swing.JMenuItem JMenuItem6 = new javax.swing.JMenuItem();
	javax.swing.JMenu helpMenu = new javax.swing.JMenu();
	//javax.swing.JMenuItem JMenuItem1 = new javax.swing.JMenuItem();
	//javax.swing.JSeparator JSeparator3 = new javax.swing.JSeparator();
	javax.swing.JMenuItem aboutItem = new javax.swing.JMenuItem();
	//com.symantec.itools.javax.swing.borders.BevelBorder bevelBorder1 = new com.symantec.itools.javax.swing.borders.BevelBorder();
	//}}

	//{{DECLARE_MENUS
	//}}


	void exitApplication()
	{
		try {
		    	this.setVisible(false);    // hide the Frame
		    	this.dispose();            // free the system resources
		    	System.exit(0);            // close the application
		} catch (Exception e) {
		}
	}

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
		// to do: code goes here.

		MainFrame_windowClosing_Interaction1(event);
	}

	void MainFrame_windowClosing_Interaction1(java.awt.event.WindowEvent event) {
		try {
			this.exitApplication();
		} catch (Exception e) {
		}
	}

	class SymAction implements java.awt.event.ActionListener
	{
		public void actionPerformed(java.awt.event.ActionEvent event)
		{
			Object object = event.getSource();
			if (object == openItem)
				openItem_actionPerformed(event);
			else if (object == saveItem)
				saveItem_actionPerformed(event);
			else if (object == exitItem)
				exitItem_actionPerformed(event);
			else if (object == aboutItem)
				aboutItem_actionPerformed(event);
			else if (object == openButton)
				openButton_actionPerformed(event);
			else if (object == saveButton)
				saveButton_actionPerformed(event);
			else if (object == aboutButton)
				aboutButton_actionPerformed(event);
			else if (object == selectButton)
				selectButton_actionPerformed(event);
			else if (object == handButton)
				handButton_actionPerformed(event);
			else if (object == zoomButton)
				zoomButton_actionPerformed(event);
			else if (object == fitButton)
				fitButton_actionPerformed(event);
			if (object == JMenuItem7)
				JMenuItem7_actionPerformed(event);

			if (object == JMenuItem8)
				JMenuItem8_actionPerformed(event);
			else if (object == JMenuItem2)
				JMenuItem2_actionPerformed(event);


		}
	}

	void openItem_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		openItem_actionPerformed_Interaction1(event);
	}

	void openItem_actionPerformed_Interaction1(java.awt.event.ActionEvent event) {
		try {
			// openFileDialog Show the FileDialog
			openFileDialog.setVisible(true);
		} catch (Exception e) {
		}
	}

	void saveItem_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		saveItem_actionPerformed_Interaction1(event);
	}

	void saveItem_actionPerformed_Interaction1(java.awt.event.ActionEvent event) {
		try {
			// saveFileDialog Show the FileDialog
			saveFileDialog.setVisible(true);
		} catch (Exception e) {
		}
	}

	void exitItem_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		exitItem_actionPerformed_Interaction1(event);
	}

	void exitItem_actionPerformed_Interaction1(java.awt.event.ActionEvent event) {
		try {
			this.exitApplication();
		} catch (Exception e) {
		}
	}

	void aboutItem_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		aboutItem_actionPerformed_Interaction1(event);
	}

	void openButton_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		openButton_actionPerformed_Interaction1(event);
	}

	void openButton_actionPerformed_Interaction1(java.awt.event.ActionEvent event) {
		try {
			// openFileDialog Show the FileDialog
			openFileDialog.setVisible(true);
		} catch (Exception e) {
		}
	}

	void saveButton_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		saveButton_actionPerformed_Interaction1(event);
	}

	void saveButton_actionPerformed_Interaction1(java.awt.event.ActionEvent event) {
		try {
			// saveFileDialog Show the FileDialog
			saveFileDialog.setVisible(true);
		} catch (Exception e) {
		}
	}

	void aboutButton_actionPerformed(java.awt.event.ActionEvent event)
	{
		try {
			// JAboutDialog Create and show as modal
			{
				JAboutDialog JAboutDialog1 = new JAboutDialog(this);
				JAboutDialog1.setModal(true);
				JAboutDialog1.show();
			}
		} catch (java.lang.Exception e) {
		}
	}

	void selectButton_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		selectButton_actionPerformed_Interaction1(event);
	}

	void selectButton_actionPerformed_Interaction1(java.awt.event.ActionEvent event) {
		try {
			// JAboutDialog Create with owner and show as modal
			{
				selectButton.setSelected(true);
				handButton.setSelected(false);
				zoomButton.setSelected(false);
				MainClass.displayManager.SetSelectMode(true);
				MainClass.displayManager.SetHandMode(true);
				MainClass.displayManager.SetZoomMode(true);
			}
		} catch (Exception e) {
		}
	}

	void handButton_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		handButton_actionPerformed_Interaction1(event);
	}

	void handButton_actionPerformed_Interaction1(java.awt.event.ActionEvent event) {
		try {
			// JAboutDialog Create with owner and show as modal
			{
				selectButton.setSelected(false);
				handButton.setSelected(true);
				zoomButton.setSelected(false);
				MainClass.displayManager.SetSelectMode(false);
				MainClass.displayManager.SetHandMode(true);
				MainClass.displayManager.SetZoomMode(false);
			}
		} catch (Exception e) {
		}
	}

	void zoomButton_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		zoomButton_actionPerformed_Interaction1(event);
	}

	void zoomButton_actionPerformed_Interaction1(java.awt.event.ActionEvent event) {
		try {
			// JAboutDialog Create with owner and show as modal
			{
				selectButton.setSelected(false);
				handButton.setSelected(false);
				zoomButton.setSelected(true);
				MainClass.displayManager.SetSelectMode(false);
				MainClass.displayManager.SetHandMode(false);
				MainClass.displayManager.SetZoomMode(true);
			}
		} catch (Exception e) {
		}
	}

	void fitButton_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		fitButton_actionPerformed_Interaction1(event);
	}

	void fitButton_actionPerformed_Interaction1(java.awt.event.ActionEvent event) {
		try {
			// JAboutDialog Create with owner and show as modal
			{
				MainClass.mainFrame.GetGraphDisplayPanel().FitToScreen();
			}
		} catch (Exception e) {
		}
	}

	/*class SymFocus extends java.awt.event.FocusAdapter
	{
		public void focusGained(java.awt.event.FocusEvent event)
		{
			Object object = event.getSource();
			if (object == MainMenuBar)
				MainMenuBar_focusGained(event);
		}
	}

	void MainMenuBar_focusGained(java.awt.event.FocusEvent event)
	{
		// to do: code goes here.

		MainMenuBar_focusGained_Interaction1(event);
	}

	void MainMenuBar_focusGained_Interaction1(java.awt.event.FocusEvent event)
	{
		try {
			MainClass.suspend();
		} catch (java.lang.Exception e) {
		}
	}*/

	          //the following code was written by kamin
	public net.tinyos.moteview.GraphDisplayPanel GetGraphDisplayPanel()
	{
		return GraphDisplayPanel;
	}

	public javax.swing.JScrollPane GetMainScrollPane()
	{
		return MainScrollPane;
	}

	public javax.swing.JLabel GetCoordLabel()
	{
		return JLabel4;
	}

	void JMenuItem7_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		JMenuItem7_actionPerformed_Interaction1(event);
	}


	class SymItem implements java.awt.event.ItemListener
	{
		public void itemStateChanged(java.awt.event.ItemEvent event)
		{
			Object object = event.getSource();
			if (object == JCheckBoxMenuItem7)
				JCheckBoxMenuItem7_itemStateChanged(event);
			if (object == JCheckBoxMenuItem8)
				JCheckBoxMenuItem8_itemStateChanged(event);
		}
	}

	void JCheckBoxMenuItem7_itemStateChanged(java.awt.event.ItemEvent event)
	{
		// to do: code goes here.

		JCheckBoxMenuItem7_itemStateChanged_Interaction1(event);
	}

	void JCheckBoxMenuItem7_itemStateChanged_Interaction1(java.awt.event.ItemEvent event)
	{
		try {
			if(event.getStateChange() == ItemEvent.SELECTED)
			{
				net.tinyos.moteview.MainClass.displayManager.start();
			}
			else
			{
				net.tinyos.moteview.MainClass.displayManager.stop();
			}
		} catch (java.lang.Exception e) {
		}
	}

	void JMenuItem8_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		JMenuItem8_actionPerformed_Interaction1(event);
	}

	void JMenuItem8_actionPerformed_Interaction1(java.awt.event.ActionEvent event)
	{
		try {
			net.tinyos.moteview.MainClass.displayManager.RefreshScreenNow();
		} catch (java.lang.Exception e) {
		}
	}

	void JCheckBoxMenuItem8_itemStateChanged(java.awt.event.ItemEvent event)
	{
		// to do: code goes here.

		JCheckBoxMenuItem8_itemStateChanged_Interaction1(event);
	}

	void JCheckBoxMenuItem8_itemStateChanged_Interaction1(java.awt.event.ItemEvent event)
	{
		try {
			if(event.getStateChange() == ItemEvent.SELECTED)
			{
				net.tinyos.moteview.MainClass.mainFrame.GetGraphDisplayPanel().SetFitToScreenAutomatically(true);
			}
			else
			{
				net.tinyos.moteview.MainClass.mainFrame.GetGraphDisplayPanel().SetFitToScreenAutomatically(false);
			}
		} catch (java.lang.Exception e) {
		}
	}

	void JMenuItem7_actionPerformed_Interaction1(java.awt.event.ActionEvent event)
	{
		try {
			net.tinyos.moteview.MainClass.mainFrame.GetGraphDisplayPanel().FitToScreen();
		} catch (java.lang.Exception e) {
		}
	}

	class SymChange implements javax.swing.event.ChangeListener
	{
		public void stateChanged(javax.swing.event.ChangeEvent event)
		{
			Object object = event.getSource();
			if (object == JSlider1)
				JSlider1_stateChanged(event);
		}
	}

	void JSlider1_stateChanged(javax.swing.event.ChangeEvent event)
	{
		// to do: code goes here.

		JSlider1_stateChanged_Interaction1(event);
	}

	void JSlider1_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
	{
		try {
			// convert int->class java.lang.String
			MainClass.displayManager.MultiplyGraphDisplayPanelSize(JSlider1.getValue());
			JLabel3.setText(java.lang.String.valueOf(JSlider1.getValue()));
		} catch (java.lang.Exception e) {
		}
	}

	void aboutItem_actionPerformed_Interaction1(java.awt.event.ActionEvent event)
	{
		try {
			// JAboutDialog Create and show as modal
			{
				JAboutDialog JAboutDialog1 = new JAboutDialog(this);
				JAboutDialog1.setModal(true);
				JAboutDialog1.show();
			}
		} catch (java.lang.Exception e) {
		}
	}

	void JMenuItem2_actionPerformed(java.awt.event.ActionEvent event)
	{
		// to do: code goes here.

		JMenuItem2_actionPerformed_Interaction1(event);
	}

	void JMenuItem2_actionPerformed_Interaction1(java.awt.event.ActionEvent event)
	{
		try {
			net.tinyos.moteview.MainClass.ShowOptionsDialog();
		} catch (java.lang.Exception e) {
		}
	}
}