<html>
<head><title>Test page title</title></head>
<body>
<h1>Header 1</h1>
<image src='topic_metro.gif'>
<p>
<% count = msg_count(); %>
You have <% print count; %> messages.
<table>
<%
count = msg_count();
for ( i = 0 ; i < count ; i+= 1 ) {
    print "<tr><td>", msg_value(i), "</td><td>", msg_date(i), "</td></tr>\n";
}
%>
</table>
<p>There is <a href='other.htm'>another</a> page</p>
</body>
</html>