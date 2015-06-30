// $Id: GUI.java,v 1.1 2004/01/13 18:43:50 idgay Exp $
/*									tab:4
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
package net.tinyos.matchbox.demo;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import net.tinyos.packet.*;
import net.tinyos.matchbox.*;
import java.util.*;
import java.io.*;

public class GUI extends JPanel implements WindowListener {
    Comm comm;
    JFrame main;
    JScrollPane filePane;
    JList files;
    Dir dir;
    Copier copier;
    JPopupMenu fileMenu;
    JFileChooser fc;
    JLabel freeBytes;

    GUI(Comm comm) {
	dir = new Dir(comm);
	copier = new Copier(comm);

	setMinimumSize(new Dimension(300, 250));
	setPreferredSize(new Dimension(300, 300));
	BorderLayout topLayout = new BorderLayout();
	setLayout(topLayout);

	filePane = new JScrollPane();
	add(filePane, BorderLayout.CENTER);
	files = new JList();
	filePane.getViewport().add(files, null);
	files.setFont(new java.awt.Font("Monospaced", Font.PLAIN, 12));

	freeBytes = new JLabel();
	freeBytes.setFont(new java.awt.Font("Dialog", 1, 10));
	freeBytes.setText("free bytes");
	add(freeBytes, BorderLayout.NORTH);

	MouseListener filePopup = new MouseAdapter() {
		void ev(MouseEvent e) {
		    if (e.isPopupTrigger()) {
			int index = files.locationToIndex(e.getPoint());
			if (index >= 0)
			    showFileMenu(index, e);
		    }
		}
		public void mouseReleased(MouseEvent e) {ev(e);}
		public void mousePressed(MouseEvent e) {ev(e);}
	    };
	files.addMouseListener(filePopup);

	fileMenu = new JPopupMenu();
	JMenuItem item;
	item = new JMenuItem("Size");
	item.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    showSize();
		}
	    });
	fileMenu.add(item);
	item = new JMenuItem("Rename...");
	item.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    renameFile();
		}
	    });
	fileMenu.add(item);
	item = new JMenuItem("Export...");
	item.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    exportFile();
		}
	    });
	fileMenu.add(item);
	item = new JMenuItem("Delete");
	item.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    deleteFile();
		}
	    });
	fileMenu.add(item);

	fc = new JFileChooser();

	JPanel buttons = new JPanel();
	add(buttons, BorderLayout.SOUTH);
	GridLayout buttonLayout = new GridLayout(1, 2);
	buttons.setLayout(buttonLayout);

	JButton refresh = new JButton();
	refresh.setFont(new java.awt.Font("Dialog", 1, 10));
	refresh.setText("Refresh");
	refresh.addActionListener(new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    refreshFileList();
		}
	    });
	buttons.add(refresh, null);

	JButton imprt = new JButton();
	imprt.setFont(new java.awt.Font("Dialog", 1, 10));
	imprt.setText("Import");
	imprt.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    importFile();
		}
	    });
	buttons.add(imprt, null);

	main = new JFrame("Matchbox Demo");
	main.setSize(getPreferredSize());
	main.getContentPane().add("Center", this);
	main.show();
	main.addWindowListener(this);

	refreshFileList();
    }

    public void windowClosing (WindowEvent e) {
	System.exit(0);
    }

    public void windowClosed      (WindowEvent e) { }
    public void windowActivated   (WindowEvent e) { }
    public void windowIconified   (WindowEvent e) { }
    public void windowDeactivated (WindowEvent e) { }
    public void windowDeiconified (WindowEvent e) { }
    public void windowOpened      (WindowEvent e) { }

    Vector vfiles;
    String lastFile;

    void refreshFileList() {
	files.setListData(vfiles = dir.readDirectory());
	long n = dir.freeBytes();
	freeBytes.setText(n + "(" + (n / 1024) + "k) bytes free");
    }

    void importFile() {
	int act = fc.showOpenDialog(main);

	if (act == JFileChooser.APPROVE_OPTION) {
	    File f = fc.getSelectedFile();

	    String err = copier.copyToMote(f, f.getName());
	    if (err != null)
		message("Error", err);
	    refreshFileList();
	}
    }

    void showFileMenu(int index, MouseEvent e) {
	lastFile = (String)vfiles.get(index);
	fileMenu.show(e.getComponent(), e.getX(), e.getY());
    }

    void deleteFile() {
	dir.delete(lastFile);
	refreshFileList();
    }

    void showSize() {
	message("Size", lastFile + ": " + dir.fileSize(lastFile) + " bytes");
    }

    void renameFile() {
	String from = lastFile;
	String to = (String)
	    JOptionPane.showInputDialog(main, "Rename " + lastFile + " to:");
	if (to != null) {
	    dir.rename(from, to);
	    refreshFileList();
	}
    }

    void exportFile() {
	String from = lastFile;
	int act = fc.showSaveDialog(main);
	if (act == JFileChooser.APPROVE_OPTION) {
	    File f = fc.getSelectedFile();

	    String[] head = new String[1];
	    String err = copier.copyFromMote(from, f, head);
	    if (err != null)
		message("Error", err);
	    else
		message("Contents (first 400 bytes)", head[0]);
	}
    }

    void message(String title, String message) {
	JOptionPane.showMessageDialog(main, message, title,
				      JOptionPane.INFORMATION_MESSAGE);
    }
}
