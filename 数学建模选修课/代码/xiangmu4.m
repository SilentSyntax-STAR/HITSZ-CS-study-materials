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

% 初始角度猜测（基于分段模型结果）
theta0 = deg2rad(-30); % 初始角度估计值

% 优化求解最佳角度
options = optimoptions('fmincon', 'Display', 'iter', ...
                      'Algorithm', 'sqp', 'MaxFunctionEvaluations', 1000);

% 调用优化函数
theta_opt = fmincon(@(theta) time_to_cross_continuous(D, v_swimmer, v_water_continuous, theta), ...
                    theta0, [], [], [], [], -pi/2, pi/2, ...
                    @(theta) end_constraint_continuous(D, L, v_swimmer, v_water_continuous, theta), ...
                    options);

% 计算最优路径和成绩
[t_opt, y_path, x_path] = simulate_path_continuous(D, v_swimmer, v_water_continuous, theta_opt);

% 找到到达对岸的时间点
arrival_idx = find(y_path >= D, 1);
if isempty(arrival_idx)
    arrival_idx = length(t_opt);
end
arrival_time = t_opt(arrival_idx);
final_x = x_path(arrival_idx);

% 结果输出
fprintf('\n连续流速分布优化结果:\n');
fprintf('最优角度: %.1f° (向上游偏航)\n', rad2deg(theta_opt));
fprintf('渡江时间: %.1f 秒 (%.1f 分钟)\n', arrival_time, arrival_time/60);
fprintf('到达位置: 下游 %.1f 米 (目标: %.1f 米)\n', final_x, L);
fprintf('水平偏差: %.1f 米\n', final_x - L);

plot(x_path, y_path, 'LineWidth', 2)
hold on
plot(L, D, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r')
plot([0, max(x_path)], [D, D], 'g--') % 对岸线

% 标记关键点
plot(x_path(1), y_path(1), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g') % 起点
plot(x_path(arrival_idx), y_path(arrival_idx), 'mo', 'MarkerSize', 10) % 到达点
text(x_path(arrival_idx)+20, y_path(arrival_idx), sprintf('到达点 (%.0fm)', final_x))

xlabel('下游距离 (m)'), ylabel('横渡距离 (m)')
title(sprintf('最优游泳路径 (角度: %.1f°)', rad2deg(theta_opt)))
legend('游泳路径', '目标终点', '对岸线', '起点', '实际到达点', 'Location', 'best')
grid on
axis equal

% 添加流速分布标注
annotation('textbox', [0.15, 0.7, 0.3, 0.1], 'String', ...
           sprintf('流速分布:\n近岸: 0-1.47m/s\n中流: 2.11m/s\n远岸: 1.47-0m/s'), ...
           'FitBoxToText', 'on', 'BackgroundColor', 'white')

% 辅助函数：计算渡江时间
function t_cross = time_to_cross_continuous(D, v_swimmer, v_water, theta)
    % 设置ODE选项，当y>=D时停止积分
    options = odeset('Events', @(t,y) event_terminate(t,y,D));
    
    % 求解ODE
    [t, y] = ode45(@(t,y) v_swimmer*cos(theta), [0 10000], 0, options);
    
    % 返回渡江时间
    t_cross = t(end);
end

% 辅助函数：终点约束
function [c, ceq] = end_constraint_continuous(D, L, v_swimmer, v_water, theta)
    % 设置ODE选项
    options = odeset('Events', @(t,y) event_terminate(t,y,D));
    
    % 求解位置
    [t, y] = ode45(@(t,y) v_swimmer*cos(theta), [0 10000], 0, options);
    x = cumtrapz(t, v_swimmer*sin(theta) + arrayfun(v_water, y));
    
    % 终点约束：到达对岸时x位置=L
    ceq = x(end) - L;
    c = []; % 无不等式约束
end

% 事件函数：当y>=D时终止积分
function [value, isterminal, direction] = event_terminate(t, y, D)
    value = D - y;     % 当y=D时值为0
    isterminal = 1;    % 触发时停止积分
    direction = -1;    % 从正方向穿过零点
end

% 辅助函数：模拟完整路径
function [t, y, x] = simulate_path_continuous(D, v_swimmer, v_water, theta)
    % 设置ODE选项
    options = odeset('Events', @(t,y) event_terminate(t,y,D), 'MaxStep', 1);
    
    % 求解位置
    [t, y] = ode45(@(t,y) v_swimmer*cos(theta), [0 10000], 0, options);
    
    % 计算x位置
    x = zeros(size(y));
    for i = 2:length(t)
        dt = t(i) - t(i-1);
        v_water_i = v_water(y(i));
        dx = (v_swimmer*sin(theta) + v_water_i) * dt;
        x(i) = x(i-1) + dx;
    end
end