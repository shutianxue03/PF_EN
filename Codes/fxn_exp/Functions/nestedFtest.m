function Fval = nestedFtest(sse1,sse2,k1,k2,n)

Fval = ((sse1 - sse2)./(k2-k1))...
    ./ (sse2./(n-(sse2+sse1+1)));
