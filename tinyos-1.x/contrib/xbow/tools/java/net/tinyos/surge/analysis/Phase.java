import java.io.*;
import java.util.*;

public class Phase{



	public static void main(String args[]) {
	MoteHistory data = new MoteHistory();
	
	 
	InputStreamReader in = new InputStreamReader(System.in);
	BufferedReader read = new BufferedReader(in);

	try{
		int count = 0;
		read.readLine();
	   while(in.ready()){
		SurgeRecord r = new SurgeRecord(read.readLine());
		data.add(r);
		//if(count % 1000 == 0) System.out.println(count);
		count ++;
	
	   }
	}catch(Exception e){
		e.printStackTrace();
	}
	try{

		int num_nodes = 14;
		long base_time = 0;
	    for(int j = 0; ;j ++){
		for(int i = 0; i < num_nodes; i ++){
			if(i == 0) {
				SurgeRecord base = (SurgeRecord)data.data[i].get(j);
				base_time = base.time.getTime();
				//System.out.print(base_time%180000);
			}else{

				SurgeRecord r = data.getByTime(i, base_time);
				long node_time = r.time.getTime();
				if(base_time - node_time > 180000 ||
				   node_time - base_time > 180000)
					node_time -= 10000;
				//else
					//System.out.print(node_time%180000);
				System.out.print((base_time - node_time)%180000);
				System.out.print("#");
				
			}

		}
		System.out.println("");
	     }

	}catch (Exception e){}

	}



}
