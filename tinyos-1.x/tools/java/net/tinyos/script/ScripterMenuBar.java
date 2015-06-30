// $Id: ScripterMenuBar.java,v 1.2 2004/07/15 02:54:27 scipio Exp $

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
 * Date:        Jun 14 2004
 * Desc:        Program area panel for Scripter.
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

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class ScripterMenuBar extends JMenuBar {
  private JMenu fileMenu;
  private JMenuItem loadItem;
  private JMenuItem quitItem;
  
  public ScripterMenuBar(ScripterWindowed scripter) {
    super();
    fileMenu = new JMenu();
    fileMenu.setText("File");

    loadItem = new JMenuItem();
    loadItem.setText("Load");
    loadItem.addActionListener(new LoadActionListener(scripter));
    loadItem.setFont(TinyLook.defaultFont());
    fileMenu.add(loadItem);

    quitItem = new JMenuItem();
    quitItem.setText("Quit");
    quitItem.addActionListener(new QuitActionListener(scripter));
    quitItem.setFont(TinyLook.defaultFont());
    fileMenu.add(quitItem);

    add(fileMenu);
  }

 
  private class LoadActionListener implements ActionListener {
    private ScripterWindowed scripter;
    private JFileChooser chooser;

    public LoadActionListener(ScripterWindowed s) {
      scripter = s;
      chooser = new JFileChooser();
    }
    
    public void actionPerformed(ActionEvent e) {
      int rval = chooser.showOpenDialog(scripter);
      if (rval == JFileChooser.APPROVE_OPTION) {
	File file = chooser.getSelectedFile();
	if (file.isFile()) {
	  scripter.loadProgramFile(file);
	}
	else {
	  scripter.showError("Invalid file: " + file);
	}
      }
    }
  }
  
  
  private class QuitActionListener implements ActionListener {
    private ScripterWindowed scripter;
    
    public QuitActionListener(ScripterWindowed s) {
      scripter = s;
    }
    public void actionPerformed(ActionEvent e) {
      scripter.cleanup();
      System.exit(0);
    }
  }
}
