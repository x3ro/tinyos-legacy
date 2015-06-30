/* Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

import java.io.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.http.*;
import org.mortbay.html.*;
import org.mortbay.http.*;
import org.mortbay.jetty.servlet.*;
import net.tinyos.task.taskapi.*;
import net.tinyos.task.tasksvr.*;

public class TASKQueryServlet extends HttpServlet {

    private TASKServer taskServer;

    public void init() throws ServletException {
		taskServer = (TASKServer)getServletContext().getAttribute("TASKInstance");
		if (taskServer == null) {
			throw new UnavailableException("Couldn't get the TASKServer.");
		}
    }

    public void destroy() {
		taskServer = null;
    }

    public void doGet(HttpServletRequest request, HttpServletResponse response)
		throws IOException, ServletException
    {
		Vector taskAttrInfos = taskServer.getTASKAttributes();
		String formTarget = response.encodeURL(request.getRequestURI());
		TASKQuery taskQry = taskServer.getTASKQuery(TASKServer.SENSOR_QUERY);
		boolean  taskQryActive = taskServer.isTASKQueryActive(TASKServer.SENSOR_QUERY);
        PrintWriter out = response.getWriter();

        response.setContentType("text/html");
		response.setHeader("Pragma", "no-cache");
        response.setHeader("Cache-Control", "no-cache,no-store");

        out.println("<html>");
        out.println("<head>");
        out.println("<title>TASK Query Configuration</title>");
        out.println("</head>");
        out.println("<body>");

		out.println("<h3>Query Status</h3>");

		out.println("<b>Status:</b> " + 
					(taskQryActive?"<font color=\"#00FF00\">RESULTS RECEIVED</font>":
					 "<font color=\"#FF0000\">STOPPED - NO RESULTS RECEIVED</font>"));
		out.println("<p>");
		out.println("<b>Last Query:</b> <br>");
		if (taskQry != null) {
			out.println(taskQry.toSQL());
			out.println("<form name=\"formQueryStatus\" action=\"" + formTarget + "\" method=post>");
			out.println("<input type=\"submit\" name=\"submitAction\" value=\"Stop Query\">");
			out.println("<input type=\"submit\" name=\"submitAction\" value=\"Resend Query\">");
			out.println("</form>");
		}
		else {
			out.println("None.");
			out.println("<form name=\"formQueryStatus\" action=\"" + formTarget + "\" method=post>");
			out.println("<input type=\"submit\" name=\"submitAction\" value=\"Stop Query\">");
			out.println("</form>");
		}
	

		out.println("<hr>");

		out.println("<h3>Create New Sensor Query</h3>");

		out.println("<form name=\"formQueryCreate\" action=\"" + formTarget + "\" method=post>");

		out.println("Construct a query by selecting attributes " + 
					"and sample period:<br>");
		out.println("<p>");

		out.println("<select size=5 name=\"slAttributes\" multiple>");      
		for (int i = 0;i < taskAttrInfos.size();i++) {
			TASKAttributeInfo info = (TASKAttributeInfo)taskAttrInfos.get(i);
			out.println("<option value = " + info.name + ">" 
						+ info.name + " : " + info.description);
		}
		out.println("</select>\n");

		out.println("<p>");
		out.println("Period (milliseconds): " +  
					"<input type=\"text\" name=\"textTime\" size=6>");
		/*
		  out.println( "Time (milliseconds): " +  
		  "<input type=\"text\" name=\"Time\" size=6>" +
		  "<INPUT type=\"radio\" name=\"Timetype\" value=\"ttl\" CHECKED> " +
		  "Total Time to Live" + "<b> -OR- </b>" +
		  "<INPUT type=\"radio\" name=\"Timetype\" value=\"sp\">" + 
		  "Sample Period");
		*/
		out.println("<p>");


		out.println("<input type=\"submit\" name=\"submitAction\" value=\"Run Query\">" +
					"<input type=\"reset\" value=\"Reset\">");

		out.println("</form>");

        out.println("<hr><p>");
        out.println("Method: " + request.getMethod());
        out.println("Request URI: " + request.getRequestURI());
        out.println("Protocol: " + request.getProtocol());
        out.println("PathInfo: " + request.getPathInfo());
        out.println("Remote Address: " + request.getRemoteAddr());

        out.println("</body>");
        out.println("</html>");
    }


    public void doPost(HttpServletRequest request, HttpServletResponse response)
		throws IOException, ServletException
    {
        PrintWriter out = response.getWriter();
		String action = request.getParameter("submitAction");

		response.setContentType("text/html");
        response.setHeader("Pragma", "no-cache");
        response.setHeader("Cache-Control", "no-cache,no-store");

		if (action.equals("Stop Query")) {
			taskServer.stopTASKQuery(TASKServer.SENSOR_QUERY);
		}
		else if (action.equals("Resend Query")) {
			TASKQuery qry = taskServer.getTASKQuery(TASKServer.SENSOR_QUERY);
	   
			if (qry != null) {
				taskServer.runTASKQuery(qry, TASKServer.SENSOR_QUERY);
			}
		}
		else if (action.equals("Run Query")) {
			Vector taskAttrInfos = taskServer.getTASKAttributes();
			String attribs[] = request.getParameterValues("slAttributes");
			String timeString = request.getParameter("textTime");

			if ((attribs != null) && (timeString != null)) {
				Vector selectEntriesVec = new Vector();

				try 
					{
						TASKQuery qry;
						Integer time = new Integer(timeString);
			
						for (int i=0;i<attribs.length;i++) {
							for (int j=0;j < taskAttrInfos.size();j++) {
								TASKAttributeInfo tai = (TASKAttributeInfo)taskAttrInfos.elementAt(j);
								if ((tai != null) && (tai.name.equalsIgnoreCase(attribs[i]))) {
									selectEntriesVec.add(new TASKAttrExpr(tai));
								}
								if (j >= taskAttrInfos.size()) {
									out.println("Bad Query Attribute. Go back and try again.");
									throw new HttpException(501);
								}
							}
						}
						qry = new TASKQuery(selectEntriesVec,new Vector(),time.intValue(),null);
						taskServer.runTASKQuery(qry,TASKServer.SENSOR_QUERY);
					}
				catch (Exception e) 
					{
					}
			}
		}
		response.sendRedirect(response.encodeURL(request.getRequestURI()));
        //doGet(request, response);
    }

}







