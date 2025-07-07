function estP = fxn_selectLoc(data, indLoc)
nLoc_s = length(indLoc);

data_s = data(indLoc);
nsubj = length(data_s{1});
estP = nan(nsubj, nLoc_s);
for iiLoc=1:nLoc_s, estP(:, iiLoc) = data_s{iiLoc}; end
end