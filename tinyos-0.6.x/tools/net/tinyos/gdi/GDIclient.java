/* Demo for a signal plotter.
*/
package net.tinyos.gdi;
import ptolemy.plot.*;
import java.sql.*;
import java.applet.*;
import java.util.*;
import java.io.*;
import java.net.*;


public class GDIclient extends PlotApplet {

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

    protected String DOW[] = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
    
    protected int plots[];
    
    protected Vector parseHttpInput(BufferedInputReader bin) {
	String line;
	Vector main = new Vector();
	Vector col1 = new Vector();
	Vector col2 = new Vector();
	Vector col3 = new Vector();
	while ((line = bin.readLine()) != null)
	{
	    StringTokenizer t = new StringTokenizer(node_id_str, "\t");
	    int index = 0;
	    while (t.hasMoreTokens()) {
		String tok = t.nextToken();
		Integer temp = Integer.valueOf(tok);
		if (index == 0)
		    col1.addElement(temp);
		if (index == 1)
		    col2.addElement(temp);
		if (index == 2)
		    col3.addElement(temp);
	    }
	}
	main.addElement(col1);
	main.addElement(col2);
	main.addElement(col3);
	return main;
    }

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
	    //plot.setYRange(0, 4096);
	    plot.setXRange(0, 4*86400*1000);
	    //	    plot.setXLabel();
	    plot.setYLabel(getParameter("ylabel"));

	    String readingType = getParameter("readingtype");
	    if (readingType == null) 
		readingType = "light_reading";
	    
	    String node_id_str = getParameter("nodeid");
	    if (node_id_str == null)
		node_id_str = "39";

	    String rmiHost = getParameter("rmiHost");
	    if (rmiHost == null)
		rmiHost = "www.greatduckisland.net";

	    String rmiScript = getParameter("rmiScript");
	    if (rmiScript == null)
		rmiScript = "/java/sqlquery.php";

	    parseNodeIDs(plot, node_id_str);

	    java.sql.Timestamp startTime = new java.sql.Timestamp(System.currentTimeMillis() - 
					       (((long)4) * ((long)86400) * 
						((long)1000)));
	    System.out.println(startTime);

	    // make HTTP post call to $rmiHost$rmiScript with
	    // $readingType
	    // $node_id_str
	    // $startTime
	    System.err.println(sqlStmt);

	    URL url = null;
	    HttpURLConnection connection = null;
	    BufferedReading bin = null;

	    try {
		String args = "readingType=" + 
		    URLEncoder.encode(readingType) + 
		    "&node_id_str=" + URLEncoder.encode(node_id_str) +
		    "&startTime=" + URLEncoder.encode(startTime);

		url = new URL(rmiHost + rmiScript + "?" + args);
		System.out.println(rmiHost + rmiScript + "?" + args);
		connection = (HttpURLConnection)url.openConnection();
		connection.setRequestMethod("GET");
		bin = new BufferedReader(new InputStreamReader(
		       connection.getInputStream()));
	    }
	    catch (Exception e) {
		e.printStackTrace();
		showStatus("Unable to connect to Great Duck Island database!");
	    }

	    Vector rs = parseHttpInput(bin);

	    /*
	    String line;
	    while ( (line=bin.readLine()) != null)
		{
		    System.out.println(line);
		}
	    */

	    long baseTime = System.currentTimeMillis() - ((long)(4 * 86400 *1000));

	    java.util.Date date = new java.util.Date();
	    Calendar cal = Calendar.getInstance(
		   TimeZone.getTimeZone("America/Los_Angeles"),Locale.US);
	    int dow = cal.get(Calendar.DAY_OF_WEEK);
	    // Create the midnight point on GDI 
	    cal.set(Calendar.HOUR_OF_DAY, (24-3));
	    cal.set(Calendar.MINUTE, 0);
	    cal.set(Calendar.SECOND, 1);
	    
	    double ttm = (double) (cal.getTime().getTime() - baseTime);
	    System.out.println("Day of the week is "+dow);
	    

	    for (int d=4; d >= 0; d--) {
		System.out.println("Index: "+((dow-d+7)%7));
		plot.addXTick(DOW[(dow-d+7)%7], 
			      (ttm - (((double)d)* 86400.0 *1000.0)));
		System.out.println("Adding a tickmark at "+(ttm - (((double)d)* 86400.0 *1000.0)));
	    }

