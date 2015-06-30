// $Id: plotformulapanel.java,v 1.2 2003/10/07 21:46:02 idgay Exp $

package net.tinyos.plot;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;

public class plotformulapanel extends JToolBar implements ActionListener {
	plotpanel p;
	JTextField formula;
	JTextField description;
	Color mycolor = Color.blue;
	JButton colorButton;
	
	public plotformulapanel (plotpanel p) {
		GridBagLayout gb = new GridBagLayout();
		GridBagConstraints gbc = new GridBagConstraints();
		setLayout(gb);
		this.p = p;
		
		gbc.gridx = 1;
		gbc.gridy = 1;
		gbc.weightx = 0;
		gbc.fill = GridBagConstraints.HORIZONTAL;

		JLabel fx = new JLabel ("f(x) = ");
		gb.setConstraints(fx, gbc);
		add(fx);
		
		gbc.weightx = .7;
		gbc.gridx = 2;
		formula = new JTextField();
		formula.setActionCommand("Plot!");
		formula.addActionListener (this);
		gb.setConstraints(formula, gbc);
		add (formula);

		gbc.gridx = 3;
		gbc.weightx = 0;
		JLabel quote1 = new JLabel (" - \"");
		gb.setConstraints(quote1, gbc);
		add(quote1);

		gbc.weightx = .3;
		gbc.gridx = 4;
		description = new JTextField();
		gb.setConstraints(description, gbc);
		add (description);

		gbc.weightx = 0;
		gbc.gridx = 5;
		JLabel quote2 = new JLabel ("\"");
		gb.setConstraints(quote2, gbc);
		add(quote2);

		/*gbc.gridx = 4;
		JButton erase = new JButton ("<<");
		erase.addActionListener (this);
		gb.setConstraints(erase, gbc);
		add(erase);*/

		gbc.gridx = 6;
		colorButton = new JButton("Color", new ImageIcon("color.gif"));
		colorButton.setActionCommand("color");
		colorButton.setBackground (mycolor);
		colorButton.addActionListener (this);
		gb.setConstraints(colorButton, gbc);
		add(colorButton);
		
		gbc.gridx = 7;
		JButton plot = new JButton ("Plot!", new ImageIcon("goplot.gif"));
		plot.addActionListener (this);
		gb.setConstraints(plot, gbc);
		add(plot);
	}

	public void actionPerformed (ActionEvent e) {
		/*if (e.getActionCommand() == "<<") {
			p.setBackground(Color.white);
			formula.setText("");
			return;
		} else */if (e.getActionCommand() == "Plot!") {
			p.addFunction(new ParsedFunction(formula.getText()), mycolor, description.getText());
		} else if (e.getActionCommand() == "color") {
			mycolor = JColorChooser.showDialog(
			              this,
			              "Choose Plot Color",
			              mycolor);
			colorButton.setBackground (mycolor);
		}

		p.repaint();
	}
}