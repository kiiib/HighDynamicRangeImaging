%High Dynamic Range Imaging Program
%convert a LDR set to HDR
%
%input:
%   directory: the path of the image set
%   lamdba: the constant that determines the amount of smoothness
%

function main(directory, lamdba)

    %set default parameters
    if(~exist('directory'))
        directory = '../input_image/';
    end
    if(~exist('lamdba'))
        lamdba = 10;
    end
    
    %
    % Load images
    %
    disp('Load images from directory');
    images = [];
    exposureTimes = [];
    
    extension = 'jpg';
    files = dir([directory, '*.', extension]);
    imgNumber = length(files);
    imgInfo = imfinfo([directory, files(1).name]);
    imgHeight = imgInfo.Height;
    imgWidth = imgInfo.Width;
    imgColorChannel = imgInfo.NumberOfSamples;
    % NumberOfSamples: number of image's color channel
    images = zeros(imgHeight, imgWidth, imgColorChannel, imgNumber);
    exposureTimes = zeros(imgNumber);
    
    for i = 1 : imgNumber
        fileName = [directory, files(i).name];
        image = imread(fileName);

        images(:, :, :, i) = image;

        exifValue = imfinfo(fileName);
        exposureTimes(i) = exifValue.DigitalCamera.ExposureTime;
        %disp(exposureTimes(i));
    end
    lnDelta_t = log(exposureTimes);
    
    %
    % Pick up random sample pixels into sImage
    %
    disp('Select sample pixels');
    resImage = {};
    for i = 1 : imgNumber
        resImage{i} = reshape(images(:, :, :, i), imgHeight * imgWidth, imgColorChannel);
    end
    sampleNumPixels = 50;
    randomNum = randi([1, imgHeight * imgWidth], 1, sampleNumPixels);
    
    % Save samplex pixels into sImage in different color channel
    sImage = {}
    for number = 1 : imgNumber
        for pixel = 1 : sampleNumPixels
           for rbgColor = 1 :  imgColorChannel
               sImage{rbgColor}(pixel, number) = resImage{number}(randomNum(pixel), rbgColor);
               %disp(resImage{number}(randomNum(pixel), color));
           end
        end
    end

    %weight function
    weight = zeros(1, 256);
    weight(1 : 128) = (1 : 128);
    weight(129 : 256) = (128 : -1 : 1);
    %disp(weight);
    
    % Calculate the camera response curve by gsolve.m
    disp('Calculate camera response function');
    g = zeros(256,3);
    lnE = zeros(sampleNumPixels, imgColorChannel);
    for colorChannel = 1 : imgColorChannel
        [g(:,colorChannel), lnE(:, colorChannel)] = gsolve(sImage{colorChannel}, lnDelta_t, lamdba, weight);
        %disp(g);
        %disp(lnE);
    end
    
    disp('Build HDR radiance map');
    for colorChannel = 1 : imgColorChannel
        for height = 1 : imgHeight
            for width = 1: imgWidth
                
            end
        end
    end
    
%     HDR_img = reshape(HDR_Map(resImage, g, lnDelta_t, weight, imgNumber), imgHeight, imgWidth, 3);
%     figure, imshow(HDR_img), title('HDR image');
%     disp('Write HDR image to file');
%     writeHDR(HDR_img, 'img');
%     
%     tone_img = ToneMapping('global', HDR_img);
%     writeHDR(tone_img, 'TM_global_img');
%     imwrite(tone_img, 'TM_global.png');
% 
%     tone_img = ToneMapping('local', HDR_img);
%     writeHDR(tone_img, 'TM_local_img');
%     imwrite(tone_img, 'TM_local.png');

end

