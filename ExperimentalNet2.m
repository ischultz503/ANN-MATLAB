% Create blank matrices for forecast results and MSE dailys (nxtday, training)
Daily_results=zeros(365,100);
Hourly_results=zeros(8760,5);
squared_y_minust=zeros(24,1);
daily_avgt=zeros(24,1);
daily_avgy=zeros(24,1);
r_squared_calc=zeros(24,3);
%completeResults=zeros(500,6);

% Import dataset, including ALL data that will be used for train and test.
data=xlsread('ModelOut_normalized.xlsx');

% Define arrays for the training and performance fucntions
tFunc={'trainlm';'trainbr';'trainscg';'trainrp';'trainbfg';'traincgb';'traincgf';'traincgp';'traingdx'};
pFunc={'mse';'sse';'mae';'sae'};

%Choose length of training window, number of days to test, # hours to predict
testing_days=300;
start_day=1;
hours_predicted=24;
r=557;

for TW=20:15:50

% Loop through number of hidden nuerons    
for n=9:2:13
    
    % Loop through training fucntions
    for t=1:9
    trainFcn=tFunc{t};
    %Loop through performance fucntions
    for p=1:4
           for i=start_day:(start_day-1+testing_days)
               
           x_full=transpose(data(:,4:12));
           t_full=transpose(data(:,13));

                    % Pick network parameters (# nuerons, training dataset,
                    % val/train indices, transfer fcn, perform fcn
                    hiddenLayerSize = n;
                    net=feedforwardnet(hiddenLayerSize, trainFcn);
                    x_train=x_full(:,1+24*(i-1):24*(i-1)+TW*24);
                    t_train=t_full(:,1+24*(i-1):24*(i-1)+TW*24);
                    net.divideFcn='dividerand';
                    net.layers{1}.transferFcn = 'tansig';
                    net.divideParam.trainRatio = 70/100;
                    net.divideParam.valRatio = 30/100;
                    net.divideParam.testRatio = 0/100;
                    net.performFcn=pFunc{p};    
                    
                    %Train network
                    [net, tr] = train(net,x_train,t_train);


        %Populate hourly results matrix with target value and network output
        %for each hour of each day, also calc squared error each hour
        for j=1:hours_predicted
        Hourly_results(24*(i-1)+j,1)=i;
        Hourly_results(24*(i-1)+j,2)=j;
        Hourly_results(24*(i-1)+j,3)=net(x_full(:,24*(i-1)+TW*24+j));
        Hourly_results(24*(i-1)+j,4)=t_full(:,24*(i-1)+TW*24+j);
        Hourly_results(24*(i-1)+j,5)=(Hourly_results(24*(i-1)+j,3)-Hourly_results(24*(i-1)+j,4))^2;
        end
            %For each network that is trained (1/day) calculate the R-squared value
            %and average squared error (MSE) for each day
            for e=1:hours_predicted
            squared_error(e)=(Hourly_results(24*(i-1)+e,3)-Hourly_results(24*(i-1)+e,4))^2;
            daily_avgt(1:24)=nanmean(Hourly_results(24*(i-1)+1:24*(i-1)+24,4));
            daily_avgy(1:24)=nanmean(Hourly_results(24*(i-1)+1:24*(i-1)+24,3));
            r_squared_calc(e,1)=(Hourly_results(24*(i-1)+e,4)-daily_avgt(e));
            r_squared_calc(e,2)=(Hourly_results(24*(i-1)+e,3)-daily_avgy(e));
            r_squared_calc(e,3)=r_squared_calc(e,1)*r_squared_calc(e,2);
            end
            
                %MSE & R-squared calcs per day (ie. per each trained network) and also MSE and R^2 for the whole years run
                Daily_results((i-1)+1,1+7*(n-1))=n;
                Daily_results((i-1)+1,2+7*(n-1))=i;
                Daily_results((i-1)+1,3+7*(n-1))=nanmean(squared_error);
                Daily_results(1,4+7*(n-1))=nanmean(Hourly_results(:,5));
                Daily_results((i-1)+1,5+7*(n-1))=(nansum(r_squared_calc(:,3))/(nansum(r_squared_calc(:,1).^2)*nansum(r_squared_calc(:,2).^2))^.5)^2;
                end
  
                        %Calculate R^2 for whole year, save in Daily_results
                        for f=1:testing_days*24
                        yearlyavgt(1:testing_days*24,1)=nanmean(Hourly_results(:,4));
                        yearlyavgy(1:testing_days*24,1)=nanmean(Hourly_results(:,3));
                        r_squaredCalc2(f,1)=(Hourly_results(f,4)-yearlyavgt(f));
                        r_squaredCalc2(f,2)=(Hourly_results(f,3)-yearlyavgy(f));
                        r_squaredCalc2(f,3)=r_squaredCalc2(f,1)*r_squaredCalc2(f,2);
                        end
                        
                % After each completed run (every hour all year, new
                % network each day).
                
                completeResults(r,1)=TW;
                completeResults(r,2)=n;
                completeResults(r,3)=p;
                completeResults(r,4)=t;
                completeResults(r,5)=nanmean(Hourly_results(:,5));
                completeResults(r,6)=(nansum(r_squaredCalc2(:,3))/(nansum(r_squaredCalc2(:,1).^2)*nansum(r_squaredCalc2(:,2).^2))^.5)^2;
                r=r+1;
                
                Daily_results(1,6+7*(n-1))=(nansum(r_squaredCalc2(:,3))/(nansum(r_squaredCalc2(:,1).^2)*nansum(r_squaredCalc2(:,2).^2))^.5)^2;
                        
                %Finally, calculate average MSE across all days, by hour (ie. average error
                %for hour 1, hour 2 hou3 etc.) Plot these results to show skill dropoff.
                for h=1:24
                    for d=1:testing_days
                    avg_error_calc(d,h)=Hourly_results(24*(d-1)+h,5);
                    end
                avg_error_hourly(h,1)=h;
                avg_error_hourly(h,2)=nanmean(avg_error_calc(:,h));        
                end
                
                figure;
                hourlyPlotName=strcat('errorByHour_',num2str(n),'_neurs',num2str(TW),'day_wind_trainFcn:_',tFunc{t},'perf_',pFunc{p});
                plot(avg_error_hourly(:,2))
                print(hourlyPlotName,'-dpng','-r0')
                close('all')
                figure;
                timeSeriesPlotName=strcat('timeSeries_',num2str(n),'_neurs',num2str(TW),'day_wind_trainFcn:_',tFunc{t},'perf_',pFunc{p});
                plot(1:24*testing_days,Hourly_results((start_day-1)*24+1:(start_day-1)*24+testing_days*24,4),1:24*testing_days,Hourly_results((start_day-1)*24+1:(start_day-1)*24+testing_days*24,3))
                print(timeSeriesPlotName,'-dpng','-r0')
                close('all')
                figure;
                regressionPlotName=strcat('fullRegression_',num2str(n),'_neurs',num2str(TW),'day_wind_trainFcn:_',tFunc{t},'perf_',pFunc{p});
                plotregression(Hourly_results((start_day-1)*24+1:(start_day-1)*24+testing_days*24,4),Hourly_results((start_day-1)*24+1:(start_day-1)*24+testing_days*24,3));
                print(regressionPlotName,'-dpng','-r0')
                close('all')
                end
        end
        end
end