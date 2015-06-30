import java.io.*;
import java.util.*;

import javax.servlet.*;
import javax.servlet.http.*;

import net.tinyos.packet.*;
import net.tinyos.util.*;

import org.mortbay.util.*;

public class MoteList extends HttpServlet {

  public void doGet(HttpServletRequest req, HttpServletResponse res)
    throws ServletException, IOException {

    StringBuffer fullURI = req.getRequestURL();
    if (req.getQueryString() != null) {
      fullURI.append("?" + req.getQueryString());
    }
    URI uri = new URI(fullURI.toString());
    System.err.println("GET " + uri);
	
    PrintWriter out = res.getWriter();

    MoteConnector mc = MoteConnector.getInstance();
	
    Map nameMap = mc.getNameMap();

    out.println("<html><body>");

    if (nameMap.isEmpty()) {
      out.println("ERROR: No motes available<br>");
    } else {

      out.println("<table border=1>");

      out.println("<tr>");

      out.println("<td><b>Node Name</b><td><b>MOTECOM</b>");

      for(Iterator it = nameMap.entrySet().iterator();
	  it.hasNext(); ) {

	out.println("<tr>");

	Map.Entry en = (Map.Entry) it.next();
		
	out.println("<td>" + 
		    "<a href=\"bridge?mote=" + en.getKey() + "\"/>" + en.getKey() + "</a>" + 
		    "<td>" + 
		    en.getValue());
      }
      out.println("</table>");
    }
	
    out.println("</body></html>");
  }
}
