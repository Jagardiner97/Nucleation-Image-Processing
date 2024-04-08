%% Crop Info
xmin = 750;
ymin = 650;
width = 3200;
height = 2000;

%% Circle Detection Parameters
circle_radii_range = [35, 100];
circle_sensitivity = .805;
circle_edge_threshold = 0.037;

cal_im_name = "109GOPRO/G0378983.jpg";
cal_pic = imread(cal_im_name);
cal_pic = imcrop(cal_pic, [xmin ymin width height]);
[centers, radii] = imfindcircles(cal_pic, circle_radii_range, 'Sensitivity', circle_sensitivity, 'EdgeThreshold', circle_edge_threshold);
imshow(cal_pic)
viscircles(centers, radii);

test = csvread("Final Method\test.csv")