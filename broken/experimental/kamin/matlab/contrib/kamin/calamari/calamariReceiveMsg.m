function calamariReceiveMsg(address,msg)
global locID loc locStdv distRxrID distTxrID dist distStdv 
if(msg.getClass.toString=='class net.tinyos.calamari.LocalizationDebugMsg')
    %store the positions and position stdvs
    locID = union(locIDs, msg.get_myID);
	loc(msg.get_myID,[1 2]) = [msg.get_loc_pos_x msg.get_loc_pos_y];
	locStdv(msg.get_myID,[1 2]) = [msg.get_loc_stdv_x msg.get_loc_stdv_y];
elseif(msg.getClass.toString=='class net.tinyos.calamari.distDebugMsg')
	%store the distances and distance stdvs
    distRxrID = union(distRxrIDs, msg.get_myID);
	distTxrID = union(distTxrIDs, msg.get_hisID);
	dist(msg.get_myID,msg.get_hisID) = msg.get_distance_distance;
	distStdv(msg.get_myID,msg.get_hisID) = msg.get_distance_stdv;
end
%plot positions
ids=locID;
plot(loc(ids,1), loc(ids,2),'k.');
hold on
%plot anchors
anchors=find(locStdv(:,1)==0 & locStdv(:,2)==0);
plot(loc(ids,1), loc(ids,2),'xr', 'MarkerSize', 15,'LineWidth',2);
%plot stdv estiamtes
ids=setdiff(ids,anchors);
plot([loc(ids,1)-locStdv(ids,1) loc(ids,1)+locStdv(ids,1)], locStdv(ids,2),'b-');
plot([loc(ids,2)-locStdv(ids,2) loc(ids,2)+locStdv(ids,2)], locStdv(ids,1),'b-');
%plot distance estimates
scalex=loc(distRxrID,1)-loc(distTxrID,1)/dist(distRxrID,distTxrID);
scaley=loc(distRxrID,2)-loc(distTxrID,2)/dist(distRxrID,distTxrID);
quiver(loc(distRxrID,1),loc(distRxrID,2),dist(distRxrID,distTxrID)*scalex,dist(distRxrID,distTxrID)*scaley,0,'color',[.8 .8 .8]); %remove the zero to automatically scale the arrow to fit screen
hold off