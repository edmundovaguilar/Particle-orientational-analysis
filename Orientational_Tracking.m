%% J. Rubén Gómez Solano
%% Edmundo V. Aguilar
%% Tracking of objects with a dark ring surrounding a bright center
%% Brightness distribution over particle area provides cap orientation
%% Touching particles are tracked individually

% ringlike structure element to find particles
% brightness level to generate regionmask
% invert image to detect only central spots for identifying touching particles
% erode and dilate mask to remove noise
% filter remaining objects by size
% average gradient calculation
% generate textfile readable by MATLAB


%%

clear                % clear memory
clc
clf

tic

% settings
maskLevel =      25;
% the mask is that much brighter than the background, 
% low = better sensitivity, but more noise.                           
% Because of the size sensitive filtering, this value can be small
particleRadius = 14;       
% inner radius, important for structure element size filtering
thickness =       1;        
% thickness of rings, "1" is usually a good choice 
radiusFilter =    1;        
% gaussian filter of image for gradient, helps with noisy images
erodeRadius =     1;        
% size of the structure element for erosion, diameter = 2*erodeRadius + 1
dilateRadius =    3;        
% size of the structure element for dilation, 
% diameter = 2*dilateRadius + 1
dilateMask =      1;        
% size of the structure element for mask, diameter = 2*dilateMask + 1

viewScale =       1.0;     
% scale video output to this ratio, useful for big videos on small screens

framePortion =    400;     
% number of frames read at once, 
% higher = better performance, more memory usage


[inputFilename,inputFilepath,Filter] = uigetfile('D:\Videos_Lab\20231109_Janus_200nm_Celda_confinada\*.mp4','Multiselect','on');
FilenameArray = char(inputFilename);
NumberOfFiles = size(FilenameArray);
StructureErode = strel('disk',erodeRadius);
StructureDilate = strel('disk',dilateRadius);
StructureMask = strel('disk',dilateMask);

% create structure element for ring detection
radiusOuter = particleRadius + thickness;
[x,y] = meshgrid(-radiusOuter:radiusOuter); 
disk1 = sqrt( x.^2 + y.^2) <= particleRadius;    % .^ = array power
disk2 = sqrt( x.^2 + y.^2) <= radiusOuter; 
ArrayRing = disk2 - disk1; 
StructureRing = strel(ArrayRing);
MaskRing = 1 - ArrayRing;


for FileLoop = 1 : NumberOfFiles(1)      % begin of file loop

inputFile = deblank([inputFilepath FilenameArray(FileLoop,:)]);
[inputPath, Filename, Extension ]= fileparts(inputFile);
sep = filesep;

%% ---- Setting video conditions ------------------------------------------------------------------------

firstFrame = ((0*60)+2)*50; % (1*60*50)
lastFrame = ((1*60)+58)*50; % numberOfFrames;
videoFrames = lastFrame - firstFrame + 1;
sep1 = '_';
Filename_mod = string(inputPath)+sep+"coords"+sep+Filename(1:17)+string(firstFrame)+"-"+string(lastFrame)+'_coord.txt'; 

fid = fopen(Filename_mod,'w');

%% ------------------------------------------------------------------------------------------------------

videoReadObj = VideoReader(inputFile);
numberOfFrames = videoReadObj.NumberOfFrames;
frameRate = videoReadObj.FrameRate;
Xres = videoReadObj.Width;
Yres = videoReadObj.Height;

Filename_mod2 = string(inputPath)+sep+"orientation_videos"+sep+Filename(1:17)+string(firstFrame)+"-"+string(lastFrame)+'_track';
videoWriteObj = VideoWriter(Filename_mod2,'MPEG-4');
videoWriteObj.FrameRate = frameRate;
videoWriteObj.Quality = 95;
open(videoWriteObj);

%%
%set figure properties
set (figure(1),'Toolbar','none','MenuBar','none','Position', [(1000-Xres*viewScale) 100 Xres*viewScale Yres*viewScale ])
colormap(gray)
axis off
axis normal
set (axes, 'position', [0 0 1 1 ])

% calculate background image in 24 bit


% load portion of video file, i = number of portion
for i = 1 : floor(videoFrames/framePortion)

