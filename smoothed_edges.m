function [smoothedX, smoothedY] = smoothed_edges(inputPatch, polynomialOrder, windowWidth, boundaryNum)

%Uses Savitzky-Golay Filter in image tools to find smoothed edges of patch
%image

 if ~exist('polynomialOrder','var')
     % default polynomial order if not specified
      polynomialOrder = 2;
 end
 
  if ~exist('windowWidth','var')
     % default window width if not specified
      windowWidth = 7; %must be odd
  end
 
    if ~exist('boundaryNum','var')
     % default window width if not specified
      boundaryNum = 1; %must be odd
 end
 
 

filled_image=imfill(inputPatch, 'holes');
boundaries=bwboundaries(filled_image);
b=boundaries{boundaryNum};
x=b(:,2);
y=b(:,1);

smoothedX = sgolayfilt(x, polynomialOrder, windowWidth);
smoothedY = sgolayfilt(y, polynomialOrder, windowWidth);