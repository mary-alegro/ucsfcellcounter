function check_files(list)

nFiles = length(list);
for f=1:nFiles
    name = char(list(f));
    
    try
        l = ls(name);
    catch
        fprintf('%s does not exist\n.',name);
    end
end