	    /*
	    for (int h = 0; h < 96; h++) {
		plot.addXTick("", (double) (h * 3600 *1000L));
	    }
	    */
	    boolean first = true;
	    
	    java.sql.Timestamp ctime;
	    double value;
	    int count = 0;
	    int nid;
	    int q;
	    
	    DataFilter filter = null;
	    if (readingType.equals("photo_reading"))
		filter = new PhotoFilter();
	    else if (readingType.equals("temp_reading"))
		filter = new I2CTemperatureFilter();
	    else if (readingType.equals("thermopile_reading"))
		filter = new ThermopileFilter();
	    else if (readingType.equals("humidity_reading"))
		filter = new HumidityFilter();
	    else if (readingType.equals("voltage_reading"))
		filter = new VoltageFilter();
	    else
		filter = new PhotoFilter();
	    filter.setYRange(plot);

	    ResultSetUsable rsu = new ResultSetUsable(rs);

	    while(rsu.next()) {
		nid =  rsu.getInt(1);
		long now = rsu.getLong(2);
		value = filter.filterData(rsu);
		
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
	    System.out.println(e);
	    showStatus("Connection failed: "+e.getMessage());
	}
    }
}

class ResultSetUsable {
    int index = -1;
    Vector main = null;
    Vector col1 = null;
    Vector col2 = null;
    Vector col3 = null;

    public ResultSetUsable(Vector main) {
	this.main = main;
	col1 = (Vector)main.elementAt(0);
	col2 = (Vector)main.elementAt(1);
	col3 = (Vector)main.elementAt(2);
    }

    public int getInt(int pos) {
	if (pos == 1)
	    return ((Integer)col1.elementAt(index)).intValue();
	if (pos == 2)
	    return 0;
	if (pos == 3)
	    return ((Integer)col3.elementAt(index)).intValue();
	return 0;
    }

    public long getLong(int pos) {
	if (pos == 2)
	    return ((Long)col2.elementAt(index)).longValue();
	return 0;
    }


    public boolean next() {
	index++;
	try {
	    Object j = col1.elementAt(index);
	}
	catch (ArrayIndexOutOfBoundsException e)
	{
	    return false;
	}
	return true;
    }
}
	

interface DataFilter {
    public double filterData(ResultSetUsable rs) throws SQLException;  
    public void setYRange(Plot plot); 
}

class VoltageFilter implements DataFilter {
    // returns voltage from 0 to 3.3V
    public double filterData(ResultSetUsable rs) throws SQLException {
	int val = rs.getInt(3);
	return (val * 3.3) / 256;
    }

    public void setYRange(Plot plot) {
	plot.setYRange(0, 3.3);
    }
}

class PhotoFilter implements DataFilter {
    // returns % light
    public double filterData(ResultSetUsable rs) throws SQLException {
	int val = rs.getInt(3);
	return (((double) val) / 4096.0) * 100.0;
    }
    public void setYRange(Plot plot) {
	plot.setYRange(0, 100.0);
    }
}


class HumidityFilter implements DataFilter {
    // returns % RH
    public double filterData(ResultSetUsable rs) throws SQLException {
	int val = rs.getInt(3);
	double value = (val*3.3)/4096;
	value = ((value - 1.43)/0.4)*100;
	return value;
    }
    public void setYRange(Plot plot) {
	plot.setYRange(0, 100.0);
    }

}

class ThermopileFilter implements DataFilter {
    // returns % RH
    public double filterData(ResultSetUsable rs) throws SQLException {
	int val = rs.getInt(3);
	double value = (val*3.3)/4096;
	value = (value - 0.7) / 0.155;
	return value;
    }
    public void setYRange(Plot plot) {
	plot.setYRange(-10, 20);
    }

}

class I2CTemperatureFilter implements DataFilter {
    // returns temperature value
    public double filterData(ResultSetUsable rs) throws SQLException {
	int val = rs.getInt(3);
	return (((double)val/8) * 0.0625);
    }
    public void setYRange(Plot plot) {
	plot.setYRange(0.0, 50.0);
    }
}

class ThermistorFilter implements DataFilter {
    // returns thermistor value
    public double filterData(ResultSetUsable rs) throws SQLException {
	int val = rs.getInt(3);
	return (double) val;
    }
    public void setYRange(Plot plot) {
	plot.setYRange(0, 4096.0);
    }
}
