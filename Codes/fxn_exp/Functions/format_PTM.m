function [PTMdata] = format_PTM(pre70,pre79,post70,post79)

avg_pre70 = mean(pre70);
avg_pre79 = mean(pre79);

if iscell(post70)
    ncond = length(post70);
    for i = 1:ncond
        avg_post70(i,:) = mean(post70{i});
        avg_post79(i,:) = mean(post79{i});
    end
else
    avg_post70 = mean(post70);
    avg_post79 = mean(post79);
end

PTMdata = [avg_pre70; avg_post70; avg_pre79; avg_post79];
