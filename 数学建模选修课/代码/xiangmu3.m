% 参数设置
v_swimmer = 1.5; % 游泳速度 (m/s)
D = 1160;         % 江宽 (m)
L = 1000;         % 终点偏移 (m)

% 分段流速定义
v_water = @(y) ...
    (y <= 200) * 1.47 + ...
    (y > 200 & y < 960) * 2.11 + ...
    (y >= 960) * 1.47;

% 优化选项设置
options = optimoptions('fmincon', ...
    'Display', 'iter', ...
    'Algorithm', 'sqp', ...
    'MaxFunctionEvaluations', 3000, ...
    'MaxIterations', 1000, ...
    'StepTolerance', 1e-4, ...
    'ConstraintTolerance', 1, ... % 放宽约束容差（1米）
    'OptimalityTolerance', 1e-3);

% 初始猜测（基于物理直觉）
theta0 = deg2rad(-35); 

% 优化求解
[theta_opt, ~, exitflag] = fmincon(@(theta) time_to_cross(D, v_swimmer, v_water, theta), ...
                    theta0, [], [], [], [], -pi/2, pi/2, ...
                    @(theta) end_constraint(D, L, v_swimmer, v_water, theta), ...
                    options);

% 计算成绩和路径
[t, y, x, x_arrival] = simulate_path(D, L, v_swimmer, v_water, theta_opt);
t_opt = t(end);

% 结果输出
fprintf('优化状态: %d (1=收敛, 2=步长小, 3=函数变化小)\n', exitflag);
fprintf('最优角度: %.1f°\n', rad2deg(theta_opt))
fprintf('估计成绩: %.1f 秒 (%.1f 分钟)\n', t_opt, t_opt/60)
fprintf('到达点位置: x=%.1fm (目标: %.0fm)\n', x_arrival, L);
fprintf('位置误差: %.1fm (%.2f%%)\n', abs(x_arrival-L), 100*abs(x_arrival-L)/L);

% 绘制路线
figure
plot(x, y, 'LineWidth', 2)
hold on
plot(L, D, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r')
plot([0, max(x)], [D, D], 'k--') % 对岸线
plot([L, L], [0, D], 'b--') % 终点线
xlabel('下游距离 (m)'), ylabel('横渡距离 (m)')
title(sprintf('分段流速下最优路线 (角度: %.1f°)', rad2deg(theta_opt)))
grid on, axis equal

% 标记关键点
plot(0, 0, 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g') % 起点
plot(x_arrival, D, 'mo', 'MarkerSize', 10, 'MarkerFaceColor', 'm') % 到达点
text(x_arrival+20, D, sprintf('到达点 (%.0fm)', x_arrival), 'FontSize', 10)
legend('游泳路径', '目标终点', '对岸线', '终点线', '起点', '实际到达点', 'Location', 'best')

% 添加流速分布
text(500, 100, sprintf('流速分布:\n0-200m: 1.47m/s\n200-960m: 2.11m/s\n960-1160m: 1.47m/s'), ...
     'BackgroundColor', 'white', 'FontSize', 10)

% --- 辅助函数 ---
function t = time_to_cross(D, v_swimmer, v_water, theta)
    [t_sim, y_sim] = swim_ode_solver(D, v_swimmer, v_water, theta);
    t = t_sim(end);
end

function [c, ceq] = end_constraint(D, L, v_swimmer, v_water, theta)
    [~, ~, x_arrival] = swim_ode_solver(D, v_swimmer, v_water, theta);
    ceq = x_arrival - L; % 约束条件
    c = [];
end

function [t, y, x, x_arrival] = simulate_path(D, L, v_swimmer, v_water, theta)
    [t, y_sim, x_arrival] = swim_ode_solver(D, v_swimmer, v_water, theta);
    y = y_sim(:,1); % 横渡距离
    x = y_sim(:,2); % 下游距离
end

function [t_sim, y_sim, x_arrival] = swim_ode_solver(D, v_swimmer, v_water, theta)
    % 设置事件函数：当y>=D时精确停止
    options = odeset('Events', @(t,y) event_terminate(t,y,D), ...
                    'RelTol', 1e-8, 'AbsTol', 1e-8);
    
    % 求解ODE
    [t_sim, y_sim] = ode45(@(t, y) swim_ode(t, y, v_swimmer, v_water, theta), ...
                          [0 2000], [0; 0], options);
    
    % 精确计算到达对岸时的x位置
    if ~isempty(t_sim)
        % 插值得到精确的y=D时的x位置
        x_arrival = interp1(y_sim(:,1), y_sim(:,2), D, 'pchip');
    else
        x_arrival = NaN;
    end
end

function dydt = swim_ode(~, y, v_swim, v_water, theta)
    dydt = zeros(2,1);
    dydt(1) = v_swim * cos(theta); % dy/dt (垂直方向)
    dydt(2) = v_swim * sin(theta) + v_water(y(1)); % dx/dt (水平方向)
end

function [value, isterminal, direction] = event_terminate(t, y, D)
    value = y(1) - D;  % 当y(1) >= D时触发
    isterminal = 1;    % 停止积分
    direction = 1;     % 正向穿过零点
end
