% 参数设置
D = 1160;       % 江宽 (m)
L = 1000;       % 终点偏移 (m)
v_water = 1.89; % 水流速度 (m/s)
t_winner = 14*60 + 8; % 冠军成绩 (s)

% 冠军速度计算
syms v theta %创建两个符号变量
eq1 = v*cos(theta)*t_winner == D;
eq2 = (v*sin(theta) + v_water)*t_winner == L;
sol = solve([eq1, eq2], [v, theta]);
v_winner = double(sol.v(1));  % 取实数解
theta_winner = double(sol.theta(1));

% 1.5m/s游泳者方向选择
v_swimmer = 1.5;
syms t
eq3 = v_swimmer*cos(theta)*t == D;
eq4 = (v_swimmer*sin(theta) + v_water)*t == L;
sol2 = solve([eq3, eq4], [theta, t]);
theta_swimmer = double(sol2.theta(1));
t_swimmer = double(sol2.t(1));

% 结果输出
fprintf('冠军结果:\n速度: %.3f m/s, 角度: %.1f°\n', v_winner, rad2deg(theta_winner));
fprintf('1.5m/s游泳者:\n方向: %.1f°, 成绩: %.1f 秒 (%.1f 分钟)\n', ...
        rad2deg(theta_swimmer), t_swimmer, t_swimmer/60);

% 可视化
figure% 创建新图形窗口
% 冠军路线（红色实线）
fplot(@(t) (v_winner*sin(theta_winner) + v_water)*t, ...
      @(t) v_winner*cos(theta_winner)*t, [0 t_winner], 'r-', 'LineWidth', 2)
hold on
% 1.5m/s选手路线（蓝色虚线）
fplot(@(t) (v_swimmer*sin(theta_swimmer) + v_water)*t, ...
      @(t) v_swimmer*cos(theta_swimmer)*t, [0 t_swimmer], 'b--', 'LineWidth', 2)
plot(L, D, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r')
xlabel('下游距离 (m)'), ylabel('横渡距离 (m)')
title('抢渡长江路线对比')
legend('冠军路线', '1.5m/s选手路线', '终点位置', 'Location', 'best')
grid on, axis equal