function A = unpickle( strIn )


% parse the header
sepInd = find( ':' == strIn );
if ~isempty(sepInd) && (length(sepInd) == 2) && (sepInd(2) < length(strIn)-1)
    classStr = strIn(1:sepInd(1)-1);
    sizeStr = strIn(sepInd(1)+1:sepInd(2)-1);
    dataStr = strIn(sepInd(2)+1:end-1);
else
    error( 'This string cannot be unpickled; it lacks the proper header' );
end

% convert the str to a MATLAB object
switch classStr

 case 'char'
  sizeVal = str2num( sizeStr );
  A = dataStr;
  A = reshape( A , sizeVal );

 otherwise
  sizeVal = str2num( sizeStr );
  A = str2num( dataStr );
  A = reshape( A , sizeVal );
end