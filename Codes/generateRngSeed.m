fileDir_rng_seed = dir('rng_seed*');

if isempty(fileDir_rng_seed)
    state = rng;
    time_current = datestr(now,'yyyymmddTHHMM');
    save(sprintf('rng_seed_%s', time_current), 'time_current', 'state')
    fprintf('\n\nNote: rng seed (%s) created \n\n', time_current)
else
    fileName_rng_seed = fileDir_rng_seed.name;
    load(fileName_rng_seed)
    fprintf('\n\n *** Note: rng seed loaded: %s\n\n', fileName_rng_seed)
    rng(state);
end