import java.io.*;
import java.util.*;

public class Stats{



	public static void main(String args[]) {
	MoteHistory data = new MoteHistory();
	
	 
	InputStreamReader in = new InputStreamReader(System.in);
	BufferedReader read = new BufferedReader(in);
		int[] forwarded = new int[15];

	try{
		int count = 0;
		int first = 0;
		Thread.sleep(3000);
	   while(1 == 1){
		if(first == 0){
			 read.readLine();
			 Thread.sleep(1000);
		} else{
			String s = read.readLine();
			 //read.readLine();
			//System.out.println(s);
			SurgeRecord r = new SurgeRecord(s);
			data.add(r);
			count ++;
		}
		first = 1;
	
	   }
	}catch(Exception e){
	}
		int j;
			System.out.print("Node Number" + ": ");
			System.out.print("Packets Received"+ ": ");
			System.out.print("Packets Sent" + ": ");
			System.out.print("Success Rate" + ": ");
			System.out.print("Parent Changes" + ": ");
			System.out.print("Level Changes" + ": ");
			System.out.print("Average Level" + ": ");
			System.out.print("Duty Cycle" + ": ");
			System.out.print("Battery Voltage" + ": ");
			System.out.println();
		for(int i = 0; i < 500; i ++){
	try{
			int parent_change = 0;
			long level_count = 0;
			long level_sum = 0;
			int last_parent = 0;
			int last_hopcount = 0;
			double min_quality = 100;
			j = 0;
			SurgeRecord first = (SurgeRecord)data.data[i].get(0);
			SurgeRecord r = null;
			for(j = 0; j < data.data[i].size(); j ++){
				r = (SurgeRecord)data.data[i].get(j);
				if(last_hopcount != r.hopcount) level_count ++;
				last_hopcount = r.hopcount;
				level_sum += r.hopcount;
				if(last_parent != r.parent) parent_change ++;
				last_parent = r.parent;
				if(min_quality > r.neighbors[0].quality && r.neighbors[0].quality > 0) min_quality=r.neighbors[0].quality;

				//walk the parent tree...
				SurgeRecord p = r;
				while(p.parent != 0x7e){
					forwarded[p.nodeNumber] ++;
					p = data.getByTime(p.parent, p.time.getTime());
				}
			}
			//double sent = (double)data.data[0].size();
			j = data.data[i].size();
			double sent = (double)(r.msg_number - first.msg_number) + 1;
			System.out.print(i + ": ");
			System.out.print(j + ": ");
			System.out.print((int)sent + ": ");
			//System.out.print(r.msg_number + " " );
			//System.out.print(first.msg_number + " " );
			System.out.print(((double)j)/sent + ": ");
			System.out.print(parent_change + ": ");
			System.out.print(level_count + ": ");
			System.out.print((((double)level_sum)/(double)j) + ": ");
			System.out.print(100.0 * ((double)r.reading/(double)r.msg_number)/2.0/180.0*8.0 + ": ");
			//System.out.print(""+ r.msg_number);
			double volt = 1.25 * 1023.0/(double)r.batt;
			System.out.print(volt);
			System.out.println();
	

	}catch (Exception e){

	
	}
	}
		for(int jt = 0; jt < 14; jt ++){
			System.out.print(jt + ":");
			System.out.print(forwarded[jt]);
			System.out.println();

		}
}


}
