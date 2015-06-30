package com.shockfish.tinyos.apps.demo;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.Socket;
import java.sql.SQLException;
import java.util.Calendar;
import java.util.Date;
import java.util.Properties;
import java.util.logging.Logger;



public class OscopeDataCaptureServerThread extends Thread {

    // lazy import from the TC65 code tree, ProtocolGateway
    protected final int NEW_VALUE = 60;
    private Socket socket;
    private DataInputStream in;
    private DataOutputStream out;



    public OscopeDataCaptureServerThread(Socket socket)  throws IOException {

        try {
            this.socket = socket;
            in = new DataInputStream(socket.getInputStream());
            //out = new DataOutputStream(socket.getOutputStream());
        } catch (IOException e) {
            throw e;
        }
    }

    public void run() {
        int packetCount = 0;
        //long depart = Calendar.getInstance().getTimeInMillis();
        try {
            String idBaseStation = in.readUTF();
            System.out.println("*** ID Basestation: " + idBaseStation);
            long timeStampBaseStation = in.readLong();
            System.out.println("*** Timestamp Basestation: "+timeStampBaseStation);
            // read a packet as long as new_value is received
            while (in.readUnsignedByte() == NEW_VALUE) {
                ++packetCount;
                byte[] data = new byte[OscopeMsg.DEFAULT_MESSAGE_SIZE];
                OscopeMsg msg;
                in.read(data, 0, OscopeMsg.DEFAULT_MESSAGE_SIZE);
                msg = new OscopeMsg();
                msg.dataSet(data);
                System.out.println(msg.toString());
            }
            this.close();
        } catch (Exception e) {
            e.printStackTrace();
            this.close();
        }
    }

    public void close() {
        try {
            in.close();
            //out.close();
            socket.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
