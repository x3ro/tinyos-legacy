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
import javax.swing.*;
import Surge.*;
import Surge.Dialog.*;
import Surge.PacketAnalyzers.*;
import java.awt.event.*;
import javax.swing.event.*;
import java.beans.*;
import java.awt.*;

public class OptionsPanel extends ActivePanel
{


	public OptionsPanel()
	{
	    tabTitle = "Display Properties";
	    modal = true;
		//{{INIT_CONTROLS
		setLayout(null);
		Insets ins = getInsets();
		setSize(280,114);
		JLabel1.setToolTipText("This is the number of times the screen will be magnified");
		JLabel1.setText("ZoomX:");
		add(JLabel1);
		JLabel1.setBounds(24,12,48,24);
		JComboBox1.setEditable(true);
		JComboBox1.setToolTipText("This is the number of times the screen will be magnified");
		JComboBox1.addItem(new Double(1.0));
		JComboBox1.addItem(new Double(1.5));
		JComboBox1.addItem(new Double(2.0));
		JComboBox1.addItem(new Double(2.5));
		JComboBox1.addItem(new Double(3.0));
		add(JComboBox1);
		JComboBox1.setBounds(144,12,108,24);
		JLabel2.setToolTipText("Times are listed in milliseconds");
		JLabel2.setText("Screen Refresh Rate:");
		add(JLabel2);
		JLabel2.setBounds(24,48,132,24);
		JLabel4.setText("msec");
		add(JLabel4);
		JLabel4.setFont(new Font("Dialog", Font.BOLD, 9));
		JLabel4.setBounds(204,48,24,24);
		JSlider1.setMinimum(100);
		JSlider1.setMaximum(10000);
		JSlider1.setToolTipText("Slide this to change the refresh rate");
		//JSlider1.setBorder(bevelBorder1);
		JSlider1.setValue(1500);
		add(JSlider1);
		JSlider1.setBounds(60,84,216,21);
		//$$ bevelBorder1.move(0,115);
		JLabel3.setText("jlabel");
		add(JLabel3);
		JLabel3.setFont(new Font("Dialog", Font.BOLD, 16));
		JLabel3.setBounds(156,48,51,27);
		JComboBox1.setSelectedIndex(0);
		//}}

		//{{REGISTER_LISTENERS
		SymChange lSymChange = new SymChange();
		JSlider1.addChangeListener(lSymChange);
		SymAction lSymAction = new SymAction();
		//}}
	}

	//{{DECLARE_CONTROLS
	javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
	javax.swing.JComboBox JComboBox1 = new javax.swing.JComboBox();
	javax.swing.JLabel JLabel2 = new javax.swing.JLabel();
	javax.swing.JLabel JLabel4 = new javax.swing.JLabel();
	javax.swing.JSlider JSlider1 = new javax.swing.JSlider();
	//com.symantec.itools.javax.swing.borders.BevelBorder bevelBorder1 = new com.symantec.itools.javax.swing.borders.BevelBorder();
	javax.swing.JLabel JLabel3 = new javax.swing.JLabel();
	//}}


	public void ApplyChanges()
	{
		      //this function is called when the user clicks the "Apply" button
		      //on the dialog in which this Active Panel is displayed.
		      //It should apply the values of the display components
		      //to the variables they represent
	}

	public void InitializeDisplayValues()
	{
		      //This function is called by a thread that runs in the background
		      //and updates the values of the Active Panels so they are always
		      //up to date.
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

	class SymAction implements java.awt.event.ActionListener
	{
		public void actionPerformed(java.awt.event.ActionEvent event)
		{
		}
	}

	void JSlider1_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
	{
		try {
			// convert int->class java.lang.String
			JLabel3.setText(java.lang.String.valueOf(JSlider1.getValue()));
		} catch (java.lang.Exception e) {
		}
	}
}