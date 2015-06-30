package de.tub.eyes.gui.customelements;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2004</p>
 * <p>Company: </p>
 * @author not attributable
 * @version 1.0
 */

import javax.swing.*;
import java.awt.*;

public class ListTest implements java.awt.event.ActionListener{

  private javax.swing.JList list;
  private javax.swing.DefaultListModel model;
  private javax.swing.JButton addButton;
  private javax.swing.JFrame frame;
  private int counter;

  public ListTest(){
    buildUI();
    frame.pack();
    frame.show();
  }

  private void buildUI(){
    frame = new javax.swing.JFrame("Dynamic List test");
    frame.setDefaultCloseOperation(javax.swing.JFrame.EXIT_ON_CLOSE);
    model = new javax.swing.DefaultListModel();
    list = new javax.swing.JList(model);
    addButton = new javax.swing.JButton("add entry");
    addButton.addActionListener(this);

    frame.getContentPane().setLayout(new java.awt.BorderLayout());
    frame.getContentPane().add(list,java.awt.BorderLayout.CENTER);
    frame.getContentPane().add(addButton,java.awt.BorderLayout.SOUTH);

  }

  public void actionPerformed(java.awt.event.ActionEvent e){
    String s = String.valueOf(counter++);
    model.addElement(s);
  }

  public static void main(String[] args){
    ListTest test = new ListTest();
  }

}
