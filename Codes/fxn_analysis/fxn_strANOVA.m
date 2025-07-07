function str_ANOVA = fxn_strANOVA(tbl)
% Initialize an empty cell array to store the strings
nRows = size(tbl, 1) - 3; % Number of terms in the ANOVA
str_ANOVA = [];
for iRow = 1:nRows
    term = tbl{iRow+1, 1};   % Term name
    df1 = tbl{iRow+1, 3};    % Degrees of freedom (numerator)
    df2 = tbl{end, 3}; % Degrees of freedom (denominator)
    F = tbl{iRow+1, 6};      % F-statistic
    p = tbl{iRow+1, 7};      % p-value
    % Append formatted ANOVA results
    str_ANOVA = [str_ANOVA, sprintf('%s: F=%.2f, p=%.3f\n', term, F, p)];
end
