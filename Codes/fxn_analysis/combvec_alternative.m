function C = combvec_alternative(varargin)
    [grid{1:nargin}] = ndgrid(varargin{:});
    C = cell2mat(cellfun(@(x) x(:)', grid, 'UniformOutput', false));
end