gabNorth2 = CreateGabor(4*32,.5*32,90,2/32,0,0);
gabNorth = CreateGabor(4*32,.5*32,90,2/32,0,.5);

gabEast  = CreateGabor(4*32,.5*32,90,2/32,0.25,1);

imagesc(CreateGaborAnnulus(gabEast,12*32,0,0)); colormap gray; axis square; set(gca,'box','off','XTick',0,'YTick',0); 
% caxis; hold on
imagesc(CreateGaborAnnulus(gabNorth2,12*32,0,0)); colormap gray; axis square; set(gca,'box','off','XTick',0,'YTick',0,'CLim',[-.5 .5]); 
imagesc(CreateGaborAnnulus(gabNorth,12*32,0,0)); colormap gray; axis square; set(gca,'box','off','XTick',0,'YTick',0,'CLim',[-.5 .5]); 

caxis