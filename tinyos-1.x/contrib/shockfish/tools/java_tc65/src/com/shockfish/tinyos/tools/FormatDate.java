package com.shockfish.tinyos.tools;

import java.util.Calendar;
import java.util.Date;
import java.lang.String;

public class FormatDate {


	public FormatDate () {
	}
	
	public static String GetATCCLKformat (Date date) {
		Calendar calendar=Calendar.getInstance();
		calendar.setTime(date);
		//System.out.println(date);
		String dateFormatted=new String("");
		
		dateFormatted=dateFormatted.concat(String.valueOf(calendar.get(Calendar.YEAR)).substring(2,4));
		dateFormatted=dateFormatted.concat("/");
		dateFormatted=dateFormatted.concat(CheckNumber(calendar.get(Calendar.MONTH)+1));
		dateFormatted=dateFormatted.concat("/");
		dateFormatted=dateFormatted.concat(CheckNumber(calendar.get(Calendar.DAY_OF_MONTH)));
		dateFormatted=dateFormatted.concat(",");
		dateFormatted=dateFormatted.concat(CheckNumber(calendar.get(Calendar.HOUR_OF_DAY)));
		dateFormatted=dateFormatted.concat(":");
		dateFormatted=dateFormatted.concat(CheckNumber(calendar.get(Calendar.MINUTE)));
		dateFormatted=dateFormatted.concat(":");
		dateFormatted=dateFormatted.concat(CheckNumber(calendar.get(Calendar.SECOND)));
		
		
		return dateFormatted;
	}
	
	private static String CheckNumber (int data) {
		String number = new String("");
		if (data<10) {
			number=number.concat("0");
		}
		number=number.concat(String.valueOf(data));
		return number;
	}


}
