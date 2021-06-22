% author: sun hao (matlab R2020a)
% 根据输入的N张带标定板的图片，计算其内参。并使用校正后的标定板内角点，在图片中找到标定板的四条边缘线。
% imageFileDir： 图片所在路径
% imageNames: 所有图片名称
% squareSize： 标定板格子的边长。单位时mm
% up_down_ratio: 标定板边缘与角点线的距离与角点线之间距离的比例。 比如纵目的标定板内角点数为 10*7.
% 角点线距离就是格子的边长，就是100mm。而最外层的角点到板子边缘的距离则为一个格子的距离加板子四周空白距离，为200mm.
clear;
clc;
clf;

imageFileDir = "C:\Users\10216\OneDrive\纵目实习\matlab 内参标定\correctedImage\";
imageNames = [      ...
    "0000.jpg","0001.jpg","0002.jpg","0003.jpg","0004.jpg","0005.jpg",  ...
    "0006.jpg","0007.jpg","0008.jpg","0009.jpg","0010.jpg","0011.jpg",  ...
    "0012.jpg","0013.jpg","0014.jpg","0015.jpg","0016.jpg","0017.jpg",             ...
    "0018.jpg","0019.jpg","0020.jpg","0021.jpg","0022.jpg","0023.jpg",  ...
    "0024.jpg"];
imageFileNames = imageFileDir+imageNames;

% Detect checkerboards in images 检测标定板上的所有角点。 无法检测出所有角点的图片会被剔除
[imagePoints, boardSize, imagesUsed] = detectCheckerboardPoints(imageFileNames);
imageFileNames = imageFileNames(imagesUsed);

% Read the first image to obtain image size
originalImage = imread(imageFileNames{1});
[mrows, ncols, ~] = size(originalImage);

% Generate world coordinates of the corners of the squares
squareSize = 100;  % in units of 'millimeters'  设置标定板格子的实际边长是多少
worldPoints = generateCheckerboardPoints(boardSize, squareSize);

% Calibrate the camera 至此，matlab标定部分完成。结果都存在了cameraParams中。
[cameraParams, imagesUsed, estimationErrors] = estimateCameraParameters(imagePoints, worldPoints, ...
    'EstimateSkew', false, 'EstimateTangentialDistortion', false, ...
    'NumRadialDistortionCoefficients', 2, 'WorldUnits', 'millimeters', ...
    'InitialIntrinsicMatrix', [], 'InitialRadialDistortion', [], ...
    'ImageSize', [mrows, ncols]);

%% 利用matlab函数标定的结果，计算标定板的四个角点并画出。
for image_index = 1:size(imageFileNames,2)
    % 纵目的标定板内角点数为 10*7.角点线距离就是格子的边长，就是100mm。
    % 而最外层的角点到板子边缘的距离则为一个格子的距离加板子四周空白距离，为200mm. 这里设置为210时由于鱼眼相机的畸变没有完全消除。
    up_down_ratio = 210/100;
    [y_up_down_lines] = findYLines(cameraParams, imageFileNames, image_index, up_down_ratio);
    [x_up_down_lines] = findXLines(cameraParams, imageFileNames, image_index, up_down_ratio);
    
    % 画出标定板x, y方向上下边界的线
    figure(50);
    imshow(imageFileNames{image_index}); 
    hold on;
    plot_x = [1, 640];
    plot_y = plot_x*y_up_down_lines(1,1) + y_up_down_lines(1,2);
    plot(plot_x,plot_y,'Color','g');
    plot_y = plot_x*y_up_down_lines(2,1) + y_up_down_lines(2,2);
    plot(plot_x,plot_y,'Color','g');
    plot_y = plot_x*x_up_down_lines(1,1) + x_up_down_lines(1,2);
    plot(plot_x,plot_y,'Color','b');
    plot_y = plot_x*x_up_down_lines(2,1) + x_up_down_lines(2,2);
    plot(plot_x,plot_y,'Color','b');
