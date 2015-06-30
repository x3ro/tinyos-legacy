function tof_distance=calibrateLsqrTOF_DISTANCE(varargin)
%this function uses the data in TOF_DISTANCE and
%tries to come up with a calibration factor for each sounder/microphone

global trueDist
global estDist

for i=1:32
    for j=1:32
        if estDist(i,j)<trueDist(i,j)-10
            estDist(i,j)=0;
        end
    end
end

[r c] = size(trueDist);

row=0;
%for each receiver
for i=1:r

    %for each transmitter
    for j = 1:c


        %this is the row in the matrices that we are currently populating
        if estDist(i,j)~=0
        row=row+1;

        %create the B array
%         if estDist(i,j)==0
%             B(row)=0;
%         else
%             B(row) = trueDist(i,j);
%         end
        B(row) = trueDist(i,j);

        %create the A array
        Atrans(row,i) = estDist(i,j);
        
        Arec(row,j) = estDist(i,j);
        
        Arectrans(row,i) = estDist(i,j);
        Arectrans(row,r+j) = estDist(i,j);

        ArectransOffset(row,i) = estDist(i,j);
        ArectransOffset(row,r+j) = estDist(i,j);
        ArectransOffset(row,r*2+i) = 1;
        ArectransOffset(row,r*3+j) = 1;
%        ArectransOffset(row,r*4+i) = estDist(i,j)^2;
%        ArectransOffset(row,r*5+j) = estDist(i,j)^2;
        end
    end 
 
end   

%find the calibration factors
xtrans=lsqr(Atrans,B',1e-9,200);
xrec=lsqr(Arec,B',1e-9,200);
xrectrans=lsqr(Arectrans,B',1e-9,200);
xrectransOffset=lsqr(ArectransOffset,B',1e-9,200);


%plot the true estimates
hold off
%L=min(size(A));
%plot(B, A*(ones(L,1)*.5),'.r')
plot(trueDist, estDist,'.r')
hold on
plot([1:250], [1:250],'-')
ax = [0 500 0 500];

pause
ax=axis;

%plot the calibrated estimates
hold off
plot(B, Atrans*xtrans,'.b')
hold on
plot([1:250], [1:250],'-')
plot([1:250], [1:250]+15,'-g')
plot([1:250], [1:250]-15,'-g')
plot([1:250], [1:250]+30,'-y')
plot([1:250], [1:250]-30,'-y')
axis(ax);
title('Transmitter Calibration')

pause

hold off
plot(B, Arec*xrec,'.b')
hold on
plot([1:250], [1:250],'-')
plot([1:250], [1:250]+15,'-g')
plot([1:250], [1:250]-15,'-g')
plot([1:250], [1:250]+30,'-y')
plot([1:250], [1:250]-30,'-y')
axis(ax);
title('Receiver Calibration')

pause

hold off
plot(B, Arectrans*xrectrans,'.k')
hold on
plot([1:250], [1:250],'-')
%plot([1:250], [1:250]+15,'-g')
%plot([1:250], [1:250]-15,'-g')
%plot([1:250], [1:250]+30,'-y')
%plot([1:250], [1:250]-30,'-y')
axis(ax);
title('Iterative Calibration')
ylabel('Estimated Distance (cm)')
xlabel('True Distance (cm)')
pause

hold off
plot(B, ArectransOffset*xrectransOffset,'.b')
hold on
plot([1:250], [1:250],'-')
plot([1:250], [1:250]+15,'-g')
plot([1:250], [1:250]-15,'-g')
plot([1:250], [1:250]+30,'-y')
plot([1:250], [1:250]-30,'-y')
axis(ax);
title('Receiver/Transmitter Calibration with Offset')