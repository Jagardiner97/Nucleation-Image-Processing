clear;
tic;

num_test_values = 10;
min_error = inf;
best_sensitivity = 0;
mean_errors = zeros(1,num_test_values);
actual = [275, 279, 274, 304, 286, 303, 259, 259, 288, 313, 288, 263, 262, 271, 179, 293, 244, 263, 297];
all_calculated = [];

%% Get the Number of Pictures
num_pictures = 330;
np_str = string(num_pictures);
file_type = '.jpg';
directory = "Test Images/Picture Sets/1/";

%% Read crop information
xmin = 0;
ymin = 500;
width = 4000;
height = 2500;
circle_radii_range = [35, 100];
circle_sensitivity = 0.87;
circle_edge_threshold = 0.037;

%% Select the Calibration Image
cal_pic_name = strcat(directory, np_str, file_type);
cal_pic = imread(cal_pic_name);
cal_pic = imcrop(cal_pic, [xmin ymin width height]);
[centers, radii] = imfindcircles(cal_pic, circle_radii_range, 'Sensitivity', circle_sensitivity, 'EdgeThreshold', circle_edge_threshold);
cal_gray = rgb2gray(cal_pic);
num_drops = length(radii);

%% Remove Overlapping Droplets
ave_rad = mean(radii);
overlapping = [];
for i = 1:num_drops
    if not(ismember(i, overlapping))
        for j = 1:num_drops
            if (j ~= i) && (not(ismember(j, overlapping)))
                dx = centers(i,1) - centers(j,1);
                dy = centers(i,2) - centers(j,2);
                dist = sqrt(dx^2 + dy^2);
                if dist < ave_rad * 1.2
                    overlapping = [overlapping; j];
                end
            end
        end    
    end    
end
overlap_descending = sort(overlapping, 'descend');
for i = 1:length(overlap_descending)
    remove = overlap_descending(i);
    centers(remove,:) = [];
    radii(remove,:) = [];
end
%imshow(cal_gray)
%viscircles(centers, radii)
num_drops = length(radii);

centers_and_radii = [centers, radii];

%% Reorder Droplets
vsorted = sortrows(centers_and_radii, 2); %sort based on the y coordinate
row_coord = 0;
row_end_index = [];
last_row = 0;

% Sorting parameters
row_tolerance = 100;

% Sort into rows
for i = 1:num_drops
    % Find the mean y coordinate of the row
    y_val = vsorted(i, 2);
    row_coord = row_coord + y_val;
    n_in_row = i - last_row;
    row_coord_mean = row_coord / n_in_row;
    
    % Determine if the current droplet is in a new row
    if y_val > row_coord_mean + row_tolerance
        row_end_index = [row_end_index; i-1];
        last_row = i-1;
        row_coord = y_val;
    end
end
row_end_index = [row_end_index; num_drops];

% Sort rows by x coordinate
number = numel(row_end_index);
last_row = 0;
for i = 1:number
    start_index = last_row + 1;
    end_index = row_end_index(i);
    B = sortrows(vsorted(start_index:end_index, :), 1);
    vsorted(start_index:end_index, :) = B;
    last_row = end_index;
end

centers = vsorted(:, 1:2);
radii = vsorted(:, 3);

for n=1:num_test_values
    %% Define Sensitivity
    sensitivity = n * 2;
    clear droplet

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
    for j = 1:num_pictures
        % open the next picture
        pic_num = j; %change this if the pictures start at 1
        pic_name = strcat(directory, string(pic_num), file_type);
        curr_pic = imread(pic_name);
        curr_pic = imcrop(curr_pic, [xmin ymin width height]);
        gray_pic = rgb2gray(curr_pic);

        if j == 1
            for k = 1:num_drops
                droplet(k).curr_mpv = sum((double(droplet(k).pixels).*double(gray_pic))/droplet(k).num_pixels, 'all');
            end
        else 
             % iterate through each unfrozen droplet and check status
            for k = 1:num_drops
                if droplet(k).status < 0
                    new_MPV = sum((double(droplet(k).pixels).*double(gray_pic))/droplet(k).num_pixels, 'all');
                    if abs(new_MPV - droplet(k).curr_mpv) > sensitivity
                        droplet(k).status = j;
                    end
                end
            end
        end
    
        % close the open image and clear variables from memory
        close
        clear curr_pic gray_pic;
    end
    
    %% Compare Calculations vs Actual Values
    calculated = zeros(1, num_drops);
    for l=1:num_drops
        frame = droplet(l).status;
        calculated(l) = frame;
    end
    all_calculated = [all_calculated; calculated];
    difference = calculated - actual;
    error = difference .* difference;
    mean_error = mean(error);
    if mean_error < min_error
        min_error = mean_error;
        best_sensitivity = sensitivity;
    end
    mean_errors(n) = mean_error;
end

%% Results
disp(best_sensitivity)
disp(min_error)

toc;