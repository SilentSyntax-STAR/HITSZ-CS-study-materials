% 参数设置
v_swimmer = 1.5;   % 游泳速度 (m/s)
D = 1160;           % 江宽 (m)
L = 1000;           % 终点偏移 (m)

% 定义连续流速分布函数（给定函数）
v_water_continuous = @(y) ...
    (y <= 200) .* (2.28/200 * y) + ...        % 近岸区域：线性增加
    (y > 200 & y < 960) .* 2.28 + ...         % 中心区域：恒定高速
    (y >= 960) .* (2.28/200 .* (1160 - y));  % 远岸区域：线性减小

% 可视化结果
figure('Position', [100, 100, 1200, 500])%设置图形窗口的位置和大小
%流速分布
y_values = linspace(0, D, 100);
v_values = arrayfun(v_water_continuous, y_values);
plot(v_values, y_values, 'b', 'LineWidth', 2)
xlabel('流速 (m/s)'), ylabel('离岸距离 (m)')
title('长江流速分布 (连续模型)')
grid on
set(gca, 'YDir', 'reverse') % 起点在顶部