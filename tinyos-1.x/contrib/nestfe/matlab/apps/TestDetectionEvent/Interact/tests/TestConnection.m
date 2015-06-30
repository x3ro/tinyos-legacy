function TestConnection()

precision = 4;

server = Connection( '' , 7000 , 7001 , precision );
client = Connection( '' , 7001 , 7000 , precision );


TestInfo( server , client , 'catdog' , precision );
TestInfo( server , client , 3 , precision );
TestInfo( server , client , rand(9,1) , precision );
TestInfo( server , client , rand(1,5) , precision );
TestInfo( server , client , magic(5) , precision );


server = close( server );
client = close( client );



function TestInfo( server , client , A , precision )

success = false;
maxError = 0;
try 
    disp(['Testing data of class ' class(A) ])
    server = send( server , A );
    [client,info] = recv( client );
    
    if isa( info , 'char' ) && strcmp( info , A )
	success = true;
    elseif isa( info , 'numeric' )
	error = abs(A - info);
	maxError = max( error(:) );
	if maxError.*10^precision < 1
	    success = true;
	end
    end
catch
    lasterr
end


if success
    disp([ '>>> passed , max error: ' num2str(maxError) ' <<<']);
else
    disp([ '>>> FAILED , max error: ' num2str(maxError) ' <<<']);
end
