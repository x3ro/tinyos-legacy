function stopVisTimer
% start a timer, to refresh the graphics

global VIS;

if ~isfield(VIS,'timer') | isempty(VIS.timer)
  return
end


stop(VIS.timer);
delete(VIS.timer);
VIS.timer = [];
