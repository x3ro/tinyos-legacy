import java.io.*;

public class MakeClock {

    public static void main(String[] args){

	PrintStream os = System.out;
	os.println("void clock_tickchar num, char* data){");
	os.println("#ifdef FULLPC");
	os.println("printf(\"got messaged number %d for dispatch\\n\", num);");
	os.println("#endif");
	
	String command = args[0] + " ";
	for(int i = 1; i < args.length; i++){
	    command += args[i] + " ";
	}
	command += " | grep clock_ticks_per_sec_ | grep -v U";

	//System.out.println("got comand ");
	//System.out.println(command);
	try{
	    Runtime runtime = Runtime.getRuntime();
	    Process process = runtime.exec(command);
	    InputStream SysinfoStream = process.getInputStream();
	    process.waitFor();
	    InputStreamReader isr = new InputStreamReader(SysinfoStream);
	    BufferedReader input = new BufferedReader(isr);
	    String data = input.readLine();
	     data = input.readLine();
	    int first = 1;
	    int count = 0;
	    int[] times = new int[400];
	    String[] names = new String[400];
	    try{
		while(data != null){
		    
		    if(data.indexOf("clock_ticks_per_sec_") > 0){
		    	os.println(data);
			times[count] = clockNumber(data);
			names[count] = clockName(data);
			count ++;
		    }
		    data = input.readLine();
		}
		for(int i = 0; i < count; i ++){
			os.println(names[i] + " : " + times[i]);
		}	
		int val = calcRange(times, count);
		os.println("calc: " + val);
		for(int i = 0; i < count; i ++){
			os.println(names[i] + " : " + val/times[i]);
		}	
	    }catch(Exception f){
		f.printStackTrace();
	    }
	    os.println("}");
	}catch(Exception e){
	    e.printStackTrace();
	}
    }
    static int clockNumber(String data){
	int start = data.indexOf("clock_ticks_per_sec_") +
	    "clock_ticks_per_sec_".length();
	System.out.println(data.substring(start));
	return Integer.parseInt(data.substring(start));
    }
    static String clockName(String data){
	int start =  data.indexOf("clock_ticks_per_sec_");
	String tmp = data.substring(0, start);
	int space = data.lastIndexOf(" ");
	
	return data.substring(space, start) + "clock_ticks_per_sec_" + clockNumber(data);
    }
	
    static int calcRange(int[] times, int count){
	int sofar = 1;
	int i = 0;
	for(i = 0; i < count; i ++){
		if(1 % times[i] != 0) sofar = 0;
	}
	if(sofar == 1) return 1;
	sofar = 1;
	for(i = 0; i < count; i ++){
		if(2 % times[i] != 0) sofar = 0;
	}
	if(sofar == 1) return 2;
	sofar = 1;
	for(i = 0; i < count; i ++){
		if(4 % times[i] != 0) sofar = 0;
	}
	if(sofar == 1) return 4;
	sofar = 1;
	for(i = 0; i < count; i ++){
		if(16 % times[i] != 0) sofar = 0;
	}
	if(sofar == 1) return 16;
	sofar = 1;
	for(i = 0; i < count; i ++){
		if(128 % times[i] != 0) sofar = 0;
	}
	if(sofar == 1) return 128;
	return 0;
   }
}
