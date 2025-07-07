

nn_dir = dir('S10*');
nfiles = length(nn_dir);
for ifile = 1:nfiles
    name_old = nn_dir(ifile).name;
    name_new = sprintf('YK%s', name_old(4:end));
    movefile(name_old, name_new)
end