%     pause(0.5);

end

% 函数： 根据相机内参，找到某照片中y方向标定板角点连成的线。
function [y_up_down_lines] = findYLines(cameraParams, imageFileNames, image_index, up_down_ratio)
    % 计算y方向标定角点每条线的拟合系数
    % 先提取所有的线，以及对应的角点
    y_lines_index = 0;
    temp_index = 1;
    for i = 1:70
        if(mod(i,7)==1)
            y_lines_index = y_lines_index + 1;
            temp_index = 1;
        end
        y_lines_points(y_lines_index, temp_index, 1) = cameraParams.ReprojectedPoints(i, 1, image_index);
        y_lines_points(y_lines_index, temp_index, 2) = cameraParams.ReprojectedPoints(i, 2, image_index);
        temp_index = temp_index + 1;
    end
    % 用最小二乘对这些点进行直线拟合
    % 计算与y轴平行方向的特征点连成的直线的系数。
    for i = 1:size(y_lines_points,1)
        temp_x = y_lines_points(i, :, 1);
        temp_y = y_lines_points(i, :, 2);
        p=polyfit(temp_x,temp_y,1); % 用一次函数拟合此直线
        y_lines_coeff(i,1) = p(1);
        y_lines_coeff(i,2) = p(2);
    end
    % 由于纵目的照片时鱼眼相机矫正过来的，可能矫正的不是很好。经过评估发现这些线的参数符合一个二次函数分布
    % 计算直线参数的拟合系数
    y_lines_coeffx = 1:size(y_lines_coeff,1);   % 直接以 1：n 作为x
    y_lines_coeff_k = y_lines_coeff(:,1);
    y_lines_coeff_b = y_lines_coeff(:,2);
    y_k_p=polyfit(y_lines_coeffx,y_lines_coeff_k,2);    % 进行二次函数拟合。
    y_b_p=polyfit(y_lines_coeffx,y_lines_coeff_b,2);    % 进行二次函数拟合。
% 画出 b 参数的分布; k 参数同理
% figure(102);
% hold on;
% plot(y_lines_coeffx, y_lines_coeff_b,'k.');
% plot_x = y_lines_coeffx;
% plot_y = y_b_p(1)*plot_x.^2 + y_b_p(2)*plot_x + y_b_p(3);
% plot(plot_x,plot_y,'Color','r');
% hold off;    
    % 根据拟合的参数，以及实际标定板上的比例，求出标定板y方向上下两条线的参数
    ratio_y_up_to_chess = up_down_ratio;
    y_up_coeffx = 1 - ratio_y_up_to_chess;
    y_down_coeffx = size(y_lines_coeff,1) + ratio_y_up_to_chess;    % 上下比例也可以不一样。这里是一样的，
    y_up_b = y_b_p(1)*y_up_coeffx.^2 + y_b_p(2)*y_up_coeffx + y_b_p(3);
    y_up_k = y_k_p(1)*y_up_coeffx.^2 + y_k_p(2)*y_up_coeffx + y_k_p(3);
    y_down_b = y_b_p(1)*y_down_coeffx.^2 + y_b_p(2)*y_down_coeffx + y_b_p(3);
    y_down_k = y_k_p(1)*y_down_coeffx.^2 + y_k_p(2)*y_down_coeffx + y_k_p(3);
    
    y_up_down_lines(1,1) = y_up_k;
    y_up_down_lines(1,2) = y_up_b;
    y_up_down_lines(2,1) = y_down_k;
    y_up_down_lines(2,2) = y_down_b;
    
    % 画出标定板y方向上下边界的线
%     figure(105);
%     imshow(imageFileNames{image_index}); 
%     hold on;
%     plot_x = [1, 640];
%     plot_y = plot_x*y_up_k + y_up_b;
%     plot(plot_x,plot_y,'Color','g');
%     plot_y = plot_x*y_down_k + y_down_b;
%     plot(plot_x,plot_y,'Color','b');
%     pause(0.5);
end

