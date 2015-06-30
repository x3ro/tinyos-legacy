function peggroup( group )
global G_PEG;
if nargin == 1;
    G_PEG.group = group;
    if isfield(G_PEG,'receiver') && isjava(G_PEG.receiver)
        G_PEG.receiver.setGroup( G_PEG.group );
    end
end
fprintf('group = %d\n',G_PEG.group);
peginit;
