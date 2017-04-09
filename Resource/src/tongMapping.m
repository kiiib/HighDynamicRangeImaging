%Tone Mapping Program
%input:
%   imageHDR: the HDR image
%   type: global or local
%
function tonemappedImage = toMapping(imageHDR, type)
    tonemappedImage = zeros(size(imageHDR));
    alpha = 0.36;
    white = 2;
    phi = 8;
    epsilon = 0.05;
    delta = 1e-6;
    
    % Luminace channel
    %L = 0.2126 * imageHDR(:, :, 1) + 0.7152 * imageHDR(:, :, 2) + 0.0722 * imageHDR(:, :, 2);
    L = 0.2 * imageHDR(:, :, 1) + 0.7 * imageHDR(:, :, 2) + 0.1 * imageHDR(:, :, 2);
    
    Lw = exp(mean(mean(log(delta + L))));
    
    % using alpha and logMean scale luminance
    Lm = (alpha * L) / Lw;
    
    switch type
        case 'global'
            % global
            Ld = (Lm .* (1 + Lm / (white * white))) ./ (1 + Lm);

        case 'local'
            % local
            sMax = 8;
            [imgHeight, imgWidth] = size(Lm);
            Vi = zeros(imgHeight, imgWidth, sMax);
            % compute 9 filtered images
            s = 1;
            for i = 1 : sMax
                s = s * 1.6;
                g = fspecial('gaussian', floor(6 * s + 1), s);
                Vi(:, :, i) = imfilter(Lm, g);
            end

            % modify image
            adaptL = Vi(:, :, sMax);
            mask = zeros(imgHeight, imgWidth);
            for i = 1 : (sMax - 1)
               V1 = Vi(:, :, i);
               V2 = Vi(:, :, i + 1);

               V = (V1 - V2) ./ ((((2^phi) * alpha) / (s ^ 2)) + V1);
               V = abs(V);

               index = find((V > epsilon) & (mask < 0.5));
               if(~isempty(index))
                mask(index) = i;
                adaptL(mask == i) = V1(mask == i);
               end
            end
            Ld = (Lm .* (1 + Lm / (white * white))) ./ (1 + adaptL);
    end
    
    for colorChannel = 1 : 3
        colorW = imageHDR(:, :, colorChannel) ./ L;
        tonemappedImage(:, :, colorChannel) = colorW .* Ld;
    end
end