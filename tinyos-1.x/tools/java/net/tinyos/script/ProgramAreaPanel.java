// $Id: ProgramAreaPanel.java,v 1.3 2004/09/03 17:38:12 scipio Exp $

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

public class ProgramAreaPanel extends JPanel {
  private JLabel programLabel;
  private JPanel programLabelPanel;
  
  private JTextArea programArea;
  private JTextArea lineArea;
  private JScrollPane scrollPane;
  private JPanel innerPanel;

  private Font codeFont = new Font("monospaced", Font.PLAIN, 10);
  
  public ProgramAreaPanel() {
    super();
    String defaultText;
    innerPanel = new JPanel();
    innerPanel.setBorder(new EtchedBorder());

    programArea = new JTextArea(99, 60);
    programArea.setFont(codeFont);
    
    lineArea = new JTextArea(99, 2);
    lineArea.setFont(codeFont);
		     
    defaultText = "1";
    for (int i = 2; i < 100; i++) {
      defaultText += "\n" + i;
    }
    lineArea.setText(defaultText);
    lineArea.setEditable(false);
    
    innerPanel.add(lineArea);
    innerPanel.add(programArea);
    
    scrollPane = new JScrollPane(innerPanel);
    scrollPane.setPreferredSize(new Dimension(350, 400));
    scrollPane.setSize(new Dimension(350, 400));

    programLabel = new JLabel("Program Text");
    programLabel.setFont(TinyLook.boldFont());
    programLabel.setAlignmentX(LEFT_ALIGNMENT);
    programLabelPanel = new JPanel();
    programLabelPanel.add(programLabel);
    programLabelPanel.setBorder(new EtchedBorder());

    setLayout(new BoxLayout(this, BoxLayout.Y_AXIS));
    add(programLabelPanel);
    add(scrollPane);
    setFont(TinyLook.defaultFont());
    setBorder(new EtchedBorder());
  }

  public String getProgram() {
    return programArea.getText();
  }

  public void setProgram(String text) {
    programArea.setText(text);
  }

  public void highlightLine(int line) {
    String prog = programArea.getText();
    int start = 0;
    int end = prog.length() - 1;
    int currentLine = 1;
    System.out.println("Highlighting line " + line);
    for (int i = 0; i < prog.length(); i++) {
      char ch = prog.charAt(i);
      if (ch == '\n') {
	if (currentLine == line) { // Start of offending line
	  end = i;
	}
	currentLine++;
	if (currentLine == line) {
	  start = i + 1;
	}
      }
    }
    // Because these calls have bounds checks, we need to repeat
    // one call (e.g., if new start is later than previous end)
    programArea.setSelectionStart(start);
    programArea.setSelectionEnd(end);
    programArea.setSelectionStart(start);
  }
  
  public static void main(String[] args) {
    JFrame frame = new JFrame();
    ProgramAreaPanel p = new ProgramAreaPanel();
    frame.getContentPane().add(p);
    frame.pack();
    frame.setVisible(true);
  }

}
