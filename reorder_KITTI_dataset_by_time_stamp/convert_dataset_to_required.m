%% 重新整理KITTI数据集中的 image, pointcloud, gnss 等数据，将这些数据按时间戳排序，存在一个txt文件里。
%  输出格式为 timestamp type data_file_path(relative path)

%%
clear;
clc;
clf;

% 操作路径，绝对路径
maindir  = "\\nas1.shtech.mobi\Share\DataSets\KITTI_raw\2011_10_03\2011_10_03_drive_0027_sync";

% 获取当前路径下所有的文件夹
subdir  = dir( maindir  );

time_data = zeros(10000*10,1);
path_data = strings(10000*10,1);

time_data_array = [time_data; path_data];

% 重要！ 有哪些传感器，其实也就是有哪些子文件夹。
sensor_type = ["image_00","image_01","image_02","image_03","oxts","velodyne_points"];
sensor_num = length(sensor_type);
store_end_index = 0;

for i = 1 : length( subdir )
    if( isequal( subdir( i ).name, '.' )||...
        isequal( subdir( i ).name, '..')||...
        ~subdir( i ).isdir)               % 如果不是目录则跳过
        continue;
    end
    
    % 获取文件夹名称，然后根据名称分别处理。
    sensor_dir = subdir( i ).name;
    
    switch(sensor_dir)
        case(sensor_type(1))    % 如果是第一个类型的，则将该文件夹下所有文件和时间戳全部存起来。
            [time_data,path_data,store_end_index] = obtain_info(maindir,sensor_type(1),time_data,path_data,store_end_index);        
        case(sensor_type(2))
            [time_data,path_data,store_end_index] = obtain_info(maindir,sensor_type(2),time_data,path_data, store_end_index);        
        case(sensor_type(3))
            [time_data,path_data,store_end_index] = obtain_info(maindir,sensor_type(3),time_data,path_data, store_end_index);        
        case(sensor_type(4))
            [time_data,path_data,store_end_index] = obtain_info(maindir,sensor_type(4),time_data,path_data, store_end_index);        
        case(sensor_type(5))
            [time_data,path_data,store_end_index] = obtain_info(maindir,sensor_type(5),time_data,path_data, store_end_index);
        case(sensor_type(6))
            [time_data,path_data,store_end_index] = obtain_info(maindir,sensor_type(6),time_data,path_data, store_end_index);        
    end
    
end

% sort the data by the timestamp
time_data = time_data(1:store_end_index);
[time_data_orderd,index_ordered] = sort(time_data);

% 按时间戳排序，存入结构体中。
useful_data = struct('timestamp','file_dir');
for i = 1 : store_end_index
    useful_data(i).timestamp = time_data(index_ordered(i));
    useful_data(i).file_dir = path_data(index_ordered(i));
end


%% 将结果存入txt中

delete("export_timestamp_data.txt");                     %需要改文件名称的地方
fid=fopen("export_timestamp_data.txt",'w');           
for i = 1 : store_end_index
    stored_time_stamp = datestr(useful_data(i).timestamp,'yyyy-mm-dd HH:MM:SS.FFF');
    
    % 将数据文件的绝对路径按反斜杠分割，提取出传感器类型和文件名。
    dir_strings = strsplit(useful_data(i).file_dir,'\');
    type = dir_strings( length(dir_strings)-1 );
    file_name = dir_strings( length(dir_strings));
    
    fprintf(fid,'%s\t%s\t%s\n',stored_time_stamp, type, type+'\'+file_name);          %data：需要导出的数据名称，10位有效数字，保留3位小数（包含小数点），f为双精度，g为科学计数法
end
fclose(fid);


%%
% functions， 传入绝对路径以及传感器文件夹名称，

function [time_data,path_data,store_end_index] = obtain_info(maindir,sensor_type,time_data,path_data,store_begin_index)
    disp(maindir+"\"+sensor_type);
    time_stamp_file = maindir+"\"+sensor_type+"\timestamps.txt";
    [y,m,d,hh,mm,ss]=textread(time_stamp_file,'%d-%d-%d %d:%d:%f');
    time_ordered=datenum(y,m,d,hh,mm,ss); %转成时间序列
    disp(length( time_ordered ));

    data_dir_name = maindir+"\"+sensor_type+"\data";
    data_subdir  = dir( data_dir_name  );
    disp(length( data_subdir ) - 2);    % 去掉 . 和 .. 这两个文件夹 【分别是第一和第二个】

    %sensor_data_num(1) = length( time_ordered );

    for j = 1:length( time_ordered )
        time_data(store_begin_index+j) = time_ordered(j);
        path_data(store_begin_index+j) =  strcat( data_subdir(j+2).folder, data_subdir(j+2).name ) ;
    end
    
    store_end_index = store_begin_index + length( time_ordered );
end
