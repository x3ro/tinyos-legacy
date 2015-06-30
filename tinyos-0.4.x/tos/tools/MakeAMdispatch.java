import java.io.*;

public class MakeAMdispatch {

    public static void main(String[] args){

	PrintStream os = System.out;
	os.println("#include \"super.h\"");
	os.println("void AM_MSG_REC(char num, char* data){");
	os.println("#ifdef FULLPC");
	//os.println("printf(\"got messaged number %d for dispatch\\n\", num);");
	os.println("#endif");
	
	String command = args[0] + " ";
	for(int i = 1; i < args.length; i++){
	    command += args[i] + " ";
	}
	command += " | grep AM_msg_handler | grep -v U";

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
	    try{
		while(data != null){
		    
		    //os.println(data);
		    if(data.indexOf("AM_msg_handler") > 0){
			int num = handlerNumber(data);
			//	os.println("...");
			if(first == 0){
				os.print("else ");
			}
			first = 0;
			os.println("if(num == " + num+"){");
			os.println("        TOS_EVENT(AM_MSG_HANDLER_"+num+")(data);");
			os.println("}");
		    }
		     data = input.readLine();
		}
	    }catch(Exception f){
		f.printStackTrace();
	    }
	    os.println("}");
	}catch(Exception e){
	    e.printStackTrace();
	}
    }
    static int handlerNumber(String data){
	int start = data.indexOf("AM_msg_handler") +
	    "AM_msg_handler".length() + 1;
	int end = data.indexOf("_EVENT", start);
	return Integer.parseInt(data.substring(start, end));
    }
}
