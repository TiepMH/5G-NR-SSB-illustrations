% REFs: 
% https://www.mathworks.com/help/5g/gs/synchronization-signal-blocks-and-bursts.html
% https://www.sharetechnote.com/html/5G/5G_FrameStructure.html#SSB_CaseB_Tx_3Ghz

clear all; clc;

for loop=1:7
    %% Define SS block pattern
    if loop==1
        f = 3.5; % GHz
        Case = 'Case A';
    elseif loop==2
        f = 3.5; % GHz
        Case = 'Case B';
    elseif loop==3
        f = 3.5; % GHz
        Case = 'Case C';
    elseif loop==4
        f = 35; % GHz
        Case = 'Case D';
    elseif loop==5
        f = 35; % GHz
        Case = 'Case E';
    elseif loop==6
        f = 35; % GHz
        Case = 'Case F';
    elseif loop==7
        f = 35; % GHz
        Case = 'Case G';
    end
    
    %% Find the OFDM symbol indices that specify the START positions of SS blocks within an SS burst
    % Note: The start position of an SS block is the position of the PSS within that SS block
    SymbolIndices_indicating_SSblocks = find_OFDM_symbol_indices_that_specify_PSS_positions(Case, f);
    
    %% Determine the (numerology, SCS) pair corresponding to the SS block pattern
    switch lower(Case) 
        case 'case a'
            mu = 0; 
            SCS = 15;
        case {'case b', 'case c'}
            mu = 1; 
            SCS = 30;
        case 'case d'
            mu = 3; 
            SCS = 120;
        case 'case e'
            mu = 4; 
            SCS = 240;
        case 'case f'
            mu = 5; 
            SCS = 480;
        case 'case g'
            mu = 6; 
            SCS = 960;
    end
    
    %% Generate an SS burst
    ncellid = 17;
    pbchIndices = nrPBCHIndices(ncellid); % Create the PBCH indices
    % Physical Broadcast Channel (PBCH)
    cw = randi([0 1],864,1); % The PBCH carries a codeword of length 864 bits, created by performing BCH encoding of the MIB
    
    % Create SS burst grid
    nSubframes = 5; % a half frame = 5 subframes
    symbolsPerSlot = 14; % each slot as having 14 OFDM symbols (for normal cyclic prefix length)
    nSymbols = symbolsPerSlot * 2^mu * nSubframes; % the total number of OFDM symbols in an SS burst
    ssburst = zeros([240 nSymbols]); % an empty grid for the whole SS burst
    
    % Primary Synchronization Signal (PSS)
    pssSymbols = nrPSS(ncellid);
    pssIndices = nrPSSIndices; % the PSS indices
    % Secondary Synchronization Signal (SSS) 
    sssSymbols = nrSSS(ncellid); % the same cell identity as configured for the PSS
    sssIndices = nrSSSIndices; % the SSS indices
    
    % Create SS burst content
    ssblock = zeros([240 4]);
    
    % map the PSS symbols to the SS/PBCH block
    ssblock(pssIndices) = 1 * pssSymbols; % TS 38.211 Section 7.4.3.1.1
    % map the SSS symbols to the SS/PBCH block
    ssblock(sssIndices) = 2 * sssSymbols; % TS 38.211 Section 7.4.3.1.2
    
    for ssbIndex = 1:length(SymbolIndices_indicating_SSblocks)
        
        i_SSB = mod(ssbIndex - 1, 8);
        ibar_SSB = i_SSB;
    
        % Scrambling and modulation
        v = i_SSB;
        pbchSymbols = nrPBCH(cw,ncellid,v); % TS 38.213 Section 4.1
    
        % map the PBCH symbols to the SS/PBCH block
        ssblock(pbchIndices) = 3 * pbchSymbols; % TS 38.211 Section 7.4.3.1.3
        
        % PBCH Demodulation Reference Signal (PBCH DM-RS)
        dmrsSymbols = nrPBCHDMRS(ncellid,ibar_SSB); % TS 38.211 Section 7.4.1.4.1
        dmrsIndices = nrPBCHDMRSIndices(ncellid);
        % map the PBCH DM-RS symbols to the SS/PBCH block
        ssblock(dmrsIndices) = 4 * dmrsSymbols; % TS 38.211 Section 7.4.3.1.3
        %
        ssburst(:,SymbolIndices_indicating_SSblocks(ssbIndex) + (0:3)) = ssblock;
    end
    
    % Plot the SS burst content 
    abs_ssburst = abs(ssburst);
    figure('Position', [100 200 560 350]); 
    imagesc_with_white_background(abs_ssburst)
    clim([0 4]);
    axis xy;
    xlabel('OFDM symbol index');
    ylabel('Subcarrier index');
    switch lower(Case) 
        case 'case a'
            title(['SS burst (FR1, ', Case, ', $\mu = $ ', num2str(mu), ', SCS = ', num2str(SCS), ' kHz)'], 'Interpreter','latex');
        case {'case b', 'case c'}
            title(['SS burst (FR1, ', Case, ', $\mu = $ ', num2str(mu), ', SCS = ', num2str(SCS), ' kHz)'], 'Interpreter','latex');
        case 'case d'
            title(['SS burst (FR2, ', Case, ', $\mu = $ ', num2str(mu), ', SCS = ', num2str(SCS), ' kHz)'], 'Interpreter','latex');
        case 'case e'
            title(['SS burst (FR2, ', Case, ', $\mu = $ ', num2str(mu), ', SCS = ', num2str(SCS), ' kHz)'], 'Interpreter','latex');
        case 'case f'
            title(['SS burst (FR2, ', Case, ', $\mu = $ ', num2str(mu), ', SCS = ', num2str(SCS), ' kHz)'], 'Interpreter','latex');
        case 'case g'
            title(['SS burst (FR2, ', Case, ', $\mu = $ ', num2str(mu), ', SCS = ', num2str(SCS), ' kHz)'], 'Interpreter','latex');
    end
    %
