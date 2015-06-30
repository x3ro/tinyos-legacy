import java.util.*;

public class MoteHistory{


	Vector[] data;
	long start_time[];
	long end_time[];

	MoteHistory(){
		start_time = new long[256];
		end_time = new long[256];
		data = new Vector[256];
	}

	public void add(SurgeRecord rec){
	    int node = rec.nodeNumber;
	    if(node > 255) return;
	    if(data[node] == null) data[node] = new Vector(500, 5000);
	    if(start_time[node] == 0) start_time[node] = rec.time.getTime();
	    SurgeRecord last = null;
	    if(data[node].size() > 0) {
		last = (SurgeRecord)data[node].get(data[node].size()-1);
	        if(last.msg_number == rec.msg_number){
			return;
		}
	    }
	    data[node].add(rec);
	    end_time[node] = rec.time.getTime();
	    //check to make sure this rec isn't identical to the last one.
	    if(last == null) return;
	    int i;
	    for(i = 0; i < 5; i ++){
		if(rec.neighbors[i].id != last.neighbors[i].id) i = 10;
		else if(rec.neighbors[i].quality != last.neighbors[i].quality) i = 10;
		else if(rec.neighbors[i].depth != last.neighbors[i].depth) i = 10;
	    }
	    if(i == 5){
		rec.neighbors = last.neighbors;
	    }
	}


	public double average(int nodeId){	
	    if(data[nodeId] == null) return 0.0;
	    return average(nodeId, 0, data[nodeId].size());
	}


	public double timeAverage(int nodeId, long start, long end){
		return average(nodeId, index(nodeId, start), index(nodeId, end));


	}
	public double PrinttimeAverage(int nodeId, long start_a, long end_a){
		int start = index(nodeId, start_a);
		int end = index(nodeId, end_a);
		int first = 0;
		int count = 0;
		int last = 0;
		System.out.print(nodeId + "\t" );
		System.out.print(start_a + "\t");
		System.out.print(start + "\t");
		System.out.print(end_a + "\t");
		System.out.print(end + "\t");
		if(data[nodeId] == null){ System.out.println(); return 0.0;}
		if(start >= end) {System.out.println(); return 0.0;}
		if(end >= data[nodeId].size()) end = data[nodeId].size() - 1;
		SurgeRecord first_rec = (SurgeRecord)data[nodeId].get(start);
		SurgeRecord last_rec = (SurgeRecord)data[nodeId].get(end);
		count = end -start + 1;
		last = last_rec.msg_number;
		first = first_rec.msg_number;
		System.out.print(last + "\t");
		System.out.print(first + "\t");
		System.out.print(count + "\t");
		System.out.println((last-first + 1));
		return ((double)count)/((double)(last-first + 1));
	

	}
	public double average(int nodeId, int start, int end){
		int first = 0;
		int count = 0;
		int last = 0;
		if(data[nodeId] == null) return 0.0;
		if(start >= end) return 0.0;
		if(end >= data[nodeId].size()) end = data[nodeId].size() - 1;
		SurgeRecord first_rec = (SurgeRecord)data[nodeId].get(start);
		SurgeRecord last_rec = (SurgeRecord)data[nodeId].get(end);
		count = end -start + 1;
		last = last_rec.msg_number;
		first = first_rec.msg_number;
		return ((double)count)/((double)(last-first + 1));
	

	}

	boolean check(Vector d, int i, long time){
		
		if(i >= d.size() - 1) return true;
		if(i == 0) return true;
		SurgeRecord a = (SurgeRecord)d.get(i);
		SurgeRecord b = (SurgeRecord)d.get(i + 1);
		if(a.time.getTime() <= time && b.time.getTime() > time) return true;
		return false;
		
	}

	public SurgeRecord getByTime(int id, long time){
		if(data[id] == null) return null;
		return (SurgeRecord)data[id].get(index(id, time));
	}

	public int index(int id, long time){
		Vector d = data[id];
		if(d == null) return 0;
		int max = d.size();
		//binary search
		int current = max/2;
		int step = max/4;
		while(!check(d, current, time)){
			long val = ((SurgeRecord)(d.get(current))).time.getTime();
			if(val < time) current += step;
			else current -= step;
			step = step /2;
			if(step < 1) step = 1;
		}
		return current;
	}

}
