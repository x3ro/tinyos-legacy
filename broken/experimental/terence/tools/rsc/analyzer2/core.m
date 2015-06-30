function varargout = core(varargin)
[varargout{1:nargout}] = feval(varargin{:});

% nodesID is an array of node id
% coor is 2 d array like [x1 y1; x2 y2; x3 y3];
% tablename is like hm_test30

function init(nodesID, coor, tablename, basestationID)
global rsc
clear global rsc
global rsc
% save the settings
rsc.nodesID = nodesID;
rsc.coor = coor;
rsc.tablename = tablename;
rsc.basestationID = basestationID;

% set up data base flags
setdbprefs('DataReturnFormat', 'numeric');
setdbprefs('ErrorHandling', 'report');
setdbprefs('NullNumberRead', '0');
setdbprefs('NullNumberWrite', '0');
setdbprefs('NullStringRead', '0');
setdbprefs('NullStringWrite', '0');

% connect to the database
db = database('rsc', 'Administrator', 'blah', 'org.postgresql.Driver', 'jdbc:postgresql://localhost/rsc');
rsc.db = db;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare html file function
function open_html
global rsc
temp_dir = tempdir;
[blah1, html_dir, blah2] = fileparts(tempname);
htmlfilename = 'index.html';
fullhtmlpath = [temp_dir html_dir '\' htmlfilename];
mkdir (temp_dir, html_dir);
filefid = fopen(fullhtmlpath, 'w');
rsc.filefid = filefid;
rsc.fullhtmlpath = fullhtmlpath;
rsc.dirpath = [temp_dir html_dir];
html_print('<html><head>');
html_print('<link rel="stylesheet" href="http://www-inst.eecs.berkeley.edu/~terence/style.css">');
html_print(['<title>' rsc.tablename '</title></head><body>']);
html_print('<h2>Routing Stack Statistic Report</h2>');

%% finish up with the html file and open a web browser
function close_html
global rsc
filefid = rsc.filefid;
fullhtmlpath = rsc.fullhtmlpath;
html_print('</body></html>');
fclose(filefid);
status = web(fullhtmlpath,'-browser');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% html writing helper function
function print_br 
global rsc
fprintf(rsc.filefid, '<br>'); 

function html_print(string)
global rsc
fprintf(rsc.filefid, [string]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% query the database
function result = fetch_data(query)
global rsc
% querying the database
curs = exec(rsc.db, query);
if (curs.Cursor == 0)
    error('Error Occur when trying to query database');
end
result = [];
curs = fetch(curs);
if strcmpi(curs.Data(1), 'No Data')
  result = [];
else 
  result = curs.Data;
end





