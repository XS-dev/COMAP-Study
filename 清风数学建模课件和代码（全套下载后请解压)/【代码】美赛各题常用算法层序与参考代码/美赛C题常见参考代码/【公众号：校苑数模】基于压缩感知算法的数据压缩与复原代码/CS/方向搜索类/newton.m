%牛顿梯度法
% function x_recovery=newton(M,N,x,m)
clc;
clear

K=3;      %  稀疏度(做FFT可以看出来)
N=320;    %  信号长度
M=100;     %  测量数(M>=K*log(N/K),至少40,但有出错的概率)
m=10;
% m=10;     %迭代次数
% f1=50;    %  信号频率1
% f2=100;   %  信号频率2
% f3=200;   %  信号频率3
% f4=400;   %  信号频率4
% fs=800;   %  采样频率
% ts=1/fs;  %  采样间隔
% Ts=1:N;   %  采样序列
% x=0.3*cos(2*pi*f1*Ts*ts)+0.6*cos(2*pi*f2*Ts*ts)+0.1*cos(2*pi*f3*Ts*ts)+0.9*cos(2*pi*f4*Ts*ts);  %  完整信号
% x=x';
[x,fs,bits]=WAVREAD('M1_1',[8400 8719]);
A=randn(M,N);
y=A*x;
% B=fft(eye(N,N))/sqrt(N); %y=A*x=A*B'*s=T*s;    s=B*x;
for kk=2:N
    for nn=1:N
        dctbasis(kk,nn)=(2/N)^0.5*cos((2*(nn-1)+1)*(kk-1)*pi/2/N);
    end
end
for nn=1:N
    dctbasis(1,nn)=(1/N)^0.5*cos((2*(nn-1)+1)*(1-1)*pi/2/N);
end

B=dctbasis;                        %  傅里叶正变换矩阵
T=A*B';
Aug_t=[];
% Id=[];
rn=y;
% a=1;%步长

hat_x=zeros(N,1);

% G=Aug_t'*Aug_t;
% b=Aug_t'*y;
% f=1/2*hat_x'*G*hat_x-b'*hat_x;

% while(norm(rn)>10^-2)
    for times=1:12
    for col=1:N
        inner(col)=abs(T(:,col)'*rn);
    end
    [val,pos]=max(inner);
    Aug_t=[Aug_t,T(:,pos)];  %M*i
   l=size(Aug_t,2);
    pos_array(times)=pos; %i*1
    

     H=-Aug_t'*Aug_t;                              %海森矩阵i*i
    gn=Aug_t'*rn;                                 %i*1,梯度
 d=-H^(-1)*gn;                                      %步长i*1，d=(rn'*cn)/norm(cn).^2;
%     a=-(gn'*d)/(d'*H*d);
     hat_x(pos_array)=hat_x(pos_array)+d  ;         %hat_x(pos_array)=hat_x(pos_array)+d*gn  
   
  
   rn=rn-Aug_t*d;                                  %a*Aug_t*d
     T(:,pos)=zeros(M,1); 
% if norm(rn)<10^-3
%      break;
%  end
% times=times+1;
   
end

x_recovery=real(B'*hat_x);
times
rn=norm(rn)
error=norm(x_recovery-x)^2/norm(x)^2  ;
snr=10*log10(1/error)
plot(x_recovery,'k.-')
hold on;
plot(x,'r');
legend('x_recovery','x');
hold off