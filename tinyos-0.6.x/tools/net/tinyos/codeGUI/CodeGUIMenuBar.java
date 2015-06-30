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
 *
 *
 */

package net.tinyos.codeGUI;

import java.awt.event.*;

import javax.swing.*;
import javax.swing.event.*;

public class CodeGUIMenuBar extends JMenuBar {
    private JMenu fileMenu;
    
    public CodeGUIMenuBar() {
	super();
	makeFileMenu();
    }

    private void makeFileMenu() {
	fileMenu = new JMenu("File");
	fileMenu.setMnemonic(KeyEvent.VK_F);
	fileMenu.getAccessibleContext().setAccessibleDescription("File Menu");
	add(fileMenu);

	JMenuItem quitItem = new JMenuItem("Quit", KeyEvent.VK_Q);
	quitItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_Q, ActionEvent.CTRL_MASK));
	quitItem.getAccessibleContext().setAccessibleDescription("Quits Malkuth");
	quitItem.addActionListener(new QuitActionListener());
	
	fileMenu.add(quitItem);
    }

    public class QuitActionListener implements ActionListener {

	public QuitActionListener() {}

	public void actionPerformed(ActionEvent e) {
	    System.exit(0);
	}
    }
}
