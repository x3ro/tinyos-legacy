function t = composition(t)

%t = anchorNodePropogation(t);
t = weightedShortestPathToAnchor(t);
%t = shortestPathToAnchor(t);
%t = globalGridSearch(t);
%t = boundingBox(t);
%t = gradientAscent(t);
t = forceResolution(t);
%t = multihopMassSpring(t);
%t = boundingBox(t);
