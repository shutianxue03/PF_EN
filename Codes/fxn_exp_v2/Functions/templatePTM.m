figure('Color','white')
x = [-3:.1:3];
hold on
y = normpdf(x,0,.5);
plot(x,y./max(y),'-.','color',[.7 .2 .8],'LineWidth',3)
y = normpdf(x,0,.75);
plot(x,y./max(y),'-','color',[.5 0 .5],'LineWidth',3)
y = normpdf(x,0,1.25);
plot(x,y./max(y),'-','color',[.5 0 .5],'LineWidth',3)
y = normpdf(x,0,1.5);
plot(x,y./max(y),'-.','color',[.7 .2 .8],'LineWidth',3)
y = normpdf(x,0,1);
plot(x,y./max(y),'-','color',[.2 .2 .2],'LineWidth',8); 
set(gca,'visible','off')
axis square


figure('Color','white')
x = [-5:.1:5];
hold on
y = normpdf(x,-.75,2);
plot(x,y,'-','color',[.2 .2 .2],'LineWidth',12); 
y = normpdf(x,.75,2);
plot(x,y,'-','color',[.6 .6 .6],'LineWidth',12); 

set(gca,'visible','off')
% axis square