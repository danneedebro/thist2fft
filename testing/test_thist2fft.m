function test_thist2fft()
    addpath('../')
    
    fs=1000;
    t1=0:1/fs:2;
    t2=t1(1:2:end);
    y1=sin(2*pi*25*t1)+sin(2*pi*47*t1)+rand(size(t1))-0.5;
    y2=sin(2*pi*13*t2)+sin(2*pi*67*t2)+rand(size(t2))-0.5;

    [f,amp]=thist2fft(t1,y1);
    assert(length(f)==1001,'Error: frequency-vector not 1001 elements long');
    assert(length(amp)==1001,'Error: amplitude-vector not 1001 elements long');
    assert(abs(f(end)-0.5*fs)<0.001,'Error: last frequency is not 500 Hz');
    
    [f,amp]=thist2fft(t1,y1,t2,y2);
    assert(iscell(f),'Error: frequency output is not a cell');
    assert(iscell(amp),'Error: frequency output is not a cell');
    assert(length(f)==2,'Error: frequency output does not contain 2 vectors');
    assert(length(amp)==2,'Error: frequency output does not contain 2 vectors');
    assert(length(f{1})==1001,'Error: frequency-vector for curve 1 not 1001 elements long');
    assert(length(amp{1})==1001,'Error: amplitude-vector for curve 1 not 1001 elements long');
    assert(length(f{2})==501,'Error: frequency-vector for curve 2 not 501 elements long');
    assert(length(amp{2})==501,'Error: amplitude-vector for curve 2 not 501 elements long');
    
    % Check error if time-step not equal
    t_timestep_not_equal=[0:1/fs:1,1.001:0.5/fs:1.5];
    y_timestep_not_equal=sin(2*pi*34*t_timestep_not_equal);
    [f__timestep_not_equal,amp__timestep_not_equal]=thist2fft(t_timestep_not_equal,y_timestep_not_equal);
    assert(isempty(f__timestep_not_equal),'Error: output not empty');
    
    
end