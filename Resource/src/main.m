%High Dynamic Range Imaging Program
%convert a LDR set to HDR
%
%input:
%   directory: the path of the image set
%

function main(directory)

    %set default parameters
    if(~exist('directory'))
        directory = '../input_image/';
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
    sampleNumPixels = 200;
    randomNum = randi([1, imgHeight * imgWidth], 1, sampleNumPixels);
    
    % Save samplex pixels into sImage in different color channel
    sImage = {}
    for number = 1 : imgNumber
        for pixel = 1 : sampleNumPixels
           for colorChannel = 1 :  imgColorChannel
               sImage{colorChannel}(pixel, number) = resImage{number}(randomNum(pixel), colorChannel);
               %disp(resImage{number}(randomNum(pixel), color));
           end
        end
    end

    % Calculate the camera response curve by gsolve.m
    disp('Calculate camera response function');
    g = zeros(256,3);
    lnE = zeros(sampleNumPixels, imgColorChannel);
    % Weight function
    weight = zeros(1, 256);
    weight(1 : 128) = (1 : 128);
    weight(129 : 256) = (128 : -1 : 1);
    lamdba = 10;
    for colorChannel = 1 : imgColorChannel
        [g(:,colorChannel), lnE(:, colorChannel)] = gsolve(sImage{colorChannel}, lnDelta_t, lamdba, weight);
    end

    % Build HDR radiance map, according to the formula
    disp('Build HDR radiance map');
    pixcels = imgHeight * imgWidth;
    %disp(pixcels);
    lnEi = zeros(pixcels, imgColorChannel);
    for colorChannel = 1 : imgColorChannel
        for pixcel = 1 : pixcels
            sumWeight = 0;
            for number = 1 : imgNumber
                Zij = resImage{number}(pixcel, colorChannel);
                tempLnEi = weight(Zij + 1) * (g(Zij + 1, colorChannel) - lnDelta_t(number));
                lnEi(pixcel, colorChannel) = lnEi(pixcel, colorChannel) + tempLnEi;
                sumWeight = sumWeight + weight(Zij + 1);
            end
            lnEi(pixcel, colorChannel) = lnEi(pixcel, colorChannel) / sumWeight;
        end
    end

    % Remove invaild values(INF and NAN) from lnEi and set its as 0
    imageHDR = exp(lnEi);
    index = find(isnan(imageHDR) | isinf(imageHDR));
    imageHDR(index) = 0;
    
    % Write HDR image into file
    imageHDR = reshape(imageHDR, imgHeight, imgWidth, imgColorChannel);
    %write_rgbe(imageHDR, 'Image.hdr');

    % Tone Mapping
    imgToneMapping = tongMapping(imageHDR, 'global');
    %write_rgbe(imgTMO, ['_tone_mapped.hdr']);
    imwrite(imgToneMapping, ['toneMapping.png']);
    
end

