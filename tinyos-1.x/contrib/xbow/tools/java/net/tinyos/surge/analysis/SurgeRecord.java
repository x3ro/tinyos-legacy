
import java.util.*;

public class SurgeRecord{
Date time;
int msg_number;
int delay;
int parent;
int hopcount;
int nodeNumber;
int reading;
int batt;
SurgeNeighborInfo neighbors[];


String raw_data;
SurgeRecord(){
	neighbors = new SurgeNeighborInfo[5];
	for(int i = 0; i < 5; i ++) neighbors[i] = new SurgeNeighborInfo();
}

class StringChopper{
String data;
StringChopper(String val){data = val;}
String next(){
	if(data.length() == 0) return "";
	int pos = data.indexOf('#');
	String ret = data.substring(0, pos);
	data = data.substring(pos + 1);	
	return ret;

}

}
SurgeRecord(String data){
	neighbors = new SurgeNeighborInfo[5];
	StringChopper str = new StringChopper(data);
	for(int i = 0; i < 5; i ++) neighbors[i] = new SurgeNeighborInfo();
	nodeNumber = Integer.parseInt(str.next());
	msg_number = Integer.parseInt(str.next());
	str.next();
	time = new Date(Long.parseLong(str.next()));
	delay  = Integer.parseInt(str.next());
	parent  = Integer.parseInt(str.next());
	str.next();
	msg_number  = Integer.parseInt(str.next());
	hopcount  = Integer.parseInt(str.next());
	reading  = Integer.parseInt(str.next());
	batt  = Integer.parseInt(str.next());
	int rec_count = 5;
	for(int i = 0; i < rec_count && str.data.length() > 1; i ++){
		neighbors[i].id = Integer.parseInt(str.next());
		neighbors[i].depth = Integer.parseInt(str.next());
		neighbors[i].quality = Float.parseFloat(str.next());
	}

}


public String toString(){
	String val = "Node ID: " + nodeNumber + "\n";
	val += "Message ID: " + msg_number + "\n";
	val += "Hopcount : " + hopcount + "\n";
	val += "Delay : " + delay + "\n";
	val += time + " " ;
	val += time.getTime();
	return val;

}


}
