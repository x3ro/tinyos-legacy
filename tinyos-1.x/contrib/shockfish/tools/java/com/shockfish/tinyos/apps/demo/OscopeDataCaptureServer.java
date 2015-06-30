package com.shockfish.tinyos.apps.demo;

import java.io.IOException;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.logging.ConsoleHandler;
import java.util.logging.FileHandler;
import java.util.logging.Level;
import java.util.logging.Logger;

//import com.shockfish.sapn.gatewayserver.ServerThread;
//import com.shockfish.sapn.gatewayserver.SocketServerManager;

public class OscopeDataCaptureServer {

    private ServerSocket oscopeServerSocket;

    public OscopeDataCaptureServer(int port) throws Exception {
         
        try {
            //InetAddress addressReceiver = InetAddress.getLocalHost();

            oscopeServerSocket = new ServerSocket(port);
            // not so nice exception handling...
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void close() {
        try {
            oscopeServerSocket.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void start() {

        while (true) {

            Socket clientSocket;
            OscopeDataCaptureServerThread serverThread;
            try {
                System.out.println("Waiting for remote connection");
                clientSocket = oscopeServerSocket.accept();
                serverThread = new OscopeDataCaptureServerThread(clientSocket);
                //Thread thread = new Thread(serverThread);
                serverThread.start();
            } catch (IOException e) {
                e.printStackTrace();
            }

        }

    }

    public static void main(String args[]) throws Exception {
        OscopeDataCaptureServer server = new OscopeDataCaptureServer((new Integer(
                args[0])).intValue());
        server.start();

    }

}
