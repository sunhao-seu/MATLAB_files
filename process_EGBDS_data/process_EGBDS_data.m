%% process the data from EGBDS test
%input:
% EGBDS_PL dataset_FPGA/3000_frames_map_surf_373693.pcd 200000 3000 5 0 0.982
% KDTREE_TIME: 412.948 41.774 454.722
% EGBDS_SW_TIME: 20.289 648.718 669.007
% EGBDS_HW_TIME: 29.148 58.201 87.349
% test_type test_file_name data_set_size query_size K split_precision truth_ratio
% [kdtree_time] kdtree_build_time kdtree_search_time kdtree_whole_time
% [sw_time] sw_build_time sw_search_time sw_whole_time
% [hw_time] hw_build_time hw_search_time hw_whole_time
%%
clc;
clear;

FileName='test.txt'; %文件名
[id,y,m,d,hh,mm,ss,d1,d2,d3,d4]=textread(FileName,'%d %d-%d-%d %d:%d:%d %d %d %d %d');  %读取文件中的数据
[data_set_size, query_size, K, gbds_build_time, gbds_search_time, kd_build_time, kd_search_time]=textread(FileName,'%d %d %d %d %d %d %d');  %读取文件中的数据