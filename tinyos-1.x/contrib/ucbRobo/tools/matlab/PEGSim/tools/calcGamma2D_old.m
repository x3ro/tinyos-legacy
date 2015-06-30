function Gamma = calcGamma2D_old(SN,resolution,x_e,y_e)
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

disp('This calculation assumes that you are using the model from SNSim_ralpha');
for x_p=0:resolution:SN.dimX
    for y_p=0:resolution:SN.dimY
        % finding the closest node to the pursuer
        A = [x_p - SN.nodes(1,:); y_p - SN.nodes(2,:)];
        A(1,:) = A(1,:).*A(1,:);
        A(2,:) = A(2,:).*A(2,:);
        A = sqrt([1 1] * A);
        [r_minP closeNodeP] = min(A);
        % finding the closest node to the evader
        B = [x_e - SN.nodes(1,:); y_e - SN.nodes(2,:)];
        B(1,:) = B(1,:).*B(1,:);
        B(2,:) = B(2,:).*B(2,:);
        B = sqrt([1 1] * B);
        [r_minE closeNodeE] = min(B);
        % Calculate the probabilities
        p = SN.connProb(closeNodeP,closeNodeE);
        p1 = x_p/resolution + 1;
        p2 = y_p/resolution + 1;
        Rp = SN.nodes(4,closeNodeP); %comm radius
        if (Rp > r_minP)
            %b = SN.nodes(6,closeNodeP);
            Gamma(p1,p2) = p;%*b/(b+r_minP^SN.alphaR);
        else
            Gamma(p1,p2) = 0;
        end
    end
end
