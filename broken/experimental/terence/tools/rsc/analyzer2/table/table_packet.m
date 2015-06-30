function output = table_packet(varargin)
output = feval(varargin{:});

function result = byte_offset(field)
tp = TablePacket;
size = eval(['tp.size_' field]);
if (size == 1) 
  result = num2str(eval(['tp.offset_' field]));
  result = ['(b' result ')'];
elseif (size == 2)
  firstoffset = eval(['tp.offset_' field]);
  result = ['(b' num2str(firstoffset) ' + ' 'b' num2str(firstoffset + 1) ' * 256)'];
end

function result = type_filter
tp = TablePacket;
amtype_offset = num2str(tp.offset_amtype);
amtype = num2str(tp.AM_TYPE);
result = ['b' amtype_offset ' = ' amtype];


function result = report
global rsc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% typical experiment setting
[nodesID, coor, basestationID] = hearst_setting;
tablename = 'hm_test36';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

core('init', nodesID, coor, tablename, basestationID);
global rsc
core('open_html');
estimate('init');

global rsc
for i = 1:length(rsc.nodeIdx)
  estimate('caption_send_est', i);
  pic_name = estimate('graph_send_est', i);
  plotlib('snap_pic', pic_name);
  estimate('caption_receive_est', i);
  pic_name = estimate('graph_receive_est', i);
  plotlib('snap_pic', pic_name);
  estimate('caption_cost', i);
  pic_name = estimate('graph_cost', i);
  plotlib('snap_pic', pic_name);
end
core('close_html');
result = -1;




