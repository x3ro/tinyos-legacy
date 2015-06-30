

public class Filter_test{

	static double[] history;
	static int cnt;
	static void main(String[] args){
		history = new double[100];
		for(cnt = 0; cnt < 20; cnt ++){
			//System.out.println(i + " " + update(500));
			update(1);
		}
		double val = 0;
		for(cnt = 0; val < 490; cnt++) val = ((299 * val) + 500.00)/300;
		System.out.println(cnt);
	}
	static double update(double x){
	   for(int i = 0; i < 10; i ++){
		double prev = history[i];
		history[i] = (x + 1 * history[i])/2;
		x = history[i];
		System.out.print(x + ",");
		//if(x > 490 && prev <= 490) System.out.println(i + "," + cnt);
	   }
	   System.out.println();
	   return history[9];
	}
}
