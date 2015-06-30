import java.io.*;
import java.util.*;

public class HopCount{



	public static void main(String args[]) {
	MoteHistory data = new MoteHistory();
	
	 
	InputStreamReader in = new InputStreamReader(System.in);
	BufferedReader read = new BufferedReader(in);

	try{
		int count = 0;
	   while(in.ready()){
		SurgeRecord r = new SurgeRecord(read.readLine());
		data.add(r);
		//if(count % 1000 == 0) System.out.println(count);
		count ++;
	
	   }
	}catch(Exception e){
		e.printStackTrace();
	}
		int j;
		int last_hopcount = 0;
		for(int i = 0; i < 15; i ++){
			int count = 0;
			j = 0;
			for(j = 0; j < data.data[i].size(); j ++){
				SurgeRecord r = (SurgeRecord)data.data[i].get(j);
				if(last_hopcount != r.hopcount) count ++;
				last_hopcount = r.hopcount;
			}
			System.out.print(i + ": ");
			System.out.print(count + ": ");
			System.out.print(j + ": ");
			System.out.println();
		}

	}



}
