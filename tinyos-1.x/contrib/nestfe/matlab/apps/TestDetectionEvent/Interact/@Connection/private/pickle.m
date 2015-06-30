function strOut = pickle( A , precision )

if isa( A , 'char' )
    classTag = class(A);
    sizeTag = num2str(size(A));
    serialData = A(:)';
    strOut = [ classTag ':' sizeTag ':' serialData ];
else
    classTag = class(A);
    sizeTag = num2str(size(A));
    serialData = num2str( A(:)' , precision );
    strOut = [ classTag ':' sizeTag ':' serialData ];
end

