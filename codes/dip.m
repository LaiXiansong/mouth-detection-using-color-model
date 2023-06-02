clc;
clear;
close;

% load image
imgName = '../images/close_10.jpg';
img_ori = imread(imgName);

% convert to double
img = double(img_ori);

% extract rgb channels
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

% human face rgb threshould
rgbRegion = (R > 95) & ...,
            (G > 40) & ...,
            (B > 20) & ...,
            (((max(max(R, G), B)) - (min(min(R, G), B))) > 15) & ...,
            (abs(R - G) > 15) & ...,
            (R > G) & ...,
            (R > B) ;

% extract YCbCr channels
Y = 0.266 * R + 0.587 * G + 0.114 * B;
Cb = 0.568 * (B - Y) + 128;
Cr = 0.713 * (R - Y) + 128;

% human face YCbCr threshould
ycbcrRegion = (Cr <= Cb .* 1.5862 + 20) & ...,
              (Cr >= Cb .* 0.3448 + 76.2069) & ...,
              (Cr >= Cb .* (-4.5652) + 234.5652) & ...,
              (Cr <= Cb .* (-1.15) + 301.75) & ...,
              (Cr <= Cb .* (-2.2857) + 432.85) ;

% extract H channels
hsvImg = rgb2hsv(img);
H = hsvImg(:,:,1);

% human face H threshould
hsvRegion = (H * 255 < 25) | (H * 255 > 230);

% & operation
faceMask = ycbcrRegion & rgbRegion & hsvRegion;

% imshow(faceMask)


% YCbCr channels component
Cb2 = normalize(Cb .^ 2);

Cr2 = normalize(Cr .^ 2);
nCr2 = normalize((255 - Cr) .^ 2);

CbDCr = normalize(Cb ./ Cr);
CrDCb = normalize(Cr ./ Cb);

maskCr2 = Cr2 .* faceMask;
maksCrDCb = CrDCb .* faceMask;

% % eye mask
% eyeMap = (Cb2 + nCr2 + CbDCr) / 3;
% 
% imshow(eyeMap > 0.7)


% mouth mask
ita = 0.95 * sum(sum(maskCr2)) / sum(sum(maksCrDCb));

mouthMap = Cr2 .* ((Cr2 - ita .* CrDCb) .^ 2);

mouthMap = normalize(mouthMap);

SE = strel('square', 5);

faceMask = imdilate(faceMask, SE);

faceMask = imfill(faceMask, 'holes');

mouthMap = imopen(mouthMap, SE);

mouthMap = imfill(mouthMap, 'holes');

% Set the threshold to 0.08, multiply the face mask and the mouth mask to get the final mouth mask
mouthMask = (mouthMap .* faceMask > 0.08);

% Set the threshold to remove small objects in the image
areaThreshold = 150;

mouthMask = bwareaopen(mouthMask, areaThreshold);

% % show mouth map
% imshow(mouthMask)


% Calculate the aspect ratio of the mouth
pos = find(mouthMask == 1);
[rows, cols] = ind2sub(size(mouthMask), pos);
width = max(cols) - min(cols);
height = max(rows) - min(rows);
aspectRatio = width / height;

% Determine whether the mouth is open based on the aspect ratio
if aspectRatio > 1.4
    isOpen = 'close';
else
    isOpen = 'open';
end

% The mouth frame bbox used to display on the image
mouthBbox = [min(cols), min(rows), width, height];

% Display the original image, frame the position of the mouth and show whether it is open
figure();
imshow(img_ori);
hold on;
rectangle('Position', mouthBbox, 'EdgeColor', 'r', 'LineWidth', 2);
text(mouthBbox(1), mouthBbox(2)-20, isOpen, 'Color', 'r', 'FontSize', 16);

