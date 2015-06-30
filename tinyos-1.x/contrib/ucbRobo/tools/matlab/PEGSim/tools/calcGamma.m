function Gamma = calcGamma(SN,resolution)
% Calculates an approximation for Gamma on a mesh grid given a sensor network
% and static routing topology.  Gamma is the probability of connection as a
% function of position in the network.
%
% Gamma(x_p,y_p,x_e,y_e) is a function of 4 variables, and its approximation is
% represented by a 4 dimensional matrix with entries [x_p,y_p,x_e,y_e] for
% positions of the pursuer and the evader on evenly spaced gridpoints.
%
% input:  resolution specifies the spacing between grid points.

disp('This calculation assumes that you are using the model from SNSim_simple');
for x_p=0:resolution:SN.dimX
    for y_p=0:resolution:SN.dimY
        for x_e=0:resolution:SN.dimX
            for y_e=0:resolution:SN.dimY
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
                p = SN.wtMat(closeNodeP,closeNodeE);
                p1 = x_p/resolution + 1;
                p2 = y_p/resolution + 1;
                e1 = x_e/resolution + 1;
                e2 = y_e/resolution + 1;
                Rp = SN.nodes(4,closeNodeP); %comm radius
                %Re = SN.nodes(3,closeNodeE); %sensing radius
                if (Rp > r_minP)
                    Gamma(p1,p2,e1,e2) = p*(Rp-r_minP)/Rp;
                else
                    Gamma(p1,p2,e1,e2) = 0;
                end
            end
        end
    end
end

