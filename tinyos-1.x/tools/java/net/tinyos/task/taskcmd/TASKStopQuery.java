package net.tinyos.task.taskcmd;

import net.tinyos.task.taskapi.*;

class TASKStopQuery
{
	public static void main(String argv[])
	{
		if (argv.length < 2)
		{
			System.out.println("specify arguments: hostname {sensor|health|<queryid>}");
			return;
		}
		try
		{
			TASKClient client = new TASKClient(argv[0]);
			if (argv[1].equalsIgnoreCase("sensor"))
			{
				if (client.stopSensorQuery() == TASKError.SUCCESS)
					System.out.println("sensor query stop request successfully sent.");
				else
					System.out.println("sensor query stop request failed.");
			}
			else if (argv[1].equalsIgnoreCase("health"))
			{
				if (client.stopHealthQuery() == TASKError.SUCCESS)
					System.out.println("health query stop request successfully sent.");
				else
					System.out.println("health query stop request failed.");
			}
			else
				System.out.println("unknown query type.");
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
	}
}
