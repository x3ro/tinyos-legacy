package net.tinyos.tosser;

import java.io.*;
import java.net.*;
import java.util.*;

public class Simulator extends Thread {
    public static final int TOSSIM_PORT = 10583;
    public static int maxEvents = 500;
    private static final int timeout = 500;
    
    private Process proc;
    private Socket sock = null;
    private LineNumberReader lineReader;
    private OutputStreamWriter syncWriter;
    private int scale = 5;
    private LinkedList eQueue;
    private Workspace ws;

    public Simulator(String executable, int numProcs, 
                     LinkedList eQueue, Workspace ws) 
            throws IOException {
        proc = Runtime.getRuntime().exec(executable + " -l " + numProcs);
        
        while (sock == null) {
            try {
                sock = new Socket("localhost", TOSSIM_PORT);
                break;
            } catch (UnknownHostException e) {}
            try {
                Thread.sleep(100);
            } catch (InterruptedException ie) {}
        }

        lineReader = new LineNumberReader(
                         new InputStreamReader(sock.getInputStream()));
        syncWriter = new OutputStreamWriter(sock.getOutputStream());
        this.eQueue = eQueue;
        this.ws = ws;
    }

    public void run() {
        char response[] = new char[] { 'x' };
        while (true) {
            String line;
            try {
                line = lineReader.readLine();
                syncWriter.write(response, 0, 1);
                syncWriter.flush();
            } catch (IOException ioe) {
                break;
            }
            int space = line.indexOf(' ');
            String timeString = line.substring(0, space - 1);
            long timeStamp = Long.parseLong(timeString);
            String pinName = line.substring(space).trim();

            synchronized (eQueue) {
                SimulatorEvent simEvent = new SimulatorEvent(timeStamp, 
                                                             pinName, ws);
                while (eQueue.size() >= maxEvents) {
                    try {
                        eQueue.wait(100);
                    } catch (InterruptedException ie) {
                    }
                }
                eQueue.add(simEvent);
                eQueue.notify();
            }
        }
    }

    protected void finalize() throws Throwable {
        super.finalize();
        System.out.println("in finalize()");
        proc.destroy();
    }
}
