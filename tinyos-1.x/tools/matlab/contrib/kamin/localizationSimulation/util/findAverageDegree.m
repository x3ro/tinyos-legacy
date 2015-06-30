function [averageDegree,nodeDegree]=findAverageDegree(t)
%=findAverageDegree(t)
%
%This function takes a test case and returns the degree of all the nodes
%and the average degree over the network
%

nodeDegree = sum(t.connectivityMatrix,2);
averageDegree = mean(nodeDegree);
