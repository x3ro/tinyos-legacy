<html><head><title>Messages</title></head><body>
<%
 c = http_get_argcount();
 dc = 0;
 
 for ( i = 0 ; i < c ; i+= 1) {
   if ( http_get_argname(i) == "d") {
     num = atoi(http_get_argvalue(i));
     msg_delete(num - dc);
     dc += 1;
   }
 }

 s = http_get_valuebyname("msg");

 if (s) {
   print "<p bgcolor='#ffcccc'>Message added:", s, "</p>";
   msg_add(s);
 }

 n = msg_count();
%>
<h1>Messages</h1>
<form action='msg.tsp' method='GET'><table>
<%
  for ( i = n - 1 ; i >= 0 ; i-=1 ) {
    print "<tr><td><input type='checkbox' name='d' value='", i, "' /></td><td>", i + 1, "</td>";
    print "<td>";
    pmode(1);
    print msg_get_text(i);
    pmode(0);
    print "</td><td>", "%u" % msg_get_id(i), "</td></tr>\n";
  }
%>
</table>
<input type='submit' value='Delete checked' />
</form>
<h2>Add a message</h2>
<form action='msg.tsp' method='GET'>
<input type='text' name='msg' size='40' maxlength='40' />
<input type='submit' value='Submit' />
</form>
<p><a href='msg.tsp'>Refresh</a> this page</p>
</body></html>