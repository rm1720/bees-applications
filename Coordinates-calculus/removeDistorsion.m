%% Remove distortion on all images in the indicated directory (source)
% The indicated directory source/target must not contain a slash at their ends
%% Save the new images on the indicated directory (target)
function removeDistorsion(source, target, camParameters)
dossierEnCours = split(source,'\');
dossierEnCours = string(dossierEnCours(end))
% Count the number of captured images
link=dir([source '/*.tif']);
numberOfImages = size(link, 1);
% Remove the distortion for all the files in the source folder

%reference = uint16(zeros(camParameters.ImageSize(1),camParameters.ImageSize(2)));
w = waitbar(0, 'Removing the distorsion...', 'Name', dossierEnCours);
for i = 1:numberOfImages
    mkdir(fullfile(link(i).folder, target));
    waitbar(i/numberOfImages)
	image = imread(fullfile(link(i).folder, link(i).name));
	image = undistortImage(image, camParameters,'output','valid');
    imwrite(image, fullfile(link(i).folder, target, link(i).name), 'tif');
    %reference = reference + uint16(image);
end
delete(w);
%reference = uint8(reference / numberOfImages);
% reference = imread(fullfile(link(numberOfImages).folder, link(numberOfImages).name));
% reference = undistortImage(reference, camParameters);
% imwrite(reference, fullfile(target, 'reference.tif'), 'tif');