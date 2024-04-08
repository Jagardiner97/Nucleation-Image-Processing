clear;
tic;

%% Define Sensitivity
sensitivity = 2;

%% Get the Number of Pictures
num_pictures = 1;
file_type = '.jpg';

%% Read crop information
cinfo = csvread("test.csv");
xmin = 750;
ymin = 650;
width = 3200;
height = 2000;
circle_radii_range = [35, 100];
circle_sensitivity = 0.805;
circle_edge_threshold = 0.037;


%% Select the Calibration Image
cal_pic_name = "G0389097.jpg";%strcat(num_pictures, file_type);
cal_pic = imread(cal_pic_name);
cal_pic = imcrop(cal_pic, [xmin ymin width height]);
[centers, radii] = imfindcircles(cal_pic, circle_radii_range, 'Sensitivity', circle_sensitivity, 'EdgeThreshold', circle_edge_threshold);
cal_gray = rgb2gray(cal_pic);
num_drops = length(radii);
imshow(cal_gray)
viscircles(centers, radii);

%% Create Droplet Structure
droplet = struct('number',cell(1,num_drops), 'coordinates',[0,0], 'radius',0, 'status',-1, 'curr_mpv',0, 'pixels',1, 'numPixels',1);
[num_rows, num_columns] = size(cal_gray, [1,2]);
[x, y] = meshgrid(1:num_columns, 1:num_rows);

%% Update the Droplet Objects for each Droplet
for i = 1:num_drops
    % Update number, coordinates, radius, status, currentMPV, targetMPV
    droplet(i).number = i;
    droplet(i).coordinates = centers(i);
    radius = radii(i);
    droplet(i).radius = radius;

    % Find pixels inside the droplet
    center_x = round(centers(i,1));
    center_y = round(centers(i,2));
    droplet_pixels = (y-center_y).^2 + (x-center_x).^2 <= radius.^2;
    num_pixels = sum(double(droplet_pixels), 'all');

    droplet(i).pixels = droplet_pixels;
    droplet(i).num_pixels = num_pixels;
end

%% Iterate Through the Pictures
for j = 0:num_pictures
    % open the next picture
    pic_num = j; %change this if the pictures start at 1
    pic_name = strcat(pic_num, file_type);
    curr_pic = imread(pic_name);
    curr_pic = imcrop(curr_pic, [xmin ymin width height]);
    gray_pic = rgb2gray(curr_pic);

    % iterate through each unfrozen droplet and check status
    for k = 1:num_drops
        if droplet(k).status < 0
            new_MPV = sum((double(droplet(k).pixels).*double(gray_pic))/droplet(k).num_pixels, 'all');
            if abs(new_MPV - droplet(k).curr_mpv) > sensitivity
                droplet(k).status = j;
            end
        end
    end

    % close the open image and clear variables from memory
    close
    clear curr_pic gray_pic;
end

%% Add Droplet Labels and Display Image
report = zeros(num_drops, 2);
for i = 1:num_drops
    position = centers(i,[1,2]);
    label = i;
    cal_gray = insertText(cal_gray, position, label, 'AnchorPoint','Center','FontSize',25);
    report(i,1) = i;
    report(i,2) = droplet(i).status;
end

imshow(cal_gray);
viscircles(centers, radii);

%% Create the Report
mkdir results
writematrix(report, 'results/report.csv');
saveas(gcf, 'results/droplets.png');

toc;