// $Id: testplot.java,v 1.2 2003/10/07 21:46:02 idgay Exp $

package net.tinyos.plot;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;

public class testplot {
    public static void main (String[] args) throws Exception
    {
    	//UIManager.setLookAndFeel(
	    //"com.sun.java.swing.plaf.windows.WindowsLookAndFeel");



        JFrame window = new JFrame ("Java plot");
		plotpanel p = new plotpanel();
		//p.addFunction (new TestFunction(), Color.blue);
		//p.addFunction (new TestFunction2(), Color.red);
		window.getContentPane().setLayout (new BorderLayout());
		
		p.setPreferredSize(new Dimension(500, 350));

		window.getContentPane().add (new plotcontrolpanel(p), BorderLayout.NORTH);
        window.getContentPane().add (p, BorderLayout.CENTER);
		window.getContentPane().add (new plotformulapanel(p), BorderLayout.SOUTH);

		window.pack (); 
		window.setDefaultCloseOperation (JFrame.EXIT_ON_CLOSE); 
        window.setVisible (true);
    }
}










