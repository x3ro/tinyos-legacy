// $Id: GUI.java,v 1.2 2003/10/07 21:45:54 idgay Exp $

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

package net.tinyos.ident;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

class GUI extends JPanel implements WindowListener, DBReceiver
{
    JScrollPane visitorPane;
    JTextArea visitorText;
    JPanel panel = new JPanel();
    JPanel panel2 = new JPanel();
    JTextField idField = new JTextField();
    JButton setidButton = new JButton();
    JButton clearidButton = new JButton();
    JButton quitButton = new JButton();
    int textEnd;

    UserDB db;
    MoteIF moteIF;

    GUI(MoteIF m, UserDB d)
    {
	db = d;
	moteIF = m;
	db.setDBListener(this);
    }

    public void open()
    {
      try {
	  jbInit();
      }
      catch(Exception e) {
	  e.printStackTrace();
      }
      JFrame mainFrame = new JFrame("Ident");
      mainFrame.setSize(getPreferredSize());
      mainFrame.getContentPane().add("Center", this);
      mainFrame.show();
      mainFrame.addWindowListener(this);
    }

    public void dbChange(Vector db)
    {
	/* Build display string */
	String display = "";
	Enumeration elems = db.elements();

	while (elems.hasMoreElements()) {
	    DBId elem = (DBId)elems.nextElement();

	    display = display + elem.id + ":" + new Date(elem.arrivalTime) + "\n";
	}
	replaceText(display);
    }

    private void jbInit() throws Exception 
    {
	setMinimumSize(new Dimension(520, 160));
	setPreferredSize(new Dimension(520, 160));

	idField.setFont(new java.awt.Font("Dialog", 1, 10));

	setidButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e)
		{
		    String id = validateId(idField.getText());
		    if (id != null)
			moteIF.sendSet(id);
		}
	    });
	setidButton.setText("Set ID");
        setidButton.setFont(new java.awt.Font("Dialog", 1, 10));

	clearidButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e)
		{
		    moteIF.sendClear();
		}
	    });
	clearidButton.setText("Clear IDs");
        clearidButton.setFont(new java.awt.Font("Dialog", 1, 10));

	quitButton.addActionListener(new java.awt.event.ActionListener()
	    {
		public void actionPerformed(ActionEvent e)
		{
		    System.exit(0);
		}
	    });
	quitButton.setText("Exit");
        quitButton.setFont(new java.awt.Font("Dialog", 1, 10));

	panel.setLayout(new GridLayout(4, 1));
	panel.setMinimumSize(new Dimension(150, 100));
	panel.setPreferredSize(new Dimension(150, 100));
	panel.add(idField, null);
	panel.add(setidButton, null);
	panel.add(clearidButton, null);
	panel.add(quitButton, null);

	visitorText = new JTextArea();
	visitorPane = new JScrollPane(visitorText);

	panel2.setLayout(new BorderLayout());
	panel2.add(visitorPane, null);
	panel2.setPreferredSize(new Dimension(340, 100));

	add(panel2, BorderLayout.WEST);
	add(panel, BorderLayout.EAST);
    }

    String validateId(String id)
    {
	if (id.length() > Ident.MAX_ID_LENGTH)
	    return null;
	else
	    return id;
    }

    synchronized void replaceText(String newText)
    {
	visitorText.replaceRange(newText, 0, textEnd);
	textEnd = newText.length();
    }

    public void windowClosing(WindowEvent e) { }
    public void windowClosed(WindowEvent e) { }
    public void windowActivated(WindowEvent e) { }
    public void windowIconified(WindowEvent e) { }
    public void windowDeactivated(WindowEvent e) { }
    public void windowDeiconified(WindowEvent e) { }
    public void windowOpened(WindowEvent e) { }
}
