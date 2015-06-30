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

import java.awt.*;
import javax.swing.*;

public class LogPanel extends JPanel {
    private JTextArea text;
    private JScrollPane scroll;

    public LogPanel() {
		super();
		
		text = new JTextArea(16,80);
		text.setEditable(false);
		text.setLineWrap(true);
		
		scroll = new JScrollPane();
		scroll.getViewport().add(text, BorderLayout.SOUTH);
		scroll.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
		scroll.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
		
		this.add(scroll);
		
		Font f = new Font("Courier", 0, 10);
		text.setFont(f.deriveFont((float)10.0));
    }
    
    public void write(byte[] buffer, int len) {
		byte[] msg = new byte[len];
		for (int i = 0; i < len; i++) {
			msg[i] = buffer[i];
		}
		String s = new String(msg);
		text.append(s);
    }
}
