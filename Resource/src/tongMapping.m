%Tone Mapping Program
%input:
%   imageHDR: the HDR image
%   type: global or local
%
function tonemappedImage = toMapping(imageHDR, type)
    tonemappedImage = zeros(size(imageHDR));
    alpha = 0.18;
    delta = 1e-6;
    Lw = 0.23 * imageHDR(:, :, 1) + 0.69 * imageHDR(:, :, 2) + 0.08 * imageHDR(:, :, 2);

    meanLw = exp(mean(mean(log(delta + Lw))));
    Lm = (alpha / meanLw) * Lw;
    
    if(type == 'global')    
        white = 1.5;
        Ld = (Lm .* (1 + Lm / (white * white))) ./ (1 + Lm);
        Ld(isnan(Ld))=0;
    end
    
    if(type == 'local')
        
    end
    
    for colorChannel = 1 : 3
        colorW = imageHDR(:, :, colorChannel) ./ Lw;
        tonemappedImage(:, :, colorChannel) = colorW .* Ld;
    end
end