clear('video');
videoReadObj = VideoReader(inputFile);
video = read(videoReadObj, [(firstFrame+(framePortion*(i-1))) (firstFrame+(framePortion*i)-1)]);

% analyze frame by frame within each portion
for frameNumber = 1 : framePortion;
currentFrame = firstFrame + (framePortion*(i-1) + frameNumber -1)    
imageOrg = video(:,:,:,frameNumber);                                   
% original frame
imageRaw = imageOrg(:,:,1);                                            
% reduce to 8 bit
imageParticles = 255 - imageRaw;                                       
% invert image
imageOpen = imopen(imageParticles, StructureRing);                     
% searching for ringlike structures
histogram = imhist(imageOpen);                                         
% histogram of processed image
[level,threshold] = max(histogram);                                    
% threshold = brightness of background
imageMask = imageOpen >= threshold + maskLevel;                        
% create mask at desired cut off level
imageDilate = imdilate(imageMask,StructureDilate);                     
% dilate to fuse parts of broken particles
imageErode = imerode(imageDilate,StructureErode);                      
% erode to get rid of noise and separate barely touching particles
imageInvert = ~imageDilate;                                            
% invert again for tracking the inner parts of the rings

imagesc(imageOrg)
imagesc(imageRaw)
hold on
imagesc(64*ArrayRing)
hold off
imagesc(uint8(imageParticles))   
imagesc(imageOpen)
imagesc(imageMask)
imagesc(imageDilate)
imagesc(imageErode)
imagesc(imageInvert)

X = [];
Y = [];
[regions,NumberOfRegions] = bwlabel(imageInvert,8);                     
% label particle regions, get number of detected regions
props = regionprops(regions,imageRaw,'WeightedCentroid','Centroid','Area','PixelList');             
% get coordinates and sizes for all particles

% analyze particles in frame
CurrentParticles = 0;
imageVideo = imresize(imageOrg,viewScale);

for n = 1 : NumberOfRegions
X = [X;props(n).Centroid(1)];
Y = [Y;props(n).Centroid(2)];
coordX = props(n).Centroid(1);
coordY = props(n).Centroid(2);
weighX = props(n).WeightedCentroid(1);
weighY = props(n).WeightedCentroid(2);
SizeOfRegion = props(n).Area;

if SizeOfRegion > 300 && SizeOfRegion < 800     
% size filter, if other particles are present
particleMask = eq(regions,n);
particleMask = bwmorph(particleMask,'shrink','inf');
image(particleMask*128);
particleMask = imdilate(particleMask,StructureMask);
image(particleMask*128);
particleArea = uint8(particleMask) .* imageParticles;   
% mask area of one particle
imagesc(particleArea);

oriMean = abs(complex((coordX - weighX),(coordY - weighY)));
if oriMean == 0
oriMean = 0.0001;
end
oriX = particleRadius * (coordX - weighX) / oriMean;
oriY = particleRadius * (coordY - weighY) / oriMean;

imageVideo = insertMarker(imageVideo,[coordX coordY] * viewScale,'x','Size',3,'Color','blue');
imageVideo = insertMarker(imageVideo,[(coordX + 2*oriX) (coordY + 2*oriY)] * viewScale,'x','Size',3,'Color','red');
imageVideo = insertShape(imageVideo,'Line',[coordX - 2*oriX , coordY - 2*oriY, coordX + 2*oriX, coordY + 2*oriY] * viewScale,'LineWidth',1,'Color','red');


CurrentParticles = CurrentParticles+1;
timeStamp = currentFrame / frameRate;
oriX = (coordX - weighX) / oriMean;
oriY = (coordY - weighY) / oriMean;
fprintf(fid,'%4.3f %4.3f %2.3f %2.3f %5u \r\n',coordX,coordY,oriX,oriY,currentFrame);   
% create result file in matlab notation

end   % end of size selection

end     % end of regions loop
%   CurrentParticles
imagesc(imageVideo);
pause(0.00);
writeVideo(videoWriteObj,imageVideo);  

end      

end       

close(videoWriteObj);
fclose(fid);
disp('end')

end       % end of file loop
toc

%%
load handel
sound(y,Fs)