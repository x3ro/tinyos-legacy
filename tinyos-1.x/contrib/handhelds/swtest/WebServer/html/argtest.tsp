<html><head><title>Argument test</title></head><body>
<p>This page is for testing my argument extraction functions</p>
<%
 c = http_get_argcount();
%>
<p>Number of arguments: '<% print c; %>'</p>
<%
 if ( c > 0 ) {
  print "<table border='1'><tr><th>Name</th><th>Value</th></tr>";

   for ( i = 0 ; i < c ; i+=1 ) {
    print "<tr><td>", http_get_argname(i), "</td>";
    print "<td>", http_get_argvalue(i), "</td></tr>\n";
   }  
  print "</table>";
}
%>
<p>Checking for a 'dog' argument: 
<%
  d = http_get_valuebyname("dog");
  print d;
%>
</p>
</body></html>