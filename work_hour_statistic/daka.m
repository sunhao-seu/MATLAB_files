% 最终的输出excel 表示不同学号不同天数的打卡时间（s）,x轴为学号，y轴为日期。（日期单位为天)。然后数据的单位为秒
%日期计算： date = year_store*days_of_year(31*12) + month_store * days_of_month(31) + day_store; [可以反推回是哪天]
% 时间的单位是秒
%TODO: BUG % 目前已0点为一天的开始。24点之前最晚的时间为一天的结束。如果有人熬夜打卡超过0点的话，会出现错误。


clc;
clear;

days_of_year = 31*12;
days_of_month = 31;

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
output_array = zeros(date_statistic_num+1,id_statistic_num+1);
for i = 2:date_statistic_num+1
%     year = floor(date_statistic(i-1)/days_of_year);
%     month = floor( (date_statistic(i-1) - year*days_of_year)/days_of_month );
%     day = date_statistic(i-1) - year*days_of_year - month*days_of_month;
%     ymd = datetime(year,month,day,'Format','y-m-d');
%     output_array(i,1) = ymd;
    output_array(i,1) = date_statistic(i-1);
   
end
for i = 2:id_statistic_num+1
    output_array(1,i) = id_statistic(i-1);
end

%对于每个学生，统计其每一天的打卡时间
for id_count = 1:(id_statistic_num) %对于每个学生
    for date_count = 1:(date_statistic_num) %对于每一天
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
                if(day_second_store < day_second_store_morning)
                    day_second_store_morning = day_second_store;
                end
                if(day_second_store > day_second_store_night)
                    day_second_store_night = day_second_store;
                end
            end
        end
        %找到早晚时间后,打卡间隔超过两个小时认为有效,存入输出
        if(day_second_store_night - day_second_store_morning > 2*60*60)
            output_array(date_count+1,id_count+1) = day_second_store_night - day_second_store_morning;
        end
    end
end

xlswrite('signin_time_statistic.xls',output_array);
