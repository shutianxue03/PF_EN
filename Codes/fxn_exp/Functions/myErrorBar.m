function myErrorBar(xVal, mVal, errVal,colLine, horLines,horWidth)

if nargin<6
    horWidth = .05;
end
for ii=1:length(xVal)
    plot([xVal(ii) xVal(ii)],[mVal(ii)-errVal(ii) mVal(ii)+errVal(ii)],'-','color',colLine,'Linewidth',1);
end
% if horLines
%     plot([xVal-horWidth xVal+horWidth],[mVal-errVal mVal-errVal],'-','color',colLine,'Linewidth',2);
%     plot([xVal-horWidth xVal+horWidth],[mVal+errVal mVal+errVal],'-','color',colLine,'Linewidth',2);
% end