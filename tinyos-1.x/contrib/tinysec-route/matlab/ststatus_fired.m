function ret = ststatus_fired()
global ststatus_fired_arg_nodes;
global ststatus_fired_i;
global ststatus_TIMER;
global TopologyGraph;
global BASEDIR;

ststatus_fired_i = ststatus_fired_i + 1;
if(ststatus_fired_i <= length(ststatus_fired_arg_nodes))
    for j = 1:3
        peg(ststatus_fired_arg_nodes(ststatus_fired_i),'ststatus');
        pause(1)
    end
end


% wait for after final one
if(ststatus_fired_i > length(ststatus_fired_arg_nodes))
    stop(ststatus_TIMER);
    filenametxt = sprintf('%s/TopologyGraph.txt',BASEDIR);
    filenamemat = sprintf('%s/TopologyGraph.mat',BASEDIR);
    compressedTopologyGraph = TopologyGraph(find(TopologyGraph(:,1) > 0),:);
    save(filenamemat,'TopologyGraph');
    save(filenametxt,'compressedTopologyGraph','-ASCII');
    disp('resetting backoff to 3,1')
    for j=1:3
        peg all backoffBase(3)
        peg all backoffMask(1)
        pause(1)
    end
    TopologyGraph(find(TopologyGraph(:,1) > 0),:)
    drawtopo(TopologyGraph(find(TopologyGraph(:,1) > 0),:))    
end

ret = 1;
