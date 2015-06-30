function drawtopo(TopologyGraph)
   figure
   hold on
   for i=1:size(TopologyGraph, 1)
       p = xypos(TopologyGraph(i,1));
       text(p(1) + .4, p(2) + .4, sprintf('%d(%d)', TopologyGraph(i,1),TopologyGraph(i,3)));
       pp = xypos(TopologyGraph(i,2));
       h = line([p(1) pp(1)], [p(2) pp(2)]);
       set(h, 'Marker', '.');
   end
   hold off
   axis([150 200 0 20])    
       
function pos = xypos(nodenum) 
   nodenum = nodenum -1;
   xpos = floor((nodenum / 4)) + 1;
   ypos = (mod(nodenum, 4)) ;
   pos = [xpos * 6 ypos * 6 + 1 ];