// Author: Jaein Jeong
// Injecter.java

package test_trio;

import java.util.*;
import java.io.*;
import java.net.*;
import javax.swing.*;
import java.lang.Math;


public class Injecter {

    public static int group_id = 0x7d;
    static ClientWindow clntWindow = null;

    private static void usage() {
      System.err.println("Usage: Injecter <group_id>");
      System.exit(-1);
    }

    public Injecter() {

    }

    public static void main(String args[]) {
      try {
        if (args.length >= 1) {
          if (args[0].startsWith("0x") || args[0].startsWith("0X")) {
            group_id = Integer.parseInt(args[0].substring(2), 16);
          } else {
            group_id = Integer.parseInt(args[0]);
          }
        }
        System.err.println("Using AM group ID " + group_id + " (0x" +
          Integer.toHexString(group_id) + ")");
        Injecter reader = new Injecter();
        CreateGui();
      } catch (Exception ex) {
        System.err.println("main() got exception: " + ex);
        ex.printStackTrace();
        System.exit(-1);
      }
    }

    private static void CreateGui ( )
    {
        // create frame
        JFrame clientFrame = new JFrame("Trio sensor board test program");
        // create client gui
        clntWindow = new ClientWindow ( clientFrame );
        // create comm processing thread
        clientFrame.addWindowListener( clntWindow );
        clientFrame.setSize( clntWindow.getPreferredSize() );
        clientFrame.getContentPane().add("Center", clntWindow);

        clientFrame.show();
    }
};

