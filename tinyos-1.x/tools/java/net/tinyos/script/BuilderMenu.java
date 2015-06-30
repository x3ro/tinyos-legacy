// $Id: BuilderMenu.java,v 1.3 2005/04/28 00:34:03 scipio Exp $

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
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        Sep 26 2003
 * Desc:        Main window for VM builder
 *
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.script;

import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.io.*;
import java.net.*;
import java.util.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.filechooser.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.script.tree.*;
import net.tinyos.util.*;

public class BuilderMenu extends JMenuBar {
    private JMenu fileMenu;
    private JMenuItem fileSaveItem;
    private JMenu fileLoadMenu;
    private JMenuItem fileLoadTreeItem;
    private JMenuItem fileLoadDirectoryItem;
    private JMenuItem fileLoadFileItem;
    private JMenuItem fileLanguageItem;
    private JMenuItem fileQuitItem;
    
    private JMenu optionMenu;
    private JCheckBoxMenuItem optionAdvancedItem;
    
    private JMenu helpMenu;


    
    private VMBuilderGui builder;
    
    public BuilderMenu(VMBuilderGui builder) {
	super();
	this.builder = builder;
	MenuListener mListen = new MenuListener(builder);
	
	fileMenu = new JMenu("File");

	fileSaveItem = new JMenuItem("Save");
	fileSaveItem.addActionListener(mListen);
	
	fileQuitItem = new JMenuItem("Quit");
	fileQuitItem.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(java.awt.event.ActionEvent evt) {
		    System.exit(0);
		}
	    });

	fileLoadMenu = new JMenu("Load");
	fileLoadTreeItem = new JMenuItem("VM Tree");
	fileLoadTreeItem.addActionListener(mListen);	

	fileLoadDirectoryItem = new JMenuItem("Directory");
	fileLoadDirectoryItem.addActionListener(mListen);
	
	fileLoadFileItem = new JMenuItem("File");
	fileLoadFileItem.addActionListener(mListen);

	fileLanguageItem = new JMenuItem("Select Language");
	fileLanguageItem.addActionListener(mListen);
	
	fileLoadMenu.add(fileLoadTreeItem);
	fileLoadMenu.add(fileLoadDirectoryItem);
	fileLoadMenu.add(fileLoadFileItem);

	//fileMenu.add(fileSaveItem);
	fileMenu.add(fileLoadMenu);
	fileMenu.addSeparator();
	//fileMenu.add(fileLanguageItem);		
	//fileMenu.addSeparator();
	fileMenu.add(fileQuitItem);

	optionMenu = new JMenu("Options");
	
	optionAdvancedItem = new JCheckBoxMenuItem("Advanced Options");
	optionAdvancedItem.addActionListener(new AdvancedListener(optionAdvancedItem, builder));
	optionMenu.add(optionAdvancedItem);
	
	helpMenu = new JMenu("Help");
	
	Insets i = new Insets(10, 10, 10, 10);
	fileMenu.setMargin(i);
	
	add(fileMenu);
	//add(optionMenu);
	//add(helpMenu);
    }

    private class AdvancedListener implements ActionListener {
	private VMBuilderGui builder;
	private JCheckBoxMenuItem item;

	public AdvancedListener(JCheckBoxMenuItem item, VMBuilderGui builder) {
	    this.item = item;
	    this.builder = builder;
	}

	public void actionPerformed(ActionEvent evt) {
	    builder.showAdvanced(item.getState());
	}
    }

    private class MenuListener implements ActionListener {
	private VMBuilderGui builder;
	private JFileChooser chooser;
	private SingleFileFilter singleFilter;
	private SearchFileFilter searchFilter;
	private LanguageFileFilter langFilter;
	private javax.swing.filechooser.FileFilter basicFilter;
	
	public MenuListener(VMBuilderGui builder) {
	    this.builder = builder;
	    this.chooser = new JFileChooser();
	    this.basicFilter = chooser.getFileFilter();
	    this.singleFilter = new SingleFileFilter();
	    this.langFilter = new LanguageFileFilter();
	}

	public void actionPerformed(ActionEvent event) {
	    int rval;
	    File file;
	    String cmd = event.getActionCommand();

	    if (cmd.equals("Save")) {
		builder.getDescription();
		chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
		chooser.setFileFilter(basicFilter);
		rval = chooser.showSaveDialog(builder);
		if (rval == JFileChooser.APPROVE_OPTION) {
		    file = chooser.getSelectedFile();
		    try {
			String name = file.getAbsolutePath() + "/";
			System.out.println(name);
			file = new File(name);
			file.mkdir();
			builder.createFiles(file);
		    }
		    catch (Exception exception) {
			exception.printStackTrace();
			System.err.println("Could not create VM: " + file);
		    }
		}
	    }
	    else if (cmd.equals("VM Tree")) {
		chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
		chooser.setFileFilter(basicFilter);
		rval = chooser.showOpenDialog(builder);
		if (rval == JFileChooser.APPROVE_OPTION) {
		    file = chooser.getSelectedFile();
		    builder.actOnTree(file);
		}
	    }
	    else if (cmd.equals("Directory")) {
		chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
		chooser.setFileFilter(basicFilter);
		rval = chooser.showOpenDialog(builder);
		if (rval == JFileChooser.APPROVE_OPTION) {
		    file = chooser.getSelectedFile();
		    builder.actOnDirectory(file);
		}
	    }
	    else if (cmd.equals("File")) {
		chooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
		chooser.setFileFilter(searchFilter);
		rval = chooser.showOpenDialog(builder);
		if (rval == JFileChooser.APPROVE_OPTION) {
		    builder.actOnFile(chooser.getSelectedFile());
		}
	    }
	    else if (cmd.equals("Select Language")) {
		chooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
		chooser.setFileFilter(langFilter);
		rval = chooser.showOpenDialog(builder);
		if (rval == JFileChooser.APPROVE_OPTION) {
		  try {
		    builder.setLanguageFile(chooser.getSelectedFile());
		  }
		  catch (IOException exception) {
		    System.err.println("An exception occured loading the language file: " + exception);
		  }
		  catch (StatementFormatException exception) {
		    System.err.println("The language file had an irrecoverable formatting error: " + exception);
		  }
		  catch (OpcodeFormatException exception) {
		    System.err.println("The language file had an irrecoverable formatting error: " + exception);
		  }
		}
	    }
	    builder.repaint();
	}
	
    }

    private class SearchFileFilter extends javax.swing.filechooser.FileFilter implements java.io.FileFilter {
	public boolean accept(File f) {
	    if (f.isDirectory()) {
		return true;
	    }
	    
	    String name = f.getName();
	    if (name.endsWith("Context.nc") ||
		(name.startsWith("OP") &&
		 name.endsWith(".odf"))) {
		return true;
	    }
	    return false;
	}

	//The description of this filter
	public String getDescription() {
	    return "Contexts and opcodes";
	}
    }

    private class SingleFileFilter extends javax.swing.filechooser.FileFilter implements java.io.FileFilter {
	public boolean accept(File f) {
	    if (f.isDirectory()) {
		return false;
	    }
	    String name = f.getName();
	    if (name.endsWith("Context.nc") ||
		(name.startsWith("OP") &&
		 name.endsWith(".odf"))) {
		return true;
	    }
	    return false;
	}

    //The description of this filter
	public String getDescription() {
	    return "Contexts and opcodes";
	}
    }

    private class LanguageFileFilter extends javax.swing.filechooser.FileFilter implements java.io.FileFilter {
	public boolean accept(File f) {
	    if (f.isDirectory()) {
		return true;
	    }
	    String name = f.getName();
	    if (name.endsWith(".ldf")) {
		return true;
	    }
	    return false;
	}

    //The description of this filter
	public String getDescription() {
	    return "Language description files";
	}
    }
    
    public static void main(String[] args) {
	JFrame frame = new JFrame();
	BuilderMenu menu = new BuilderMenu(null);
	frame.setJMenuBar(menu);
	frame.pack();
	frame.setVisible(true);
    }
}
