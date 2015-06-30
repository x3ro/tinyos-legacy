import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;

import net.tinyos.packet.*;
import net.tinyos.util.*;

import org.mortbay.util.*;

public class PacketBridge extends HttpServlet {

  public PacketBridge() { }

  public void init(ServletConfig config) {
  }

  public void doGet(HttpServletRequest req, HttpServletResponse res)
    throws ServletException, IOException {

    PrintWriter out = res.getWriter();
	    	
    StringBuffer fullURI = req.getRequestURL();
    if (req.getQueryString() != null) {
      fullURI.append("?" + req.getQueryString());
    }
    URI uri = new URI(fullURI.toString());
    System.err.println("GET " + uri);
	
    String moteName = uri.get("mote");
    MoteConnector mc = MoteConnector.getInstance();

    PacketBridger br = new PacketBridger(req, res);

    try {
      mc.registerPacketListener(moteName, br);
      br.waitTilClose();
      mc.deregisterPacketListener(moteName, br);
    } catch (NoSuchNameException e) {
      out.println("ERROR: No mote exists with name <b>" + moteName + "</b>");
    }
  }

  private class PacketBridger implements net.tinyos.packet.PacketListenerIF {
    HttpServletResponse res;
    PrintWriter out;
    boolean connectionClosed = false;
    String linkheader;
    
    private PacketBridger(HttpServletRequest req, HttpServletResponse res) 
      throws ServletException, IOException {
      this.res = res;
      res.setContentType("text/plain");
      out = res.getWriter();
    }
    
    public void waitTilClose() {
      for (;;) {
	try {
	  if (connectionClosed) {
	    return;
	  }
	  Thread.sleep(1000);
	} catch (InterruptedException e) {
	  System.err.println(e);
	}
      }
    } 
    
    public void packetReceived(byte[] packet) {
      if (out.checkError()) {
	connectionClosed = true;
      } else {
	out.println(buildString(packet));
	out.flush();
      }
    }
    
    public String buildString(byte[] packet) {
      
      String buf = "";
      
      DataInputStream packetData = 
	new DataInputStream(new ByteArrayInputStream(packet));
      
      try {
	
	while(packetData.available() > 1) {
	  buf += toHexByte(packetData.readUnsignedByte()) + " ";
	}
	
	buf += toHexByte(packetData.readUnsignedByte());
	
      } catch (IOException e) {
	buf += e;
      }
      
      return buf;
    }
    
    private String toHexByte(int b) {
      String buf = "";
      String bs = Integer.toHexString(b & 0xff).toUpperCase();
      if (b >=0 && b < 16)
	buf += "0";
      buf += bs;
      return buf;
    }
  }
}



