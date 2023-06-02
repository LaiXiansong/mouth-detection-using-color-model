clc;
clear;
close;

% 加载图片
imgName = '../images/close_10.jpg';
img_ori = imread(imgName);

% 转换为浮点型
img = double(img_ori);

% 提取RGB三个通道
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

% 人脸的RGB阈值范围
rgbRegion = (R > 95) & ...,
            (G > 40) & ...,
            (B > 20) & ...,
            (((max(max(R, G), B)) - (min(min(R, G), B))) > 15) & ...,
            (abs(R - G) > 15) & ...,
            (R > G) & ...,
            (R > B) ;

% 提取YCbCr三个通道
Y = 0.266 * R + 0.587 * G + 0.114 * B;
Cb = 0.568 * (B - Y) + 128;
Cr = 0.713 * (R - Y) + 128;

% 人脸的YCbCr阈值范围
ycbcrRegion = (Cr <= Cb .* 1.5862 + 20) & ...,
              (Cr >= Cb .* 0.3448 + 76.2069) & ...,
              (Cr >= Cb .* (-4.5652) + 234.5652) & ...,
              (Cr <= Cb .* (-1.15) + 301.75) & ...,
              (Cr <= Cb .* (-2.2857) + 432.85) ;

% 提取H通道
hsvImg = rgb2hsv(img);
H = hsvImg(:,:,1);

% 人脸的H阈值范围
hsvRegion = (H * 255 < 25) | (H * 255 > 230);

% 三个范围取交集得到人脸的mask
faceMask = ycbcrRegion & rgbRegion & hsvRegion;

% imshow(faceMask)


% YCbCr通道各个分量运算
Cb2 = normalize(Cb .^ 2);

Cr2 = normalize(Cr .^ 2);
nCr2 = normalize((255 - Cr) .^ 2);

CbDCr = normalize(Cb ./ Cr);
CrDCb = normalize(Cr ./ Cb);

% 在人脸内的通道分量运算
maskCr2 = Cr2 .* faceMask;
maksCrDCb = CrDCb .* faceMask;

% 计算眼睛的mask
% eyeMap = (Cb2 + nCr2 + CbDCr) / 3;
% 
% imshow(eyeMap > 0.7)


% 计算嘴巴的mask
ita = 0.95 * sum(sum(maskCr2)) / sum(sum(maksCrDCb));

mouthMap = Cr2 .* ((Cr2 - ita .* CrDCb) .^ 2);

mouthMap = normalize(mouthMap);

% 结构元
SE = strel('square', 5);

% 人脸mask膨胀
faceMask = imdilate(faceMask, SE);

% 人脸mask孔洞填充
faceMask = imfill(faceMask, 'holes');

% 嘴巴mask开操作
mouthMap = imopen(mouthMap, SE);

% 嘴巴mask孔洞填充
mouthMap = imfill(mouthMap, 'holes');

% 设定阈值0.08，人脸mask和嘴巴mask相乘得到最后的嘴巴mask
mouthMask = (mouthMap .* faceMask > 0.08);

% 设定阈值去除图片中的小物体
areaThreshold = 150;

mouthMask = bwareaopen(mouthMask, areaThreshold);

% % 显示嘴巴mask
% imshow(mouthMask)


% 计算嘴巴的长宽比
pos = find(mouthMask == 1);
[rows, cols] = ind2sub(size(mouthMask), pos);
width = max(cols) - min(cols);
height = max(rows) - min(rows);
aspectRatio = width / height;

% 根据长宽比判断嘴巴是否张开
if aspectRatio > 1.4
    isOpen = 'close';
else
    isOpen = 'open';
end

% 用于显示在图像上的嘴巴框bobox
mouthBbox = [min(cols), min(rows), width, height];

% 显示原图像，框出嘴巴位置并显示是否张开
figure();
imshow(img_ori);
hold on;
rectangle('Position', mouthBbox, 'EdgeColor', 'r', 'LineWidth', 2);
text(mouthBbox(1), mouthBbox(2)-20, isOpen, 'Color', 'r', 'FontSize', 16);

