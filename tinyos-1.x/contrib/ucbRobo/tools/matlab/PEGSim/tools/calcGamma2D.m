function Gamma = calcGamma2D(SN,resolution,x_e,y_e)
% calcGamma2D(SN,resolution,x_e,y_e)
% Calculates an approximation for Gamma(x_p,y_p) on a mesh grid given a
% sensor network and static routing topology.  Gamma is the probability of
% connection as a function of position in the network.
%
% Gamma(x_p,y_p) is calculated given a fixed position (x_e,y_e), and its
% approximation is represented by a 2 dimensional matrix with entries
% [x_p,y_p] for positions of the pursuer on evenly spaced gridpoints.
%
% input:  resolution specifies the spacing between grid points.
%         x_e specifies the x position of the evader
%         y_e specifies the y position of the evader

n = 3;
disp('This calculation assumes that you are using the model from SNSim_ralpha');
for x_p=0:resolution:SN.dimX
    for y_p=0:resolution:SN.dimY
        % finding the closest node to the pursuer
        A = [x_p - SN.nodes(1,:); y_p - SN.nodes(2,:)];
        A(1,:) = A(1,:).*A(1,:);
        A(2,:) = A(2,:).*A(2,:);
        A = sqrt([1 1] * A);
        for i = 1:n
            [r_minP(i) closeNodeP(i)] = min(A);
            A = A([1:(closeNodeP(i)-1) closeNodeP(i)+1:end]); %remove min
        end

        % finding the n closest nodes to the evader
        B = [x_e - SN.nodes(1,:); y_e - SN.nodes(2,:)];
        B(1,:) = B(1,:).*B(1,:);
        B(2,:) = B(2,:).*B(2,:);
        B = sqrt([1 1] * B);
        [r_minE closeNodeE] = min(B);

        % Calculate the probabilities
        p1 = round(x_p/resolution) + 1;
        p2 = round(y_p/resolution) + 1;
        
        Gamma(p1,p2) = 0;
        bigW = sum(r_minP);
        for i = 1:n
            p = SN.connProb(closeNodeP(i),closeNodeE);
            Rp = SN.nodes(4,closeNodeP(i)); %comm radius
            if (Rp > r_minP(i))
                w(i) = bigW - r_minP(i); % weights
                b = SN.nodes(6,closeNodeP(i));
                Gamma(p1,p2) = Gamma(p1,p2) + w(i)*p*b/(b+r_minP(i)^SN.alphaR);%*(Rp-r_minP(i))/Rp;%*b/(b+r_minP(i)^SN.alphaR);
            else
                w(i) = 0;
            end
        end
        if (bigW ~= 0)
            Gamma(p1,p2) = Gamma(p1,p2)/bigW; %average over neighbors
        end
    end
end
