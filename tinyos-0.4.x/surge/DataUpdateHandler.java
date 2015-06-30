import java.net.*;
import java.util.*;
import java.io.*;



class DataPacket{ 
   byte[] data;
   Date time;
   int packetNumber;
   DataPacket(byte[] raw_data){
	data = new byte[38];
	data[0] = raw_data[0];
	data[1] = raw_data[1];
	for(int i = 3; i < raw_data.length; i++){
		data[i-1]=raw_data[i];
	}
   }
	
   byte source() { return data[3];}
   int hop_count() { 
	int i;
	for(i = 0; i < 4 && data[i + 3] != 0; i ++){}
	return i+1;
   }
   int[] hop_array(){
	int hop_count = hop_count();
	int[] hop_array = new int[hop_count + 1];
	hop_array[0] = source();
	int i;
	for(i = 1; i <= hop_count; i ++){
		hop_array[i] = data[hop_count - i + 2];			
	}
	return hop_array;
   }

   int strength(int from, int to){
	int unknown;
	if(from == source()){
		unknown = to;
	}else if(to == source()){
		unknown = from;
	}else{
		return strength_metric(0);
	}
	int count = 0;
	for(int i = 0; i < 8; i++){
		if(unknown == (0xff & (int)data[2*i + 9])){
		//if(unknown == (0xff & (int)data[i + 12])){
			count ++;
		}
	}
	return strength_metric(count);
	   	
   }
	
   int strength_metric(int n){ 
	if(n == 0) return -1;
	else return (9-n)*20;
   }

   int[][] conn_array(){
	int i;
	//let's just brute force this.
	int[] edge_count = new int[256];
	int num_distinct = 0;
	for(i = 0; i < 8; i++){
		//if(0 == edge_count[0xff & (int)data[i + 12]] ++){
		if(0 == edge_count[0xff & (int)data[2*i + 9]] ++){
			num_distinct ++;
		}
	}
	int[][] conn_array = new int[num_distinct][2];
	int sofar = 0;
	for(i = 0; i < 256 && sofar < num_distinct; i ++){
		if(edge_count[i] > 0) {
			conn_array[sofar][0] = i;
			conn_array[sofar][1] = strength_metric(edge_count[i]);
			sofar ++;
		}
	}
	return conn_array;
   }
			

   //byte temp() { return (byte)data[8];}
   byte temp() { return 3;}
   byte light() { return (byte)((data[7] << 8 | data[8]) >> 2 & 0xff);}
   long time() {
	long seconds = 0;
	long milliseconds = 0;
	int i;
	seconds |= (((long)data[30]) & 0xff);
	seconds |= (((long)data[31]) & 0xff) << 8;
	seconds |= (((long)data[32]) & 0xff) << 16;
	seconds |= (((long)data[33]) & 0xff) << 24;
	//milliseconds |= (((long)data[34]) & 0xff);
	//milliseconds |= (((long)data[35]) & 0xff) << 8;
	//milliseconds |= (((long)data[36]) & 0xff) << 16;
	//milliseconds |= (((long)data[37]) & 0xff) << 24;
	milliseconds += seconds * 1000;
	return milliseconds;
   }
		
	
	

}

public class DataUpdateHandler implements Runnable{
	GraphPanel display;
	
	DataUpdateHandler(GraphPanel display){
		this.display = display;
		Thread t = new Thread(this);
		t.start();
	}

	public void run(){
		try{
		//new DataUpdateReceiver(this, new FileInputStream("foo.data"));	
		ServerSocket s = new ServerSocket(8765);
			while(true){
				Socket sock = s.accept();
				new DataUpdateReceiver(this, sock.getInputStream());
			}
		}catch(Exception e){
			e.printStackTrace();
		}
	}
	boolean debug = true;
	void update(byte[] data){
		//parse the input.
		int i= 0;
		Node n = display.getNode("" + data[1]);
	        DataPacket packet = new DataPacket(data);	
		synchronized(n.history){
			n.history.add(0, packet);
		}
		int source = packet.source();
		n.light = packet.light();
		n.temp = packet.temp();
		n.time = new Date(packet.time());
		n.time = new Date();
		packet.time = n.time;
		n.temp &= 0xff;
		n.light &= 0xff;
		//n.last_updated = new Date();
		n.last_updated = n.time;
		n.num_msgs ++;	
		packet.packetNumber = n.num_msgs;
	//get hop count;
		if(debug){
			for(i = 0; i < 38; i ++){
			  System.out.print(data[i] + ", ");
			}
			System.out.println();
		}
			
		int hop_count = packet.hop_count();
		int[] hop_array = packet.hop_array();
		if(debug) System.out.println("hop count: " + hop_count);
		if(debug){
		        for(i = 0; i <= hop_count; i ++){
			  System.out.print(hop_array[i] + ", ");
			  
			}
			System.out.println();
		}
		Node prev = n;
		for(i = 0; i < hop_count; i ++){
			Edge e = display.updateEdge("" + hop_array[i], ""+hop_array[i+1], packet.strength(hop_array[i], hop_array[i + 1]), n.time);
			e.num_on_path ++;
			Node end = display.getNode(""+hop_array[i+1]);
			//end.last_updated = new Date();
			end.last_updated = n.time;
			end.num_forward ++;
			prev.parent = end;
			prev = end;
		}

		int[][] conn_array = packet.conn_array();
		for(i = 0; i < conn_array.length; i++){
			if(conn_array[i][0] != 0){
				if(display.isNode("" + conn_array[i][0])){
					display.updateEdge(""+hop_array[0], ""+conn_array[i][0], conn_array[i][1], n.time);
				  System.out.println(""+hop_array[0]+ " "+conn_array[i][0] + " " +  conn_array[i][1] + " " +  n.time);
				}
			}
		}
			
			

	}

}


class DataUpdateReceiver implements Runnable{

boolean stop = false;   
DataUpdateHandler handler;
InputStream ins;
DataUpdateReceiver(DataUpdateHandler handle, InputStream instream){
	handler = handle;
	ins = instream;
	Thread t = new Thread(this);
	t.start();
}

public void run(){
    try{
	int count = 0;
	while(!stop){
		byte[] data = new byte[38];
		if(ins.read(data) <= 0) return;
		handler.update(data);
		count ++;
		//if(count % 20 == 0)
			Thread.sleep(100);
	}
  }catch(Exception e){
 	e.printStackTrace();
  }
}

   public void stop(){
	stop = true;
}

}