end % end of for loop=1:7

%% Local function 
function imagesc_with_white_background(image)
    imagesc(image);
    colormap_range=64; % default = 64
    [~, xout] = hist(image(:), colormap_range); %#ok
    [~, ind] = sort(abs(xout)); % sort values
    cm = parula;
    cm(ind(1),:) = [1 1 1]; % white background
    colormap(cm);
    % Add legend
    colormap(cm);
    hold on;
    for k = 1:5 % k=1 refers to the white background
        hidden_h(k) = surf(uint8(k-[1 1;1 1]), 'edgecolor', 'none'); %#ok 
    end
    hold off
    % uistack(hidden_h, 'bottom');
    legend(hidden_h, {'Set to 0', 'PSS', 'SSS', 'PBCH', 'DM-RS for PBCH'} )
end

function SymbolIndices_indicating_SSblocks = find_OFDM_symbol_indices_that_specify_PSS_positions(Case, f)
    % Refs:
    % www.sharetechnote.com/html/5G/5G_FrameStructure.html#SSB_CaseB_Tx_3Ghz
    % The pattern of an SS/PBCH block is specified by the cell search process (see 3GPP TS 38.213)
    if strcmpi(Case,'Case A') % Case A => 15 kHz
        if f<=3 % GHz
            n = [0, 1];
        elseif (3<f) && (f<=6) % GHz
            n = [0, 1, 2, 3];
        end
        SymbolIndices_indicating_SSblocks = [2; 8] + 14*n;
        SymbolIndices_indicating_SSblocks = SymbolIndices_indicating_SSblocks(:).';
    elseif strcmpi(Case,'Case B') % Case B => 30 kHz
        if f<=3 % GHz
            n = [0];
        elseif (3<f) && (f<=6) % GHz
            n = [0, 1];
        end
        SymbolIndices_indicating_SSblocks = [4; 8; 16; 20] + 28*n;
        SymbolIndices_indicating_SSblocks = SymbolIndices_indicating_SSblocks(:).';
    elseif strcmpi(Case,'Case C') % Case C => 30 kHz
        if f<=3 % GHz
            n = [0, 1]; 
        elseif (3<f) && (f<=6) % GHz
            n = [0, 1, 2, 3]; 
        end
        SymbolIndices_indicating_SSblocks = [2; 8] + 14*n;
        SymbolIndices_indicating_SSblocks = SymbolIndices_indicating_SSblocks(:).';
    elseif strcmpi(Case,'Case D') % Case D => 120 kHz
        if f>6 % GHz
            n = [0, 1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18];
        end
        SymbolIndices_indicating_SSblocks = [4; 8; 16; 20] + 28*n;
        SymbolIndices_indicating_SSblocks = SymbolIndices_indicating_SSblocks(:).';
    elseif strcmpi(Case,'Case E') % Case E => 240 kHz
        if f>6 % GHz
            n = [0, 1, 2, 3, 5, 6, 7, 8];
        end
        SymbolIndices_indicating_SSblocks = [8; 12; 16; 20; 32; 36; 40; 44] + 56*n;
        SymbolIndices_indicating_SSblocks = SymbolIndices_indicating_SSblocks(:).';
    elseif strcmpi(Case,'Case F') % Case F => 480 kHz
        if f>6 % GHz
            n = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31];
        end
        SymbolIndices_indicating_SSblocks = [2; 9] + 14*n;
        SymbolIndices_indicating_SSblocks = SymbolIndices_indicating_SSblocks(:).';
    elseif strcmpi(Case,'Case G') % Case G => 960 kHz
        if f>6 % GHz
            n = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31];
        end
        SymbolIndices_indicating_SSblocks = [2; 9] + 14*n;
        SymbolIndices_indicating_SSblocks = SymbolIndices_indicating_SSblocks(:).';
    end
end


