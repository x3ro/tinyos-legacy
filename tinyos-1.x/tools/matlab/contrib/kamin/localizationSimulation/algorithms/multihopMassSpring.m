function t = multihopMassSpring(t)
%t = massSpring(t)
%
%This function repeatedly applies forceResolution to all nodes.  Note that
%forceResolution uses multi-hop distances

error(2) = 0;
error(1) = -1;
iter=0;
while error(2)-error(1) > .1
    t = forceResolution(t);
    error(2)=error(1);
    error(1)=findLocationError(t);
    iter=iter+1;
    disp(error(1))
    disp(iter)
end
