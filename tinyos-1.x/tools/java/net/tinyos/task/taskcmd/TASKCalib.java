package net.tinyos.task.taskcmd;

import net.tinyos.task.taskapi.*;

class TASKCalib
{
	public static void main(String argv[])
	{
		if (argv.length < 1)
		{
			System.out.println("Please specify hostname.");
			return;
		}
		try
		{
			TASKClient client = new TASKClient(argv[0]);
			client.collectCalibration();
			System.out.println("calibration query returned.");
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
	}
}
