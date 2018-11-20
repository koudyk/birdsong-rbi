function [ r ] = yb_segmentSyllables( audio,fs)

if ischar(audio)
[a,fs]=audioread(audio);
else a=audio;
    if nargin<2 || isempty(fs), disp('Missing sampling rate'), end
end
a=mean(a,2); % take mean of the two channels if there are 2 
r=yb_yinbird(a,fs);

ap0=sqrt(r.ap0);
pwr=sqrt(r.pwr);
f0=r.f0;

Nshift=1;
f0_shifted=[zeros(1,Nshift) f0(1:end-Nshift)];
change=abs(f0-f0_shifted);
%change2=sqrt(change');

Achange=0.1;
Apwr=0;
Aap0=1;
thresh=.2;

t= ...
    (Achange*change)+...
    (Apwr*(1-pwr))+...
    (Aap0*ap0);

s=f0;
s(t>thresh*2)=NaN;

plot(f0)
hold on, plot(s,'linewidth',3)


%s=f0.*





end

