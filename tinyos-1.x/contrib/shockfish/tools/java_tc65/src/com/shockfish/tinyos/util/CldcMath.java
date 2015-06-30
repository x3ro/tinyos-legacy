package com.shockfish.tinyos.util;

public class CldcMath {

	// TODO this implementation should check for NaN
	public static double pow(double a, int b) {
		double r = 1;
		for (int i=0;i<Math.abs(b);i++) {
			r = r * a;	
		}
		if (b<0)
			return 1/r;
		return r;
	}
	
}
