<html><head><title>Function test</title></head><body>
<p>This page is for some generic function testing</p>
<table>
<%
   a = "20";
   b = atoi(a);

   print "<tr><td>a = '20';</td><td>a = ", a, "</td></tr>\n";
   print "<tr><td>b = atoi(a);</td><td>b = ", b, "</td></tr>\n";
   print "<tr><td>intp(a) = ", intp(a), "</td></tr>\n";
   print "<tr><td>intp(b) = ", intp(b), "</td></tr>\n";
   print "<tr><td>stringp(a) = ", stringp(a), "</td></tr>\n";
   print "<tr><td>stringp(b) = ", stringp(b), "</td></tr>\n";
%>
</table>
</body></html>