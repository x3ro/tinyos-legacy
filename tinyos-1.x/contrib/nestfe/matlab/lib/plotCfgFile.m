function plotCfgFile(fileName)
% Reads in a *.cfg file and plots it.

mySize = 4;

motes = read_swcfgfile(fileName);

scrsz = get(0,'ScreenSize');
figure('Position',[1 (scrsz(4)/2 - 50) (scrsz(3)/2 - 25) scrsz(4)/2],'DoubleBuffer','on');
hold on;

for i=1:motes.N
    xPos = motes.pos(i,1)-mySize/2;
    yPos = motes.pos(i,2)-mySize/2;
    rectangle('Curvature',[1 1],'Position',[xPos,yPos,mySize,mySize],...
              'FaceColor',[1 0 0]);
    text(xPos+mySize/2,yPos+mySize/2,int2str(motes.id(i)));
end

newXlim = [min(motes.pos(:,1))-mySize/2  max(motes.pos(:,1))+mySize/2];
newYlim = [min(motes.pos(:,2))-mySize/2  max(motes.pos(:,2))+mySize/2];
myAx = gca;
set(myAx,'Xlim',newXlim);
set(myAx,'Ylim',newYlim);

hold off;
