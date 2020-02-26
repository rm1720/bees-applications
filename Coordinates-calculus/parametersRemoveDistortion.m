%% It provides the parameters useful to remove the distorsion.
%% Use the undistortImage function on the image you wish to treat

% Original file provided by Matlab as an example; adapted here for our
% experiment
function [parameters, scale] = parametersRemoveDistortion(calibrationImagesDirectory, squareSize)
w = waitbar(0, 'Calculus of the camera parameters...');
% Create a set of calibration images put in the CalibrationImages folder.
link=dir([calibrationImagesDirectory '/*.tif']);
numberCalibrationImages = size(link, 1);
calibrationImagesNames = cell([numberCalibrationImages,1]);
for i = 1:numberCalibrationImages
    waitbar(i/numberCalibrationImages/5)
    calibrationImagesNames(i) = cellstr(link(i).name);
end

images = imageDatastore(fullfile(calibrationImagesDirectory, calibrationImagesNames));
waitbar(0.3)
% Detect calibration pattern.
[imagePoints,boardSize] = detectCheckerboardPoints(images.Files);
waitbar(0.6)
% Generate world coordinates of the corners of the squares. Square size is
% in millimeters.
worldPoints = generateCheckerboardPoints(boardSize,squareSize);
waitbar(0.8)
% Calibrate the camera.
I = readimage(images,1);
imageSize = [size(I, 1), size(I, 2)];
parameters = estimateCameraParameters(imagePoints,worldPoints, ...
                                  'ImageSize',imageSize);
mkdir('UndistortedCalibrationImages');
for i=1:numberCalibrationImages
    I = readimage(images,i);
    I = undistortImage(I, parameters, 'output', 'valid');
    imwrite(I, fullfile('UndistortedCalibrationImages', sprintf('n%d.tif', i)));
end
waitbar(1)
I = undistortImage(I, parameters);
[imagePoints,boardSize] = detectCheckerboardPoints(I);
worldPoints = generateCheckerboardPoints(boardSize,squareSize);
delete(w);
%% VOIR POUR FAIRE UNE MOYENNE ET EVITER LES VALEURS ABERANTES
% Calculate the scale m/px
x1 = imagePoints(1,1);
x2 = imagePoints(2,1);
y1 = imagePoints(1,2);
y2 = imagePoints(2,2);

'scale'
scale = (squareSize/sqrt((x2-x1)^2 + (y2-y1)^2))/1000

%plot(imagePoints(:,1,1),imagePoints(:,2,1), 'o');