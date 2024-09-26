Code to determine the freezing frame from consecutive pictures of water droplets in a nucleation experiment.

Files:
processing.m: the main script file that analyzes images and creates a report file with freezing frame information
calibration.m: a matlab script that can be used to determine crop information for a selected image

Inputs:
directory: path to the sequence of images from processing.m
crop information: x, y, width, and height information for the image crop

Outputs:
Results are saved to a results folder inside the folder containing the experiment images
report.csv: a csv file with the droplet number in the first column and the freezing image in the right column
droplets.png: an image from the experiment images with droplet boundaries and droplet number superimposed

This code was tested on a series of 5 experiment datasets and had very good performance. Future testing with other datasets may find further tuning to the sensitivity values are needed.
