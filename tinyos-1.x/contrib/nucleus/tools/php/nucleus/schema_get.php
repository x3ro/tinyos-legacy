<font size=+1>Configure your Nucleus Network</font>

<form enctype="multipart/form-data" action="schema_set.php" method="POST">
    <!-- MAX_FILE_SIZE must precede the file input field -->
    <input type="hidden" name="MAX_FILE_SIZE" value="300000" />
    <!-- Name of input element determines name in $_FILES array -->
    Please upload your <b>Nucleus</b> schema file: <input name="schemaFile" type="file" />
    <p>
    Send queries using: <br>
    <input type="radio" name="sendQuery" value="drip">Drip Dissemination<br> 
    <input type="radio" name="sendQuery" value="local">Local Radio or Serial Connection<br>
    <p>
    Receive results over: <br>
    <input type="radio" name="receiveResults" value="drain">Drain Tree<br> 
    <input type="radio" name="receiveResults" value="local">Local Radio<br> 
    <input type="radio" name="receiveResults" value="serial">Serial Connection<br>     
    <p>
    <input type="submit" value="Go" />
</form>