% 函数： 根据相机内参，找到某照片中x方向标定板角点连成的线。
function [x_up_down_lines] = findXLines(cameraParams, imageFileNames, image_index, up_down_ratio)
        % 计算x方向标定角点每条线的拟合系数
    % 先提取所有的线，以及对应的角点
    x_lines_index = 0;
    temp_index = 1;
    for i = 1:70    
        x_lines_index = mod(i,7);
        if (x_lines_index == 0) 
            x_lines_index = 7;
        end
        temp_index = ceil(i/7);
        x_lines_points(x_lines_index, temp_index, 1) = cameraParams.ReprojectedPoints(i, 1, image_index);
        x_lines_points(x_lines_index, temp_index, 2) = cameraParams.ReprojectedPoints(i, 2, image_index);
    end
    % 用最小二乘对这些点进行直线拟合
    % 计算与y轴平行方向的特征点连成的直线的系数。
    for i = 1:size(x_lines_points,1)
        temp_x = x_lines_points(i, :, 1);
        temp_y = x_lines_points(i, :, 2);
        p=polyfit(temp_x,temp_y,1);     % 进行一次函数拟合。
        x_lines_coeff(i,1) = p(1);
        x_lines_coeff(i,2) = p(2);
    end
    % 由于纵目的照片时鱼眼相机矫正过来的，可能矫正的不是很好。经过评估发现这些线的参数符合一个二次函数分布
    % 计算直线参数的拟合系数
    x_lines_coeffx = 1:size(x_lines_coeff,1);   % 直接以 1：n 作为x
    x_lines_coeff_k = x_lines_coeff(:,1);
    x_lines_coeff_b = x_lines_coeff(:,2);
    x_k_p=polyfit(x_lines_coeffx,x_lines_coeff_k,2);    % 进行二次函数拟合。
    x_b_p=polyfit(x_lines_coeffx,x_lines_coeff_b,2);    % 进行二次函数拟合。
% 画出 b 参数的分布
% figure(103);
% hold on;
% plot(x_lines_coeffx, x_lines_coeff_b,'k.');
% plot_x = x_lines_coeffx;
% plot_y = x_b_p(1)*plot_x.^2 + x_b_p(2)*plot_x + x_b_p(3);
% plot(plot_x,plot_y,'Color','r');
% hold off;  
    % 根据拟合的参数，以及实际标定板上的比例，求出标定板x方向上下两条线的参数
    ratio_x_up_to_chess = up_down_ratio;
    x_up_coeffx = 1 - ratio_x_up_to_chess;
    x_down_coeffx = size(x_lines_coeff,1) + ratio_x_up_to_chess;    % 上下比例也可以不一样。这里是一样的，
    x_up_b = x_b_p(1)*x_up_coeffx.^2 + x_b_p(2)*x_up_coeffx + x_b_p(3);
    x_up_k = x_k_p(1)*x_up_coeffx.^2 + x_k_p(2)*x_up_coeffx + x_k_p(3);
    x_down_b = x_b_p(1)*x_down_coeffx.^2 + x_b_p(2)*x_down_coeffx + x_b_p(3);
    x_down_k = x_k_p(1)*x_down_coeffx.^2 + x_k_p(2)*x_down_coeffx + x_k_p(3);
    
    x_up_down_lines(1,1) = x_up_k;
    x_up_down_lines(1,2) = x_up_b;
    x_up_down_lines(2,1) = x_down_k;
    x_up_down_lines(2,2) = x_down_b;
    
    % 画出标定板x方向上下边界的线
%     figure(105);
%     imshow(imageFileNames{image_index}); 
%     hold on;
%     plot_x = [1, 640];
%     plot_y = plot_x*x_up_k + x_up_b;
%     plot(plot_x,plot_y,'Color','g');
%     plot_y = plot_x*x_down_k + x_down_b;
%     plot(plot_x,plot_y,'Color','b');
%     pause(0.5);
end

