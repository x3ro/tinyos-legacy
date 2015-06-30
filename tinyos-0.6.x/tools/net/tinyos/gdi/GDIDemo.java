/* Demo for a signal plotter.
*/
package net.tinyos.gdi;
import ptolemy.plot.*;
import java.sql.*;
import java.applet.*;
import java.util.*;


public class GDIDemo extends PlotApplet {

    ///////////////////////////////////////////////////////////////////
    ////                         public methods                    ////

    /**
     * Return a string describing this applet.
     */
    public String getAppletInfo() {
        return "GDI Visualization";
    }

    /**
     * Initialize the applet.  Here we step through an example of what the
     * the applet can do.
     */
    protected Connection conn;

    protected String historyStmt = "select node_id, packet_time, light_reading from weather where node_id in (?) and packet_time > ? order by packet_time";

    protected String DOW[] = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
    
    protected int plots[];
    
    protected String columnNames[] = {"light", 
			      "temperature",
			      "thermopile"};

    protected void parseNodeIDs(Plot plot, String node_id_str) {
	StringTokenizer t = new StringTokenizer(node_id_str, " ,");
	plots = new int[10];
	int index = 0;
	int nid;
	while (t.hasMoreTokens() && index < 10) {
	    String tok = t.nextToken();
	    System.err.println("Token t: "+tok);
	    plot.addLegend(index, "Node " +tok);
	    plots[index++] = Integer.parseInt(tok);
	}
    }


    public void init() {
        super.init();

	try {
	    Plot plot = (Plot)plot();

	    plot.setTitle(getParameter("plottitle"));
	    plot.setYRange(0, 4096);
	    plot.setXRange(0, 4*86400*1000);
	    //	    plot.setXLabel();
	    plot.setYLabel(getParameter("ylabel"));

	    String dbUser = getParameter("dbuser");
	    if (dbUser == null) 
		dbUser = "birdwatcher";
	    
	    String dbPasswd = getParameter("dbpasswd");
	    if (dbPasswd == null) 
		dbPasswd = "mote";

	    String dbHost = getParameter("dbhost"); 
	    if (dbHost == null) 
		dbHost = "localhost";
	    
	    String dbName = getParameter("dbname");
	    if (dbName == null) 
		dbName = "gdi"; 
	    
	    String sqlUrl = "jdbc:postgresql://"+dbHost+
		"/"+dbName;
	    
	    String readingType = getParameter("readingtype");
	    if (readingType == null) 
		readingType = "light_reading";
	    
	    String node_id_str = getParameter("nodeid");
	    if (node_id_str == null)
		node_id_str = "47";
	    parseNodeIDs(plot, node_id_str);

	    Class.forName("org.postgresql.Driver");
	    conn = DriverManager.getConnection(sqlUrl, dbUser, dbPasswd);

	    java.sql.Timestamp startTime = new java.sql.Timestamp(System.currentTimeMillis() - 
					       (((long)4) * ((long)86400) * 
						((long)1000)));
	    System.err.println(startTime);

	    String sqlStmt = "select node_id, floor(date_part('epoch', packet_time) / 1200), round(avg(" + readingType +
		")) from weather where node_id in (" + node_id_str +
		") and packet_time > \'"+ startTime +
		"\' group by node_id, floor(date_part('epoch', packet_time) / 1200)";
	    
	    System.err.println(sqlStmt);
	    Statement stmt = conn.createStatement();
	    
	    //	    pstmt.setString(, readingType);
	    ResultSet rs = stmt.executeQuery(sqlStmt);
	    long baseTime = System.currentTimeMillis() - ((long)(4 * 86400 *1000));


	    java.util.Date date = new java.util.Date();
	    Calendar cal = Calendar.getInstance();
	    int dow = cal.get(Calendar.DAY_OF_WEEK);
	    // Create the midnight point on GDI 
	    cal.set(Calendar.HOUR, 9);
	    cal.set(Calendar.MINUTE, 0);
	    cal.set(Calendar.SECOND, 1);
	    
	    double ttm = (double) (cal.getTime().getTime() - baseTime);
	    System.err.println("Day of the week is "+dow);
	    
	    for (int h = 0; h < 96; h++) {
		plot.addXTick("", (double) (h * 3600 *1000L));
	    }

	    for (int d=4; d >= 0; d--) {
		System.err.println("Index: "+((dow-d+7)%7));
		plot.addXTick(DOW[(dow-d+7)%7], (ttm - (((double)d)* 86400.0 *1000.0)));
		System.err.println("Adding a tickmark at "+(ttm - (((double)d)* 86400.0 *1000.0)));
 }
	    boolean first = true;
	    
	    java.sql.Timestamp ctime;
	    double value;
	    int count = 0;
	    int nid;
	    int q;
	    
	    DataFilter filter = new PhotoFilter();
	    filter.setYRange(plot);
	    while(rs.next()) {
		nid =  rs.getInt(1);
		long now = (long) rs.getInt(2);
		value = filter.filterData(rs);
		
		for (q=0; q < 10; q++) {
		    if (plots[q] == nid)
			break;
		}

		now *= 1200L *1000L;
		plot.addPoint(q, 
			      (double) (now-baseTime), 
			      value, 
			      true);
		count++;
		if ((count % 100) == 0) {
		    System.err.println("Time "+(double) (now- baseTime));
		    ctime = new java.sql.Timestamp(now);
		    System.err.println(ctime);
		}
	    }
	    System.err.println("inserted "+count);
	} catch (SQLException e) {
	    System.err.println(e);
	    showStatus("Connection failed: "+e.getMessage());
	} catch (ClassNotFoundException e) {
	    System.err.println(e);
	    showStatus("Could not load the SQL driver: "+e.getMessage());
	}
    }
}

interface DataFilter {
    public double filterData(ResultSet rs) throws SQLException;  
    public void setYRange(Plot plot); 
}

class VoltageFilter implements DataFilter {
    
    public double filterData(ResultSet rs) throws SQLException {
	int val = rs.getInt(3);
	return (val * 3.3) / 256;
    }

    public void setYRange(Plot plot) {
	plot.setYRange(0, 3.3);
    }
}

class PhotoFilter implements DataFilter {
    public double filterData(ResultSet rs) throws SQLException {
	int val = rs.getInt(3);
	return (((double) val) / 4096.0) * 100.0;
    }
    public void setYRange(Plot plot) {
	plot.setYRange(0, 100.0);
    }
}


class HumidityFilter implements DataFilter {
    public double filterData(ResultSet rs) throws SQLException {
	int val = rs.getInt(3);
	double value = (val*3.3)/4096;
	value = ((value - 1.43)/0.3)*100;
	return value;
    }
    public void setYRange(Plot plot) {
	plot.setYRange(0, 100.0);
    }

}

class I2CTemperatureFilter implements DataFilter {
    public double filterData(ResultSet rs) throws SQLException {
	int val = rs.getInt(3);
	return val * 0.0625;
    }
    public void setYRange(Plot plot) {
	plot.setYRange(-20.0, 40.0);
    }
}

class ThermistorFilter implements DataFilter {
    public double filterData(ResultSet rs) throws SQLException {
	int val = rs.getInt(3);
	return (double) val;
    }
    public void setYRange(Plot plot) {
	plot.setYRange(0, 4096.0);
    }
}
