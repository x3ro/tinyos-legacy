import java.io.*;

public class Fix_up{
	public static void main(String args[]){
	   try{
		InputStream f = new FileInputStream("foo.data");

		byte[] data = new byte[30];
	     while(-1 != f.read(data, 0, 30)){
//		for(int i = 0; i < 10; i ++){ System.out.print(data[i] + ",");}
		int j = 0;
		j = data[8] << 8 | data[9];
		j &= 0x3ff;
		System.out.println(j);
		}
	   }catch (Exception e){
	
		e.printStackTrace();
	  }
	

	}
}
