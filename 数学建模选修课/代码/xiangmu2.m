% 问题2：垂直游泳策略分析
D = 1160;       % 江宽 (m)
L = 1000;       % 终点偏移 (m)
v_water = 1.89; % 水流速度 (m/s)

% 计算最小所需速度
v_max = v_water * D / L;

% 生成不同速度的游泳者数据
v_speeds = linspace(1.0, 3.0, 20); % 从1.0到3.0m/s生成一个包含20个元素的等差数列，包含不同类型选手
drift_distances = v_water * D ./ v_speeds; %漂移距离 = 水流速度 × 渡江时间
success = drift_distances >= L; % 成功条件：漂移距离≥终点偏移
%success 是一个布尔数组，每个元素对应一个游泳速度是否能成功

% 可视化结果
figure('Position', [100, 100, 1000, 400])
subplot(1,2,1)
plot(v_speeds, drift_distances, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b')
hold on
plot([min(v_speeds), max(v_speeds)], [L, L], 'r--', 'LineWidth', 2)
plot(v_min, L, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r')
text(v_min+0.05, L+50, sprintf('临界点(%.2f m/s, %.0f m)', v_min, L), 'FontSize', 10)
xlabel('游泳速度 (m/s)')
ylabel('漂移距离 (m)')
title('垂直游泳漂移距离 vs 游泳速度')
legend('漂移距离', '终点要求', '临界速度', 'Location', 'best')
grid on

% 成功率对比分析
% 1934年数据：44人参加，40人成功
% 2002年数据：186人参加，34人成功
years = categorical({'1934年', '2002年'});
success_rates = [40/44*100, 34/186*100];
min_speeds = [0, v_min]; % 1934年无偏移要求，最小速度为0

subplot(1,2,2)
bar(years, success_rates, 'FaceColor', [0.5, 0.8, 0.2])
ylim([0 100])
ylabel('成功率 (%)')
title('不同年份成功率对比')
text(1, success_rates(1)+5, sprintf('%.1f%%', success_rates(1)), 'HorizontalAlignment', 'center')
text(2, success_rates(2)+5, sprintf('%.1f%%', success_rates(2)), 'HorizontalAlignment', 'center')
grid on

% 输出关键结论
fprintf('问题2关键结论:\n');
fprintf('1. 垂直游泳所需最大速度: %.2f m/s\n', v_max);
fprintf('2. 1934年成功率: %.1f%%, 原因: 终点在正对岸(无横向偏移要求)\n', success_rates(1));
fprintf('3. 2002年成功率: %.1f%%, 原因: 需克服%.0fm横向偏移\n', success_rates(2), L);
fprintf('4. 成功条件: 游泳速度 = %.2f m/s 或 调整游泳方向\n', v_min);
