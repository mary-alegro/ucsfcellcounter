function r = parseRules(rules,group)
%
% ex. RULES = {{'00'} {'14'} {'23'}}
%
    nG = length(rules);
    for i=1:nG
        c = rules{1,i};
        cc = char(c);
        g = str2num(cc(1));
        if g == group
            r = str2num(cc(2));
            break;
        end
    end

end

