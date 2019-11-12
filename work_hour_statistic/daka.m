% 最终的输出excel 表示不同学号不同天数的打卡时间（s）,x轴为学号，y轴为日期。（日期单位为天)。然后数据的单位为秒
%日期计算： date = year_store*days_of_year(31*12) + month_store * days_of_month(31) + day_store; [可以反推回是哪天]
% 时间的单位是秒
%TODO: BUG % 目前已0点为一天的开始。24点之前最晚的时间为一天的结束。如果有人熬夜打卡超过0点的话，会出现错误。


clc;
clear;

days_of_year = 31*12;
days_of_month = 31;
morning_threshold = 4*3600;
work_hour_least = 1*60*60;

FileName='data.dat'; %文件名
[id,y,m,d,hh,mm,ss,d1,d2,d3,d4]=textread(FileName,'%d %d-%d-%d %d:%d:%d %d %d %d %d');  %读取文件中的数据
id_statistic = zeros(1000,1);   %统计有多少学号并存入数组
id_statistic_num = 0;           %学号计数
date_statistic_num = 0;         %日期计数
date_statistic = zeros(1000,1); %统计有多少日期并存入数组

%遍历所有数据，找出有多少学号，多少日期
for i = 1:size(id,1)
    id_store = id(i);
    year_store = y(i);
    month_store = m(i);
    day_store = d(i);
    date = year_store*days_of_year + month_store * days_of_month + day_store;
    hour_store = hh(i);
    minite_store = mm(i);
    second_store = ss(i);
    if(~ismember(id_store,id_statistic))
        %将学号存入数组
        id_statistic_num = id_statistic_num + 1;
        id_statistic(id_statistic_num) = id_store;
    end
    
    if(~ismember(date,date_statistic))
        %将所有日期存入数组
        date_statistic_num = date_statistic_num + 1;
        date_statistic(date_statistic_num) = date;
    end
end

%输出矩阵，x轴为学号，y轴为日期。
output_array = strings(date_statistic_num*3+1,id_statistic_num+1);
for i = 2:date_statistic_num+1
    if(mod((i-1),3)==1)
        year = ( floor(date_statistic(i-1)/days_of_year) );
        month = ( floor( (date_statistic(i-1) - year*days_of_year)/days_of_month ) );
        day = ( date_statistic(i-1) - year*days_of_year - month*days_of_month );
        %ymd = [num2str(year),num2str(month),num2str(day)];
        ymd = datetime(year,month,day,'Format','eeee, MMMM d, y');
        output_array(i,1) = string(ymd) + '  sign in time:';
    end
    if(mod((i-1),3)==2)
        output_array(i,1) = 'sign out time:';
    end
    if(mod((i-1),3)==0)
        output_array(i,1) = 'work time (h):';
    end
   
end
for i = 2:id_statistic_num+1
    output_array(1,i) = id_statistic(i-1);
end

%对于每个学生，统计其每一天的打卡时间
for id_count = 1:(id_statistic_num) %对于每个学生
    for date_count = 1:(date_statistic_num) %对于每一天
        stay_up_flag = 0;       %每一天都以为是不熬夜的一天
        day_second_store_morning = 24*60*60;    %记录该天早上打卡时间
        day_second_store_night = 0;             %记录该天晚上打卡时间
        for data_count = 1:size(id,1)    %统计表格中的所有数据
            year_store = y(data_count);
            month_store = m(data_count);
            day_store = d(data_count);
            date_store = year_store*days_of_year + month_store * days_of_month + day_store;
            if((id(data_count) == id_statistic(id_count)) &&  (date_store == date_statistic(date_count)))   %如果学号对上了，日期也对上了
                day_second_store = hh(data_count)*60*60 + mm(data_count)*60 + ss(data_count);   %当前打卡时间
                %找出该学号这一天的早晚打卡时间，单位 秒
                if(day_second_store < morning_threshold)    %如果早上太早，认为是熬夜了
                    stay_up_flag = 1;
                    yesterday_morning_sign_out = day_second_store;  %可能有问题，如果有人凌晨打两次卡的话
                else
                    if(day_second_store < day_second_store_morning)
                        day_second_store_morning = day_second_store;
                    end
                end
                
                if(day_second_store > day_second_store_night)
                    day_second_store_night = day_second_store;
                end
            end
        end
        %找到早晚时间后,打卡间隔超过两个小时认为有效,存入输出
        if(day_second_store_night - day_second_store_morning > work_hour_least)
            output_array(2+3*(date_count-1),id_count+1) =  string(floor(day_second_store_morning/3600)) + ':' + string(floor(mod(day_second_store_morning,3600)/60));
            output_array(3+3*(date_count-1),id_count+1) =  string(floor(day_second_store_night/3600)) + ':' + string(floor(mod(day_second_store_night,3600)/60));
            output_array(4+3*(date_count-1),id_count+1) = string( roundn( (day_second_store_night - day_second_store_morning)/3600, -2) ) + ' hours';
        end
        
        % TODO: 如果早上打卡时间小于4点，认为是昨天晚上熬夜了。这时候应该更改昨天的最晚时间和时长； 然后今天的时间也要去掉这个早晨的时间重新考量。
        if(stay_up_flag)
            stay_up_flag = 0;
            %处理昨天的数据
            date_count_yesterday = date_count -1;
            day_second_store_night = yesterday_morning_sign_out + 24*60*60;  %昨天的离开时间是今天早上的打卡时间
            for data_count = 1:size(id,1)    %统计表格中的所有数据
                year_store = y(data_count);
                month_store = m(data_count);
                day_store = d(data_count);
                date_store = year_store*days_of_year + month_store * days_of_month + day_store;
                if((id(data_count) == id_statistic(id_count)) &&  (date_store == date_statistic(date_count_yesterday)))   %如果学号对上了，日期也对上了
                    day_second_store = hh(data_count)*60*60 + mm(data_count)*60 + ss(data_count);   %当前打卡时间
                    %但是昨天早上的时间还是正常的
                    if(day_second_store < day_second_store_morning)
                        day_second_store_morning = day_second_store;
                    end
                end
            end
            %找到早晚时间后,打卡间隔超过两个小时认为有效,存入输出
            if(day_second_store_night - day_second_store_morning > work_hour_least)
                output_array(2+3*(date_count_yesterday-1),id_count+1) =  string(floor(day_second_store_morning/3600)) + ':' + string(floor(mod(day_second_store_morning,3600)/60));
                output_array(3+3*(date_count_yesterday-1),id_count+1) =  string(floor(day_second_store_night/3600)) + ':' + string(floor(mod(day_second_store_night,3600)/60)) + '  stay_up flag';
                output_array(4+3*(date_count_yesterday-1),id_count+1) = string( roundn( (day_second_store_night - day_second_store_morning)/3600, -2) ) + ' hours';
            end
        end
        
    end
end

xlswrite('signin_time_statistic.xls',output_array);
