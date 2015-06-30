package net.tinyos.task.taskcmd;

import net.tinyos.task.taskapi.*;
import java.util.Vector;

class TASKReset
{
	public static void main(String argv[])
	{
		if (argv.length < 1)
		{
			System.out.println("specify arguments: hostname");
			return;
		}
		try
		{
			TASKClient client = new TASKClient(argv[0]);
			short moteId = -1;
			if (argv.length > 1)
				moteId = (short)Integer.getInteger(argv[1]).intValue();
			TASKCommand cmd = new TASKCommand("reset", new Vector(0), moteId);
			if (client.submitCommand(cmd) == TASKError.SUCCESS)
				System.out.println("reset command successfully sent.");
			else
				System.out.println("reset command send failed.");
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
	}
}
