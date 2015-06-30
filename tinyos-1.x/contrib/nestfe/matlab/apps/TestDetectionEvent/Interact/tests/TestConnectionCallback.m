function TestConnectionCallback()

precision = 4;

server = Connection( '' , 7000 , 7001 , precision );
client = Connection( '' , 7001 , 7000 , precision , @TestConnectionCallbackFcn );


TestInfo( server , client , 'catdog' , precision );
%TestInfo( server , client , 3 , precision );
%TestInfo( server , client , rand(9,1) , precision );
%TestInfo( server , client , rand(1,5) , precision );
%TestInfo( server , client , magic(5) , precision );


pause;
server = close( server );
client = close( client );



function TestInfo( server , client , A , precision )

try 
    disp(['Testing data of class ' class(A) ])
    server = send( server , A );
catch
    lasterr
end

