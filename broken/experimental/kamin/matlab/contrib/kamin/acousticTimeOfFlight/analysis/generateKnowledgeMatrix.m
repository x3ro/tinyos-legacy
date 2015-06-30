function knowledgeMatrix = generateKnowledgeMatrix(rangingData, percentKnownPositions)
%knowledgeMatrix = generateKnowledgeMatrix(rangingData, percentKnownPositions)
%
%This function randomly chooses a fixed percentage of the nodes to be at known
%positions and generates a knowledge matrix accordingly

numNodesKnown = round(size(rangingData, 1)*percentKnownPositions);
knowledgeMatrix = zeros(size(rangingData,1),size(rangingData,2),size(rangingData,3));
	nodeIDs = randperm(size(rangingData, 1));
    knownNodes = zeros(1,length(nodeIDs));
    knownNodes(logical(nodeIDs<=numNodesKnown))=1;
for time=1:size(rangingData,3)
	knowledgeMatrix(:,:,time) = knownNodes'*knownNodes;
end	
