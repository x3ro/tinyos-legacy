import java.io.*;
import java.util.*;

import org.mortbay.http.*;
import org.mortbay.jetty.servlet.*;
//import org.mortbay.http.handler.*;
//import org.mortbay.jetty.*;
//import org.mortbay.util.*;
//import org.mortbay.servlet.*;     
      
public class WebMote
{
    private static String motecom;
    private static int port = 80;
    
    private static void processArgs(String[] args) {
	for (int i = 0; i < args.length; i++) {
	    if (args[i].equals ("-port")) {
		i++;
		if (i < args.length) {
		    port = Integer.parseInt(args[i]);
		}
		else {
		    usage();
		}
	    }
	}
    }
  
    private static void usage() {
	System.err.println("java WebMote [args]");
	System.err.println("  -port <port> (80 default)");
	System.err.println("");
	System.err.println("Access the server at: http://<machine>:<port>/webmote/list");
	System.exit(1);
    }

    public static void main (String[] args)
	throws Exception
    {
	processArgs(args);

	// Create the server
	HttpServer server=new HttpServer();
	server.addListener(":"+port);
	HttpContext context = server.getContext("/webmote");
	ServletHandler handler = new ServletHandler();
	handler.addServlet("MoteList","/","MoteList");
	handler.addServlet("Bridge","/bridge/*","PacketBridge");
	context.addHandler(handler);

	// Start the http server
	server.start();
	
	MoteConnector.getInstance();
    }
}
