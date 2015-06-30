% genSNScript - A script to generate Sensor Network Data Structures

% for i = 1:20
%     SN = SNSimInit_ralpha(50,25,25,6,0.20,2,20,0.8,2,20,0.5);
%     fName = sprintf('examples/nodes50_25x25_%d',i);
%     save(fName,'SN');
% end

for i = 1:20
    SN = SNSimInit_ralpha(100,50,50,10,0.20,2,100,0.8,2,50,0.5);
    fName = sprintf('examples/nodes100_50x50_%d',i);
    save(fName,'SN');
end

%
% for i = 1:10
%     SN = SNSimInit_ralpha(400,100,100,20,0.20,2,20,0.8,2,100,0.5);
% %    SN = genSN_simple(400,100,100,10,0.20,15,10);
%     fName = sprintf('examples/nodes400_100x100_%d',i);
%     save(fName,'SN');
% end
% 
% for i = 11:20
%     SN = SNSimInit_ralpha(400,100,100,31-i,0.20,2,20,0.8,2,100,0.5);
%     fName = sprintf('examples/nodes400_100x100_%d',i);
%     save(fName,'SN');
% end



% SN = SNSimInit_ralpha(400,100,100,30,0.20,2,20,0.8,2,100,0.5);
% fName = sprintf('examples/nodes400_100x100_%d',i);
% save(fName,'SN');
