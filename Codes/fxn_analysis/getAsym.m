function asym = getAsym(A,a)
A(A==0)=-eps; %  when cst is 100%, set the value to -eps to avoid 0/0=nan
a(a==0)=-eps;
asym = (A-a)./(A+a);
end