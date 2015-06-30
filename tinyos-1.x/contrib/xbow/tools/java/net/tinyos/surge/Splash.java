package net.tinyos.surge;



import javax.swing.*;
import javax.swing.event.*;
import javax.swing.text.*;
import javax.swing.border.*;
import javax.swing.colorchooser.*;
import javax.swing.filechooser.*;
import javax.accessibility.*;

import java.lang.reflect.*;
import java.awt.*;
import java.awt.event.*;
import java.beans.*;
import java.util.*;
import java.io.*;
import java.applet.*;
import java.net.*;


public class Splash implements Runnable{

        public static void main(String[] args) {
		new Splash();
	}
	public Splash(){
		new Thread(this).start();
	}

	public void run(){
		ImageIcon img;
		try{
			img = new ImageIcon(getClass().getResource("images/Splash.jpg"));
		}catch(Exception e){
			img = new ImageIcon("images/Splash.jpg");
		}
		
		JLabel splashLabel = new JLabel(img);
		JWindow splashScreen = new JWindow();
		splashScreen.getContentPane().add(splashLabel);
		splashScreen.pack();	
		Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
	        splashScreen.setLocation(screenSize.width/2 - splashScreen.getSize().width/2,screenSize.height/2 - splashScreen.getSize().height/2);
		splashScreen.show();
		try{Thread.sleep(1000);}catch(Exception e){}	
		splashScreen.setVisible(false);
		
	}
}


