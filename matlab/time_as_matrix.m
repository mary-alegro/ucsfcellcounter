function times = time_as_matrix(csv_file)

%
% CSV_FILE: file name of the CSV containing counting times
% TIMES: counting time in seconds
%

fid = fopen(csv_file);
times = [];

line = fgetl(fid);
while ischar(line)
    idx = strfind(line,':');
    if isempty(idx)
        line = fgetl(fid);
        continue;
    end
    mm = str2num(line(1:idx-1));
    ss = str2num(line(idx+1:end));
    T = minutes(mm)+seconds(ss);
    Ts = seconds(T);
    times = cat(1,times,Ts);
    
    line = fgetl(fid);
end

fclose(fid);