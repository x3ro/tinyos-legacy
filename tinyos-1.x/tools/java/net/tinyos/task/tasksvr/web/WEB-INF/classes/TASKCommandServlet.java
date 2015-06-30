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

public class TASKCommandServlet extends HttpServlet {

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
		Vector taskCmdInfos = taskServer.getTASKCommands();
		String formTarget = response.encodeURL(request.getRequestURI());

        PrintWriter out = response.getWriter();

        response.setContentType("text/html");
		response.setHeader("Pragma", "no-cache");
        response.setHeader("Cache-Control", "no-cache,no-store");

        out.println("<html>");
        out.println("<head>");
        out.println("<title>TASK Command</title>");
        out.println("</head>");
        out.println("<body>");

		out.println("<h3>Create Command</h3>");

		out.println("<form name=\"formCommand\" action=\"" + formTarget + "\" method=post>");

		out.println("Select a command from the list below and enter any " +
					"required paramters (one per field):");

		out.println("<p>");

		out.println("<select name=\"slCommand\">");      
		for (int i = 0;i < taskCmdInfos.size();i++) {
			TASKCommandInfo info = (TASKCommandInfo)taskCmdInfos.get(i);
			out.println("<option value = " + info.getCommandName() + ">" 
						+ info.getCommandName());
		}
		out.println("</select>\n");

		out.println("<p>");
		out.println("Parameter 1 " +  
					"<input type=\"text\" name=\"textCommandParams\" size=6>");
		out.println("Parameter 2 " +  
					"<input type=\"text\" name=\"textCommandParams\" size=6>");


		out.println("<p>");


		out.println("<input type=\"submit\" name=\"submitAction\" value=\"Run Command\">" +
					"<input type=\"reset\" value=\"Reset\">");

		out.println("</form>");

		out.println("<hr>");

		out.println("<h3>Available Commands</h3>");
		out.println("<table border=\"1\">");
		out.println("<tr><th>Command Name<th>Parameter Count<th>Usage</tr>");

		for (int i=0;i < taskCmdInfos.size();i++) {
			TASKCommandInfo info = (TASKCommandInfo)taskCmdInfos.get(i);
			out.println("<tr><td>" + info.getCommandName() + 
						"<td>" + info.getNumArgs() +
						"<td>" + info.getDescription());
		}
		out.println("</table>");
        out.println("<p><hr><p>");
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

		if (action.equals("Run Command")) {
			String cmdName = request.getParameter("slCommand");
			String params[] = request.getParameterValues("textCommandParams");

			if (cmdName != null) {
				TASKCommand cmd;
				Vector cmdParamsVec = new Vector();
				try 
					{
						if (params != null) {
							for (int i = 0;i<params.length;i++) {
								cmdParamsVec.add(new String(params[i]));
							}
						}
						cmd = new TASKCommand(cmdName,cmdParamsVec,TASKCommand.BROADCAST_ID);
						taskServer.runTASKCommand(cmd);
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







