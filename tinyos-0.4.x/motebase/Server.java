import java.util.*;
import java.net.*;
import java.io.*;

public class Server {
     public static void main(String argv[]) {
	 Server s = new Server();
	 s.init();
	 while(1 == 1){
	     s.go();
	 }
     }


    ServerSocket sk;
    public void init(){
	 try{
		int port = 7502;
		 sk = new ServerSocket(port);
		System.out.println("waiting on accept on port: "+port);
	 }catch(Exception e){
	     e.printStackTrace();
	 }
    }
public void go(){
	 try{		
		Socket sock = sk.accept();
	 	System.out.println("connection made");
		InputStream in = sock.getInputStream();
		OutputStream out = sock.getOutputStream();
		int packetsize = 30;
		Date start = new Date();
		
		byte[] data = new byte[packetsize];
		int count = 0;
		while(count < packetsize){
		    count += in.read(data, count, packetsize-count);
		}
		for(int j = 0; j < data.length; j++){
		    
		    System.out.print((0xFF &data[j]) + ", ");
		    
		    
		}
		System.out.println(".");
		System.out.println(new String(data));
		
	 }catch(Exception e){
	     System.out.println(e.getMessage());
	     e.printStackTrace();
	 }
     }
}

