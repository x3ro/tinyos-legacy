import java.util.*;
import java.text.*;


public class DateToString
{
    private static final DateFormat dateFormatLocal = new SimpleDateFormat("yyyy-MM-dd_HH.mm.ss.SSS_z");
    private static final DateFormat dateFormatGMT = new SimpleDateFormat("yyyy-MM-dd_HH.mm.ss.SSS_z");
    static {dateFormatGMT.setTimeZone(TimeZone.getTimeZone("GMT"));}


    static public String dateToString(Date date, boolean toGMT)
    {
        if (toGMT)
            return dateFormatGMT.format(date);
        else
            return dateFormatLocal.format(date);
    }    
}
