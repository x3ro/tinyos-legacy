function [indices,order]=vectorFind(elements, vector)
%this function returns the indices in vector of the elements in elements
indices = zeros(length(vector),1); 
for i=elements
    indices(find(vector==i))=1;
    a=find(vector==i);
    order(find(elements==i))=a(1);
end
indices = logical(indices);
