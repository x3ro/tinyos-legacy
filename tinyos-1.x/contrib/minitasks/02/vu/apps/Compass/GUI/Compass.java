/*
 * Compass.java - Java application for visualizing compass
 *
 * Copyright (c) 2003 ISIS, Vanderbilt University
 * All rights reserved.
 *
 * Authors:  Peter Volgyesi
 * Date:     Jan, 2003
 *
 *
 */

import net.tinyos.util.*;

import javax.swing.*;
import java.awt.*;

/**
 * Compass class is the main application class for the
 * compass application. Its main method
 * creates a top level window and parses command line parameters.
 *
 * @author <a href="mailto:peter.volgyesi@vanderbilt.edu">Peter Volgyesi</a>
 */
public class Compass extends javax.swing.JFrame implements Runnable, PacketListenerIF {

    /** Creates new form */
    public Compass() {
        initComponents();
    }


    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        Compass theApp = new Compass();
        theApp.start(args);
    }

    public void start(String args[]) {
        if (!processCommandLine(args)) {
            usage();
            return;
        }
        msg_processor = new Thread(this);
        msg_processor.start();
        show();
    }

    private void usage() {
        String usage_msg = "\n" +
                "Usage: java Compass [OPTION]...\n" +
                "\n" +
                "  Options:\n" +
                "\n" +
                "       -help                 print this help message.\n" +
                "       -minx INT             set the (initial) mininum value of the magnetometer X axis.\n" +
                "       -maxx INT             set the (initial) maxinum value of the magnetometer X axis.\n" +
                "       -miny INT             set the (initial) mininum value of the magnetometer Y axis.\n" +
                "       -maxy INT             set the (initial) maxinum value of the magnetometer Y axis.\n" +
                "       -biascenter INT       set the estimated midpoint of the axis ADC values.\n" +
                "       -biasscale INT        set the estimated ADC scale of the magnetometer gain.\n" +
                "       -serialport STRING    the name of the serial port to be used.\n" +
                "       -width INT            the width of the main window (in pixels).\n" +
                "       -height INT           the height of the main window (in pixels).\n" +
                "";
        System.out.println(usage_msg);
    }

    protected boolean processCommandLine(String[] args) {
        try {
            for (int i = 0; i < args.length; i++) {
                String arg = args[i];

                if (arg.compareTo("-help") == 0) {
                    return false;
                } else if (arg.compareTo("-minx") == 0) {
                    MINX = Integer.parseInt(args[++i]);
                } else if (arg.compareTo("-maxx") == 0) {
                    MAXX = Integer.parseInt(args[++i]);
                } else if (arg.compareTo("-miny") == 0) {
                    MINY = Integer.parseInt(args[++i]);
                } else if (arg.compareTo("-maxy") == 0) {
                    MAXY = Integer.parseInt(args[++i]);
                } else if (arg.compareTo("-biascenter") == 0) {
                    BIAS_CENTER = Integer.parseInt(args[++i]);
                } else if (arg.compareTo("-biasscale") == 0) {
                    BIAS_SCALE = Integer.parseInt(args[++i]);
                } else if (arg.compareTo("-serialport") == 0) {
                    SERIALPORT_NAME = args[++i];
                } else if (arg.compareTo("-width") == 0) {
                    COMPASS_DEFAULT_WIDTH = Integer.parseInt(args[++i]);
                } else if (arg.compareTo("-height") == 0) {
                    COMPASS_DEFAULT_HEIGHT = Integer.parseInt(args[++i]);
                } else {
                    return false;
                }
            }
        } catch (NumberFormatException e) {
            System.err.println(e.toString());
            return false;
        } catch (ArrayIndexOutOfBoundsException e) {
            System.err.println(e.toString());
            return false;
        }
        return true;
    }


    /** This method is called from within the constructor to
     * initialize the form.
     */
    private void initComponents() {
        java.awt.GridBagConstraints gridBagConstraints;

        compass = new CompassControl();
        controlPanel = new javax.swing.JPanel();
        xminLabel = new javax.swing.JLabel();
        xminField = new javax.swing.JTextField();
        xmaxLabel = new javax.swing.JLabel();
        xmaxField = new javax.swing.JTextField();
        yminLabel = new javax.swing.JLabel();
        yminField = new javax.swing.JTextField();
        ymaxLabel = new javax.swing.JLabel();
        ymaxField = new javax.swing.JTextField();
        biascenterLabel = new javax.swing.JLabel();
        biascenterField = new WholeNumberField(BIAS_CENTER, 5);
        biasscaleLabel = new javax.swing.JLabel();
        biasscaleField = new WholeNumberField(BIAS_SCALE, 5);
        biasButton = new javax.swing.JButton();
        outputLabel = new javax.swing.JLabel();

        setTitle("CompassControl");

        getContentPane().add(compass, java.awt.BorderLayout.CENTER);

        controlPanel.setLayout(new java.awt.GridBagLayout());

        xminLabel.setText("X min:");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(xminLabel, gridBagConstraints);

        xminField.setColumns(5);
        xminField.setForeground((java.awt.Color) javax.swing.UIManager.getDefaults().get("TextField.inactiveForeground"));
        xminField.setMinimumSize(new java.awt.Dimension(55, 21));
        xminField.disable();

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(xminField, gridBagConstraints);

        xmaxLabel.setText("X max:");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(xmaxLabel, gridBagConstraints);

        xmaxField.setColumns(5);
        xmaxField.setForeground((java.awt.Color) javax.swing.UIManager.getDefaults().get("TextField.inactiveForeground"));
        xmaxField.setMinimumSize(new java.awt.Dimension(55, 21));
        xmaxField.disable();

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 3;
        gridBagConstraints.gridy = 0;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(xmaxField, gridBagConstraints);

        yminLabel.setText("Y min:");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(yminLabel, gridBagConstraints);

        yminField.setColumns(5);
        yminField.setForeground((java.awt.Color) javax.swing.UIManager.getDefaults().get("TextField.inactiveForeground"));
        yminField.setMinimumSize(new java.awt.Dimension(55, 21));
        yminField.disable();

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(yminField, gridBagConstraints);

        ymaxLabel.setText("Y max:");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(ymaxLabel, gridBagConstraints);

        ymaxField.setColumns(5);
        ymaxField.setForeground((java.awt.Color) javax.swing.UIManager.getDefaults().get("TextField.inactiveForeground"));
        ymaxField.setMinimumSize(new java.awt.Dimension(55, 21));
        ymaxField.disable();

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 3;
        gridBagConstraints.gridy = 1;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(ymaxField, gridBagConstraints);

        biascenterLabel.setText("Bias Center:");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(biascenterLabel, gridBagConstraints);

        biascenterField.setMinimumSize(new java.awt.Dimension(55, 21));
        biascenterField.addKeyListener(new java.awt.event.KeyAdapter() {
            public void keyTyped(java.awt.event.KeyEvent evt) {
                valueFieldKeyTyped(evt);
            }
        });

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(biascenterField, gridBagConstraints);

        biasscaleLabel.setText("Bias Scale:");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 3;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(biasscaleLabel, gridBagConstraints);

        biasscaleField.setMinimumSize(new java.awt.Dimension(55, 21));
        biasscaleField.addKeyListener(new java.awt.event.KeyAdapter() {
            public void keyTyped(java.awt.event.KeyEvent evt) {
                valueFieldKeyTyped(evt);
            }
        });

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 1;
        gridBagConstraints.gridy = 3;
        gridBagConstraints.ipadx = 1;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(biasscaleField, gridBagConstraints);

        biasButton.setText("Set Bias");
        biasButton.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                setBias(evt);
            }
        });
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 2;
        gridBagConstraints.gridy = 2;
        gridBagConstraints.gridwidth = 2;
        gridBagConstraints.gridheight = 2;
        gridBagConstraints.anchor = java.awt.GridBagConstraints.EAST;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(biasButton, gridBagConstraints);

        outputLabel.setText("Connecting...");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridx = 0;
        gridBagConstraints.gridy = 4;
        gridBagConstraints.gridwidth = 4;
        gridBagConstraints.insets = new java.awt.Insets(5, 5, 5, 5);
        controlPanel.add(outputLabel, gridBagConstraints);

        getContentPane().add(controlPanel, java.awt.BorderLayout.SOUTH);

        pack();
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    }


    private void valueFieldKeyTyped(java.awt.event.KeyEvent evt) {
        setDirtyField((javax.swing.JTextField) evt.getComponent(), true);
        biasButton.setEnabled(true);
    }

    private void setDirtyField(javax.swing.JTextField field, boolean isDirty) {
        java.awt.Color color = (java.awt.Color) javax.swing.UIManager.getDefaults().get(
                isDirty ? "TextField.foreground" : "TextField.inactiveForeground");
        field.setForeground(color);
    }

    private void setBias(java.awt.event.ActionEvent evt) {
        setDirtyField(biascenterField, false);
        setDirtyField(biasscaleField, false);
        biasButton.setEnabled(false);

        sendPacket[5] = (byte)(BIAS_CENTER & 0xff);             // Bias center low byte
        sendPacket[6] = (byte)((BIAS_CENTER >> 8) & 0xff);      // Bias center high byte
        sendPacket[7] = (byte)(BIAS_SCALE & 0xff);              // Bias scale low byte
        sendPacket[8] = (byte)((BIAS_SCALE >> 8) & 0xff);       // Bias scale high byte

        try {
            DisplayMsg("Sending...");
            serialPort.Write(sendPacket);
        } catch (Exception e) {
            DisplayMsg("Unable to send message: " + e.toString());
            e.printStackTrace();
        }

    }


    /** run() is called when the message processing thread has been started.
     *  It creates a SerialPortStub object, registers itself as a packer
     *  listener and call the read() method of the port reader, which never
     *  returns.
     *  @see SerialPortStub
     *  @see PacketListenerIF
     */
    public void run() {
        serialPort = new SerialPortStub(SERIALPORT_NAME);

        sendPacket = new byte[SerialForwarderStub.PACKET_SIZE];
        sendPacket[0] = (byte)0xff;     // Destination address low byte
        sendPacket[1] = (byte)0xff;     // Destination address high byte
        sendPacket[2] = (byte)18;       // Type = AM_CALIBRATEMSG
        sendPacket[3] = (byte)0x7d;     // Group ID
        sendPacket[4] = (byte)4;        // Length of payload

        try {
            serialPort.Open();
            serialPort.registerPacketListener(this);
            serialPort.Read();
        } catch (Exception e) {
            DisplayMsg("Unable to open serial port: " + e.toString());
            e.printStackTrace();
        }
    }

    /** packetReceived() is called by the SerialPortStub object. After
     *  the message processing we force the update of the screen.
     *
     *  TODO: CRC checking
     */
    public void packetReceived(byte[] packet) {
        int counter;
        int magx;
        int magy;
        int biasx;
        int biasy;

        counter = packet[6] << 8;
        counter |= packet[5] & 0xff;

        magx = packet[8] << 8;
        magx |= packet[7] & 0xff;

        magy = packet[10] << 8;
        magy |= packet[9] & 0xff;

        biasx = packet[11] & 0xff;
        biasy = packet[12] & 0xff;

        MINX = Math.min(magx, MINX);
        xminField.setText(String.valueOf(MINX));

        MAXX = Math.max(magx, MAXX);
        xmaxField.setText(String.valueOf(MAXX));

        MINY = Math.min(magy, MINY);
        yminField.setText(String.valueOf(MINY));

        MAXY = Math.max(magy, MAXY);
        ymaxField.setText(String.valueOf(MAXY));


        // TODO: Calculate direction
        double angle;

        int x1 = Math.max(0, (magx - MINX));
        double x2 = x1 - ((MAXX - MINX) / 2.0);
        double x = x2 / (MAXX - MINX);

        int y1 = Math.max(0, (magy - MINY));
        double y2 = y1 - ((MAXY - MINY) / 2.0);
        double y = y2 / (MAXY - MINY);

        if (y > 0) {
            angle = (Math.PI / 2.0) - Math.atan(x / y);
        } else {
            angle = (3.0 * Math.PI / 2.0) - Math.atan(x / y);
        }



        if (angle > 0 && angle < (Math.PI * 2)) {
            DisplayMsg(String.valueOf((int)(360.0 * (angle / (Math.PI * 2)))));
            compass.setAngle(angle);
        } else {
            DisplayMsg("Calibrating....");
        }

        System.out.println(String.valueOf(counter) + ":" +
                " magX: " + String.valueOf(magx) +
                " magY:" + String.valueOf(magy));
    }

    void DisplayMsg(String msg) {
        outputLabel.setText(msg);
    }


    private javax.swing.JTextField biasscaleField;
    private CompassControl compass;
    private javax.swing.JLabel xmaxLabel;
    private javax.swing.JTextField xmaxField;
    private javax.swing.JLabel xminLabel;
    private javax.swing.JButton biasButton;
    private javax.swing.JTextField xminField;
    private javax.swing.JLabel ymaxLabel;
    private javax.swing.JLabel biascenterLabel;
    private javax.swing.JTextField ymaxField;
    private javax.swing.JLabel yminLabel;
    private javax.swing.JPanel controlPanel;
    private javax.swing.JTextField biascenterField;
    private javax.swing.JTextField yminField;
    private javax.swing.JLabel biasscaleLabel;
    private javax.swing.JLabel outputLabel;


    int MINX = Integer.MAX_VALUE;
    int MAXX = Integer.MIN_VALUE;
    int MINY = Integer.MAX_VALUE;
    int MAXY = Integer.MIN_VALUE;


    int BIAS_CENTER = 800;
    int BIAS_SCALE = 32;

    String SERIALPORT_NAME = "COM1";

    int COMPASS_DEFAULT_WIDTH = 300;
    int COMPASS_DEFAULT_HEIGHT = 400;

    SerialPortStub serialPort;
    byte[] sendPacket;

    Thread msg_processor;
}
