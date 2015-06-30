

package net.tinyos.surge.stats;

import javax.swing.table.*;
import java.awt.event.*;
import javax.swing.*;
import java.beans.*;
import java.awt.*;
import java.util.*;
import net.tinyos.surge.stats.*;
import net.tinyos.surge.PacketAnalyzer.*;
import net.tinyos.surge.*;

public class TextFrame extends javax.swing.JFrame implements Runnable{


public TextFrame(){
	super();
	setTitle("Statistics");
	setSize(600, 300);
	TextClass text_pan = new TextClass();
	//setAutoscrolls(true);
	getContentPane().add(BorderLayout.CENTER, text_pan);
	setVisible(true);
	pack();
	new Thread(this).start();
}

public void run(){
	try{
		while(1 == 1){
			Thread.sleep(1000);
			repaint(10);
		}
	}catch (Exception e){
		e.printStackTrace();
	}

  }


}
