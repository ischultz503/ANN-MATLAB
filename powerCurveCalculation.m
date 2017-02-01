% Calculating MSE and R^2 for BMW from look up table

powerCurve=xlsread('BMW_powercurve.xlsx');
ModelOUT=xlsread('ModelOut_normalized.xlsx');
powerCurveFCST=zeros(8760,3);
  
 
for i=1:8760
    if isnan(ModelOUT(i,10))==1;
        powerCurveFCST(i,1)=NaN;
        powerCurveFCST(i,2)=NaN;
    else
      
    ind=find(ModelOUT(i,10)*90-powerCurve(:,1)>=0 & ModelOUT(i,10)*90-powerCurve(:,1)<=1);
    powerCurveFCST(i,1)=powerCurve(ind,2);
    powerCurveFCST(i,2)=ModelOUT(i,13)*102;
    powerCurveFCST(i,3)=(powerCurveFCST(i,2)-powerCurveFCST(i,1))^2;
    end
      
end

  MSE=nanmean(powerCurveFCST(:,3))