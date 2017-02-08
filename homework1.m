clear 
X=0:20:1000;
Z=0:1:30;

T=zeros(31,51);
for x=1:1:51
    for z=1:1:13
    T(z,x)=(40-.08*(x-1)*20)-6.5*(z-1);
    end
end

for k=14:31
for    c=1:1:51;
    T(k,c)=T(13,c);
end
end

P=zeros(31,51);
for rr=1:51
P(1,rr)=95+.01*rr*20;
end

for r=2:31
    for cc=1:51
        P(r,cc)=P(r-1,cc)*exp((-1)/(.0293*(T(r,cc)+273.15)));
    end
end

figure 
contour(X,Z,P,[100,90,80,70,60,50,40,30,20,10,5,2]);
Zground=1+cos(2*pi*(X-500)/500);
Zground(X<250)=0;
Zground(X>750)=0;

hold on
plot(X,Zground)