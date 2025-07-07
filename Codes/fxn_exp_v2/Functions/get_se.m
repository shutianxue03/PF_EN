function [se] = get_se(data1,data2)

sd1 = std(data1);
sd2 = std(data2);

[n1,~] = size(data1);
[n2,~] = size(data2);

se = sqrt( (sd1.^2./n1) + (sd2.^2./n2) );


end