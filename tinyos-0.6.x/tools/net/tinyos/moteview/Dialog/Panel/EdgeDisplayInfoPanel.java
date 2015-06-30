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

package net.tinyos.moteview.Dialog.Panel;

              //this file is used for visually creating the panel using VCafe,
              //it is then inserted into another class as an inner class and edited

import Surge.*;
import Surge.Dialog.*;
import java.beans.*;
import java.awt.*;
import javax.swing.JLabel;
import javax.swing.JTextField;
import javax.swing.JCheckBox;
import javax.swing.JButton;
import javax.swing.JPanel;

public class EdgeDisplayInfoPanel extends Surge.Dialog.ActivePanel
{
	Node node;

	public EdgeDisplayInfoPanel (Node pNode)
	{
		tabTitle = "General";
		node = pNode;
		//{{INIT_CONTROLS
		setLayout(null);
		Insets ins = getInsets();
		setSize(259,279);
		//}}

		//{{REGISTER_LISTENERS
		SymAction lSymAction = new SymAction();
		//}}
	}

	//{{DECLARE_CONTROLS
	//}}

	public void ApplyChanges()
	{
/*		node.SetX(Double.valueOf(JTextArea1.getText()).doubleValue());
		node.SetY(Double.valueOf(JTextArea2.getText()).doubleValue());
		node.SetFixed(JCheckBox1.isSelected());
		node.SetDisplayThisNode(JCheckBox2.isSelected());*/
	}


	class SymAction implements java.awt.event.ActionListener
	{
		public void actionPerformed(java.awt.event.ActionEvent event)
		{
		}
	}
}