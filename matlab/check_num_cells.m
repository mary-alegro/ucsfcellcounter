function check_num_cells

%
% compute the number of total cells from the GT 
%

dir_root='/Volumes/SUSHI_HD/SUSHI/CellCounter/toprocess/csv/';

files = dir(strcat(dir_root,'*.txt'));
nFiles = length(files);
count = 0;
for f=1:nFiles
    name = files(f).name;
    fid = fopen(strcat(dir_root,name));
    tline = fgets(fid);
    while ischar(tline)
        count = count + 1;
        tline = fgets(fid);
    end
end
fprintf('Total number of cell in GT: %d\n',count);
