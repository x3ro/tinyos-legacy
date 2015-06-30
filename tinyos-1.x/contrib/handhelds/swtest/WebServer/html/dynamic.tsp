<html><head><title>Dynamic page</title></head><body>
This is a dynamic page that calculates fibonacci numbers
<table cellpadding='0' cellborder='0'><tr><th>#</th><th>Value</th></tr>
<%
a = 1;
b = 1;

for ( i = 2 ; i <= 20 ; i+=1 ) {
    sum = a + b;
    a = b;
    b = sum;
    if ( i % 2 )
       c = "#aaaaaa";
    else 
       c = "#ffff22";

    print "<tr bgcolor='", c, "'><td>", i, "</td><td>", sum, "</td></tr>";
}

%>
</table>
</body></html>