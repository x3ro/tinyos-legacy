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
import java.sql.*;
import javax.servlet.*;
import javax.servlet.http.*;
import org.mortbay.html.*;
import org.mortbay.http.*;
import org.mortbay.jetty.servlet.*;
import net.tinyos.task.taskapi.*;
import net.tinyos.task.tasksvr.*;

public class TASKDataServlet extends HttpServlet {

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

	private void printResultsHTMLTable(Connection db, String sqltxt, PrintWriter out) 
		throws SQLException
	{
		Statement stmt = taskDBConn.createStatement();
		ResultSet rs;
		ResultSetMetaData rsmd;

		rs = stmt.executeQuery(sqltxt);

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

	private void printResultsCDT(Connection db, String sqltxt, PrintWriter out) 
		throws SQLException 
	{
		Statement stmt = db.createStatement();
		ResultSet rs;
		ResultSetMetaData rsmd;
		
		rs = stmt.executeQuery(sqltxt);
		if (rs != null) {
			rsmd = rs.getMetaData();
			
			out.print(rsmd.getColumnName(1));
			for (int i=2; i <= rsmd.getColumnCount();i++) {
				out.print(", "+ rsmd.getColumnName(i));
			}
			out.println();
			
			while (rs.next()) {
				out.print(rs.getString(1));
				for (int i=2; i <= rsmd.getColumnCount();i++) {
					out.print(", " + rs.getString(i));
				}
				out.println();
			}
			
		}
		else {
			out.println("__NORESULT");
		}
		return;
	}

    public void doGet(HttpServletRequest request, HttpServletResponse response)
		throws IOException, ServletException
    {
		Vector taskCmdInfos = taskServer.getTASKCommands();
		String formTarget = response.encodeURL(request.getRequestURI());

        PrintWriter out = response.getWriter();

        response.setContentType("text/html");
		response.setHeader("Pragma", "no-cache");
        response.setHeader("Cache-Control", "no-cache,no-store");

        out.println("<html>");
        out.println("<head>");
        out.println("<title>TASK Data Viewer</title>");
        out.println("</head>");
        out.println("<body onload=\"document.formDBMSQuery.textSQL.focus()\">");

		out.println("<h3>DBMS Data Viewer</h3>");

		out.println("<form name=\"formDBMSQuery\" action=\"" + formTarget + "\" method=post>");

		out.println("<b>Enter the DBMS SQL Query:</b><br>" +
					"<i>Use the table name\"</i><tt>task_current_results</tt><i>\" " +
					"to refer to the results table for the latest query.</i>");
		
		out.println("<p>");
		
		out.println("<table border=\"1\">" +
					"<tr><td><input type=\"text\" name=\"textSQL\" size=100><tr>");
		out.println("</table>");

		out.println("<p>");

		out.println("<b>Select format:</b> " + 
					"<table border=\"1\">" +
					"<tr><td>Table <input type=\"radio\" name=\"rbViewFormat\" value=\"Table\" checked>" + 
					"<td>CDT <input type=\"radio\" name=\"rbViewFormat\" value=\"CDT\"><tr>" +
					"</table><p>");

		out.println("<input type=\"submit\" name=\"submitAction\" value=\"Run Query\">" +
					"<input type=\"reset\" value=\"Reset\">");

		out.println("</form><p>");

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
		TASKQuery taskCurrentQry = taskServer.getTASKQuery(TASKServer.SENSOR_QUERY);
		String dbmsSQLQry;
		
		response.setContentType("text/html");
        response.setHeader("Pragma", "no-cache");
        response.setHeader("Cache-Control", "no-cache,no-store");

		if ((action == null) || (action.equals("Run Query"))) {
			String sqltext = request.getParameter("textSQL");
			String vfmt = request.getParameter("rbViewFormat");
			
			if ((sqltext != null) && (!sqltext.equals(""))) {
				dbmsSQLQry = sqltext;

				if ((vfmt == null) || (vfmt.equals("Table"))) {
					try {
						printResultsHTMLTable(taskDBConn,dbmsSQLQry,out);
					}
					catch (SQLException sqle){
						out.println("Bad Query:" + sqle.getMessage());
					}
				}
				else {
					try {
						printResultsCDT(taskDBConn,dbmsSQLQry,out);
					}
					catch (SQLException sqle) {
						out.println("__BADQUERY");
					}
				}
			}
			else {
				out.println("__BADFORMREQUEST");
				throw new HttpException(501);
			}
		}
		else {
			out.println("__BADFORMACTION");
			throw new HttpException(501);
		}
    }

}







