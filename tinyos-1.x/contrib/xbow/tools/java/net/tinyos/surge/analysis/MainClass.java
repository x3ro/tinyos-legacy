import java.io.*;
import java.util.*;

public class MainClass{



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
		long start = data.start_time[0];;
		long end = data.end_time[0];;
		long step = (end - start)/100;
		System.out.print(",");
		for(int j = 0; j < 100; j ++){
			System.out.print(new Date(start + (long)(j*step)));
			System.out.print(",");
		}
		System.out.println(",");
		for(int i = 0; i < 15; i ++){
			System.out.print( i + ", ");
			for(int j = 0; j < 100; j ++){
				System.out.print(data.timeAverage(i, start + j * step, start + (j+1) * step));
				System.out.print(",");
			}
			System.out.println();
		}

	}



}
