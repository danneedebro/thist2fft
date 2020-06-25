function varargout = thist2fft(varargin)
%thist2fft Return frequency vector and amplitude vector for a time history
%   Detailed explanation goes here
%
%   thist2fft(t,y) performs a FFT on the time-value-pair t and y.
%   This is plotted in a interactive plot where it is possible to zoom in
%   to the range/window the FFT is performed on. This is done by first
%   zooming into the region of interest and then pressing a button.
%
%   thist2fft(t1,y1,t2,y2) plots the FFT of both y1 and y2 in the same
%   figure
%   
%   [f,amp]=thist2fft(t,y) returns the a frequency vector and a
%   amplitude vector (batch mode). f and amp is a N/2 -vector
%
%   [f,amp]=thist2fft(t1,y1,t2,y2) returns the a frequency vector and a
%   amplitude vector (batch mode) but this time f and amp is cell
%   
%   Example
%       fs=1000;
%       t=0:1/fs:2;
%       y=sin(2*pi*25*t)+sin(2*pi*47*t)+rand(size(t))-0.5;
%       thist2fft(t,y);
%
%
%   https://github.com/danneedebro/thist2fft
%
    auto_plot = 0;
    
    % Global variables
    fig=[];
    ax1=[]; ax2=[];
    
    nCurves=(nargin-mod(nargin,2))/2;
    h1=zeros(1,nCurves); h2=zeros(1,nCurves);
    curveNames=cell(1,nCurves);
    xData0=cell(1,nCurves);
    yData0=xData0; xData=xData0;yData=xData0;fData=xData0;ampData=xData0;
    varargout=cell(1,nargout);
   
    if nargin>=2
        for i=1:nCurves
            if isempty(inputname(2*(i-1)+2))
                curveNames{i}=sprintf('curve %d',i);
            else
                curveNames{i}=inputname(2*(i-1)+2);
            end
            xData0{i} = varargin{2*(i-1)+1};
            yData0{i} = varargin{2*(i-1)+2};
        end
        if nargin>=3, auto_plot = 1; end
    else
        fprintf('Error: Not enough inputs\n');
        return
    end
    
    % xData0 and yData0 is the uncorrupted data given and xData and yData
    % is a subset of this (zoomed, downsampled, etc)
    xData = xData0;
    yData = yData0;
        
    dofft;
    
    if nargout == 0, auto_plot = 1; end  % if no output is given, plot
    if nargout >= 2
        if nCurves==1
            varargout{1}=fData{1};
            varargout{2}=ampData{1};
        else
            varargout{1}=fData;
            varargout{2}=ampData;
        end
    end

    if auto_plot == 1
        plotfigs
    end

    function dofft()
    % Action: finds the one sided spectrum of xData and yData and stores it
    %         in fData and ampData
    %
        for j=1:nCurves
            L=length(xData{j});  % number of samples
    
            % Check if number of samples is dividable by 2. If not loose one sample
            if mod(L,2) == 1
                L = L - 1;
                xData{j} = xData{j}(1:L);
                yData{j} = yData{j}(1:L);
            end

            dt_max = max(diff(xData{j}));
            dt_min = min(diff(xData{j}));
            if dt_max/dt_min >= 1.001
                fprintf('Error: step size not uniform\n');
                continue;
            end
            Fs = 1/dt_max;

            Y = fft(yData{j});
            P2 = abs(Y/L);
            P1 = P2(1:L/2+1);
            P1(2:end-1) = 2*P1(2:end-1);

            ampData{j} = P1;
            fData{j} = Fs*(0:(L/2))/L;
        end
    end

    function plotfigs()
    % Action: Initializes the figure with two subplots
    %        
        ax1=subplot(2,1,1);
        ax2=subplot(2,1,2);
        
        for j=1:nCurves
            h1(j)=plot(ax1,xData{j},yData{j});
            h2(j)=plot(ax2,fData{j},ampData{j});
            set(h1(j),'DisplayName',curveNames{j});
            set(h2(j),'DisplayName',curveNames{j});
            hold(ax1,'on'); hold(ax2,'on');
        end
        hold(ax1,'off'); hold(ax2,'off');
        legend(ax1);legend(ax2);
        fig=get(ax1,'Parent');
        c = uicontrol;
        c.String = 'Update FFT window';
        c.Callback = @(es,ed) updatePlotWindow();
        xlabel(ax1,'Time (s)'); ylabel(ax1,'X(t)');
        xlabel(ax2,'Frequency (Hz)'); ylabel(ax2,'Amplitude');
        
        updateTitles;
        set(fig,'Name','thist2fft');
    end

    function updateTitles()
    % Action: Updates the plot titles with information about frequency
    % resolution and so on
        fs_str=''; dt_str=''; df_str=''; N_str='';
        for j=1:nCurves
            dt=xData{j}(2)-xData{j}(1);
            dt_str=sprintf('%s%2.2e,',dt_str,dt);
            fs=1/dt;
            fs_str=sprintf('%s%1.2f,',fs_str,fs);
            N=length(xData{j});
            N_str=sprintf('%s%d,',N_str,N);
            df=fData{j}(2)-fData{1}(1);
            df_str=sprintf('%s%1.2f,',df_str,df);
        end
        dt_str=dt_str(1:end-1);
        df_str=df_str(1:end-1);
        fs_str=fs_str(1:end-1);
        N_str=N_str(1:end-1);
        if nCurves>1
            dt_str=sprintf('[%s]',dt_str);
            fs_str=sprintf('[%s]',fs_str);
            df_str=sprintf('[%s]',df_str);
            N_str=sprintf('[%s]',N_str);
        end
        
        set(get(ax1,'Title'),'String',sprintf('Time history (dt=%s s, fs=%s Hz)',dt_str,fs_str));
        set(get(ax2,'Title'),'String',sprintf('FFT (N=%s, \\Deltaf=%s Hz)',N_str,df_str));
    end

    function updatePlotVectors()
    % Action: updates xData, yData, fData and ampData from visible range in
    %         time window
        for j=1:nCurves
            xlimits = get(ax1,'XLim');
            ind1=find(xData0{j}>=xlimits(1),1);
            ind2=find(xData0{j}>=xlimits(2),1);
            if isempty(ind1), ind1=1; end
            if isempty(ind2), ind2=length(xData0{j}); end
            xData{j}=xData0{j}(ind1:ind2);
            yData{j}=yData0{j}(ind1:ind2);
        end
        dofft;
    end

    function updatePlotWindow()
    % Action: updates plot window
    %
        updatePlotVectors;
%         msgbox(sprintf('Plot window size, N=%d',length(xData)));
        for j=1:nCurves
            set(h2(j),'XData',fData{j},'YData',ampData{j});
        end
        axis(ax1,'auto y')
        updateTitles;
    end

end