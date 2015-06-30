function value = statistic(varargin)
value = feval(varargin{:});

function result = epoch_offset()
result = 'extract(epoch from time)';

function result = byte_offset(field)
sp = StatPacket;
size = eval(['sp.size_' field]);
if (size == 1) 
  result = num2str(eval(['sp.offset_' field]));
  result = ['(b' result ')'];
elseif (size == 2)
  firstoffset = eval(['sp.offset_' field]);
  result = ['(b' num2str(firstoffset) ' + ' 'b' num2str(firstoffset + 1) ' * 256)'];
end

function result = type_filter
sp = StatPacket;
amtype_offset = num2str(sp.offset_amtype);
amtype = num2str(sp.AM_TYPE);
result = ['b' amtype_offset ' = ' amtype];

function output = execute(module)
eval([module '(''init'');']);
pic_name = eval([module '(''graph'');']);
eval([module '(''caption'');']);
plotlib('snap_pic', pic_name);
output = -1;

function output = report

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% typical experiment setting
[nodesID, coor, basestationID] = hearst_setting;
tablename = 'hm_test36';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

core('init', nodesID, coor, tablename, basestationID);
% core('open_html');
% execute('data_generated');
% execute('data_received');
% execute('success_rate');
% execute('success_rate_distance');
% execute('avg_retransmission');
% execute('avg_retransmission_distance');
% execute('invalid_parent');
% execute('avg_hop');
% execute('hop_distance');
% execute('cycles');
% execute('hop_contour');
% execute('packet_transmission_distance');
% execute('topology');
execute('stability');
% core('close_html');
output = -1;
