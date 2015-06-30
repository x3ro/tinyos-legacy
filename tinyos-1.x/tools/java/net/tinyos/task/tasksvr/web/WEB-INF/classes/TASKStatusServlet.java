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
import java.sql.*;
import javax.servlet.http.*;
import org.mortbay.html.*;
import org.mortbay.http.*;
import org.mortbay.jetty.servlet.*;
import net.tinyos.task.taskapi.*;
import net.tinyos.task.tasksvr.*;

public class TASKStatusServlet extends HttpServlet {

    private TASKServer taskServer;
	private Connection taskDBConn;

    public void init() throws ServletException {
		taskServer = (TASKServer)getServletContext().getAttribute("TASKInstance");
		if (taskServer == null) {
			throw new UnavailableException("Couldn't get the TASKServer.");
		}
		taskDBConn = (Connection)getServletContext().getAttribute("TASKDBMSConn");
		if (taskDBConn == null) {
			throw new UnavailableException("Couldn't get the DBMS Connection.");
		}
    }

    public void destroy() {
		taskServer = null;
		taskDBConn = null;
    }

	private void displayRecentResults(TASKQuery tqry, PrintWriter out) throws SQLException {
		Statement stmt = taskDBConn.createStatement();
		ResultSet rs;
		ResultSetMetaData rsmd;

		rs = stmt.executeQuery("SELECT DISTINCT ON (nodeid) * FROM " 
							   + tqry.getTableName() 
							   + " ORDER BY nodeid, result_time DESC");

		out.println("<h3>Latest Results</h3>");

		if (rs != null) {
			rsmd = rs.getMetaData();
			out.println("<table border=\"1\">");
			out.println("<tr>");
			
			for (int i=1; i <= rsmd.getColumnCount();i++) {
				out.println("<th><tt>"+rsmd.getColumnName(i) + "</tt>");
			}
			out.println("</tr>");
			
			while (rs.next()) {
				out.println("<tr>");
				for (int i=1; i <= rsmd.getColumnCount();i++) {
					out.println("<td><tt>" + rs.getString(i) + "</tt>");
				}
				out.println("</tr>");
			}
			out.println("</table><p>");
		}
		else {
			out.println("No data in DBMS. <br>");
		}

		return;

	}

    public void doGet(HttpServletRequest request, HttpServletResponse response)
		throws IOException, ServletException
    {
		TASKQuery taskQry = taskServer.getTASKQuery(TASKServer.SENSOR_QUERY);
		boolean  taskQryActive = taskServer.isTASKQueryActive(TASKServer.SENSOR_QUERY);

        PrintWriter out = response.getWriter();

        response.setContentType("text/html");
		response.setHeader("Pragma", "no-cache");
        response.setHeader("Cache-Control", "no-cache,no-store");

        out.println("<html>");
        out.println("<body>");
        out.println("<head>");
        out.println("<title>TASK Data Viewer</title>");
        out.println("</head>");
        out.println("<body>");

		out.println("<h3>SensorNet Status</h3>");

		out.println("<b>Query State:<br> "
					+ (taskQryActive?"<font color=\"#00FF00\">RESULTS RECEIVED</font>":
					 "<font color=\"#FF0000\">STOPPED - NO RESULTS RECEIVED</font>") 
					+ "</b><br>");
		out.println("<p>");

		out.println("<b>Last Query:</b> <br>");

		if (taskQry != null) {
			out.println("<tt>" + taskQry.toSQL() + "</tt>");

			out.println("<p><hr>");
			
			try {
				displayRecentResults(taskQry,out);
			}
			catch (SQLException sqle) {
				out.println("ERROR IN RETRIEVING LATEST RESULTS! CHECK DBMS!");
				out.println("Message: " + sqle.getMessage());
			}
		}
		else {
			out.println("**** None ****" + "<p>");
		}

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
        doGet(request, response);
    }

}







