import java.util.*;
import java.io.*;
import java.net.*;

  public class ReceiverServer extends Thread{

    OutputStream out = null;

    public void run(){
      ServerSocket serverSocket=null;
      // Open a server
      try{
        serverSocket = new ServerSocket(9000);
      }catch(IOException e){
        System.out.println("Cannot listen on port 9000");
        System.exit(-1);
      }
      System.out.println("ReceiverServer starts listening");

      while(true){
	Socket clientSocket=null;
	try{
	  // Blocks to receive client's connection
	  clientSocket = serverSocket.accept();   
	  out = clientSocket.getOutputStream();      
	}catch(IOException e){
	  System.out.println("Accept failed");
	  System.exit(-1);
	}
	
	System.out.println("Client connected successfully");
	// Gets the connection, keep blocking
	while(true){
	  this.yield();
	}
      }
    }

    public void write(byte[] packet){
      try{
	if (out != null){
	  out.write(packet);
	}
      }catch(IOException e){
	System.out.println("Client connection error.");
      }
    }

  }
