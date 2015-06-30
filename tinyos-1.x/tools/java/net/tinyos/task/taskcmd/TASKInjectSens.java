package net.tinyos.task.taskcmd;

import net.tinyos.task.taskapi.*;
import java.util.*;

class TASKInjectSens
{
	private final static int DEFAULT_SAMPLE_PERIOD = 32768;
	public static void main(String argv[])
	{
		if (argv.length < 1)
		{
			System.out.println("please specify arguments: hostname [sample_period].");
			return;
		}
		try
		{
			TASKClient client = new TASKClient(argv[0]);
			int samplePeriod;
			if (argv.length > 1)
				samplePeriod = Integer.getInteger(argv[1]).intValue();
			else
				samplePeriod = DEFAULT_SAMPLE_PERIOD;
			TASKQuery sensorQuery;
			sensorQuery = client.getSensorQuery();
			if (sensorQuery != null)
			{
				System.out.println("reinjecting the currently running sensor query: " + sensorQuery.toSQL());
			}
			else
			{
				Vector selectEntries = new Vector(11);
				selectEntries.add(new TASKAttrExpr(client.getAttribute("nodeid")));
				selectEntries.add(new TASKAttrExpr(client.getAttribute("parent")));
				selectEntries.add(new TASKAttrExpr(client.getAttribute("voltage")));
				selectEntries.add(new TASKAttrExpr(client.getAttribute("humid")));
				selectEntries.add(new TASKAttrExpr(client.getAttribute("humtemp")));
				selectEntries.add(new TASKAttrExpr(client.getAttribute("press")));
				selectEntries.add(new TASKAttrExpr(client.getAttribute("prtemp")));
				selectEntries.add(new TASKAttrExpr(client.getAttribute("taostop")));
				selectEntries.add(new TASKAttrExpr(client.getAttribute("taosbot")));
				selectEntries.add(new TASKAttrExpr(client.getAttribute("hamatop")));
				selectEntries.add(new TASKAttrExpr(client.getAttribute("hamabot")));
				sensorQuery = new TASKQuery(selectEntries, new Vector(), samplePeriod, null);
				System.out.println("injecting default sensor query: " + sensorQuery.toSQL());
			}
			if (client.submitSensorQuery(sensorQuery) == TASKError.SUCCESS)
				System.out.println("sensor query successfully submitted.");
			else
				System.out.println("sensor query submission failed.");
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
	}
}
