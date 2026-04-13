clc;
clear all；
tic

rng(2);  % 设置Z随机种子

% 初始化参数

I = 8;  % 排队网络节点总数
J = 8;  % 排队网络节点总数(辅助矩阵)
E = [1, 2]; % 预约就诊方式集合，其中 1代表线下，2代表线上
S = [1, 2]; % 医疗资源集合，其中1代表优质医疗资源，2代表普通医疗资源
t = [1, 2]; % 患者集合，其中1代表慢性疾病患者，2代表普通疾病患者
global Q;
Q = [1, 2]; % 患者优先级集合，其中1代表转诊患者，2代表非转诊患者
global C1;
C1 = 60; % 线下系统容量限制
global C2;
C2 = 30; % 线上系统容量限制

% roui 服务强度(1*8) roui = lamdai/(y*miui) 到达率/（医联资源*服务率）

global miui;

% miui 服务率
miui = [7,4,5,1,6.5,3,5,1.2]; % 节点i的单个服务台的服务率
% miui = [8,4.5,6,1.5,8,5,4,0.8];

r0it1n = [0.3,0.4;0.4,0.3]; % 第n周t类患者外部到达节点i的概率(线下)[i=1，i=2；i=1，i=2] [基层慢性，上级慢性；基普，上普]
r0it2n = [0.1,0.2;0.2,0.1]; % 第n周t类患者外部到达节点i的概率(线上)[i=5，i=6；i=5，i=6]

phit1n = [50,50;100,100]; % e=1,线下，2x2矩阵表示患者到达率，t=1、2，[慢性；普通]
phit2n = [50,50;100,100]; % e=2,线上 [慢性；普通]

% lamdai 到达率
% lamdai1n = [10,34,7,28,7,17,3,8]; % 慢性患者 lamdaitn(i=1~8)
% lamdai2n = [24,24,20,18,24,24,15,18]; % 普通患者
% lamdajtn=[lamdai1n,lamdai2n]; % 前期计算使用，数据取值一样


% 转移率读取
rij11n = xlsread('trans_rate1_xianx.xls');   % 慢性线下转移率数据
rij21n = xlsread('trans_rate2_xianx.xls');   % 普通线下转移率数据
rij12n = xlsread('trans_rate1_xians.xls');   % 慢性线上转移率数据
rij22n = xlsread('trans_rate2_xians.xls');   % 普通线上转移率数据
rij1_12n = xlsread('trans_rate1_xians_xianx.xls');  % 慢性线上-线下转移率数据；包含慢性约束
rij2_12n = xlsread('trans_rate2_xians_xianx.xls'); % 普通线上-线下转移率数据

    
% Cis1 Cis0
c_i_1_1 = [480,480,720,720,300,300,500,500] ; % 节点i,s=1优质资源在繁忙状态下单位时间的成本
c_i_2_1 = [240,240,360,360,100,100,200,200] ; % 节点i,s=2普通资源在繁忙状态下单位时间的成本
global c_i_s_1;
c_i_s_1 = [c_i_1_1;c_i_2_1];
c_i_1_0 = [400,400,600,600,200,200,400,400] ; % 节点i,s=1优质资源在空闲状态下单位时间的成本
c_i_2_0 = [200,200,300,300,80,80,150,150] ; % 节点i,s=2普通资源在空闲状态下单位时间的成本
global c_i_s_0;
c_i_s_0 = [c_i_1_0;c_i_2_0];

% 扰动比例
yibuselong = 0.005;
% 扰动量
global a_i_s_1;
a_i_s_1 = yibuselong*c_i_s_1; 
global a_i_s_0;
a_i_s_0 = yibuselong*c_i_s_0;

%% 不确定参数 0-16（0-6）3
global tao0 tao1;
tao0 = 0.5;
tao1 = 0.5;

% Ct CT' 线上，线下t类患者单位时间等待成本, Cf转诊成本
global c_1 c_2 c_t c1_ c2_ c_t_ cf;

% 等待成本参数
c_1 = 200;  % t=1,慢性患者单位时间等待成本，元/小时,线下
c_2 = 400;  % t=2,普通患者单位时间等待成本，元/小时,线下
c_t = [c_1,c_2]; % 线下
c1_ = 100;  % t=1,慢性患者单位时间等待成本，元/小时,线上
c2_ = 200;  % t=2,普通患者单位时间等待成本，元/小时,线上
c_t_ = [c1_,c2_]; % 线上

% 转诊成本参数
cf = 300;  %元/人

% part2 
    
    % gammaiten 外部到达率
   
    % 节点1处慢性 线下
    gamma111n = r0it1n(1,1) * phit1n(1,1);
    % 节点1处普通
    gamma121n = r0it1n(2,1) * phit1n(2,1);
    % 节点2处慢性
    gamma211n = r0it1n(1,2) * phit1n(1,2);
    % 节点2处普通
    gamma221n = r0it1n(2,2) * phit1n(2,2);
    % 节点5处慢性 线上
    gamma512n = r0it2n(1,1) * phit2n(1,1);
    % 节点5处普通
    gamma522n = r0it2n(2,1) * phit2n(2,1);
    % 节点6处慢性
    gamma612n = r0it2n(1,2) * phit2n(1,2);
    % 节点6处普通
    gamma622n = r0it2n(2,2) * phit2n(2,2);
    
    % 节点1处外部总到达率——无用  gammain
    gamma1n = gamma111n + gamma121n;
    % 节点2处外部总到达率
    gamma2n = gamma211n + gamma221n;
    % 节点5处外部总到达率
    gamma5n = gamma512n + gamma522n;
    % 节点6处外部总到达率
    gamma6n = gamma612n + gamma622n;

    
   
    global lamda1_1_n lamda1_1_1_n lamda1_2_1_n lamda5_2_n lamda5_1_2_n lamda5_2_2_n lamda6_2_n lamda6_1_2_n lamda6_2_2_n...
        lamda7_2_n lamda7_1_2_n lamda7_2_2_n lamda8_2_n lamda8_1_2_n lamda8_2_2_n...
       lamda2_111n lamda2_121n lamda2_211n lamda2_221n lamda3_111n lamda3_121n lamda3_211n lamda3_221n lamda4_111n lamda4_211n lamda4_221n...
       elta_21n elta_22n elta_31n elta_32n elta_41n elta_42n;
    
    % 节点i的 t类（非转诊）患者到达率lamdai_t_e_n；线上线下之间已考虑
   
    % 节点1
    lamda1_1_1_n = gamma111n;
    lamda1_2_1_n = gamma121n;
    % 节点5
    lamda5_1_2_n = gamma512n;
    lamda5_2_2_n = gamma522n;
    % 节点6
    lamda6_1_2_n = gamma612n;
    lamda6_2_2_n = gamma622n;
    % 节点7
    lamda7_1_2_n = gamma512n*rij12n(5,7);
    lamda7_2_2_n = gamma522n*rij22n(5,7);
    % 节点8
    lamda8_1_2_n = gamma612n*rij12n(6,8);
    lamda8_2_2_n = gamma622n*rij22n(6,8);
    
    
    % 节点i的(t=1、t=2之和)非转诊患者到达率  lamdai_e_n
    
    % 节点1 （只有外部到达率）
    lamda1_1_n = lamda1_1_1_n + lamda1_2_1_n;
    % 节点5  （只有外部到达率）
    lamda5_2_n = lamda5_1_2_n + lamda5_2_2_n;
    % 节点6  （只有外部到达率）
    lamda6_2_n = lamda6_1_2_n + lamda6_2_2_n;
    % 节点7
    lamda7_2_n = lamda7_1_2_n + lamda7_2_2_n;
    % 节点8
    lamda8_2_n = lamda8_1_2_n + lamda8_2_2_n;

    % 节点i（i=2）q=1，有优先级的t类患者到达率；lamdai_qten，与非转诊的相加，就是i节点的所有患者到达率
    lamda2_111n = lamda1_1_1_n*rij11n(1,2)*0.2;
    lamda2_121n = lamda1_2_1_n*rij21n(1,2)*0.2;
    elta_21n = lamda2_111n + lamda2_121n;  % elta_iqn

    % 节点i（i=2）q=2，无优先级的t类患者到达率;
    lamda2_211n = gamma211n;
    lamda2_221n = gamma221n;
    elta_22n = lamda2_211n + lamda2_221n; 

    % 节点i（i=3）q=1，有优先级的t类患者到达率；
    lamda3_111n = (lamda2_111n+lamda2_211n)*rij11n(2,3) + lamda7_1_2_n*rij1_12n(7,3);
    lamda3_121n = (lamda2_121n+lamda2_221n)*rij21n(2,3);
    elta_31n = lamda3_111n + lamda3_121n;

    % 节点3，q=2，无优先级的t类患者到达率;
    lamda3_211n = lamda1_1_1_n*rij11n(1,3);
    lamda3_221n = lamda1_2_1_n*rij21n(1,3);
    elta_32n = lamda3_211n + lamda3_221n;

    % 节点i（i=4）q=1，有优先级的t类患者到达率
    lamda4_111n = lamda8_1_2_n*rij1_12n(8,4);
    % lamda4_121n = lamda6_2_2_n*rij2_12n(6,4);
    elta_41n = lamda4_111n;
    
     % 节点4，q=2，无优先级的t类患者到达率;
    lamda4_211n = (lamda2_111n+lamda2_211n)*rij11n(2,4);
    lamda4_221n = (lamda2_121n+lamda2_221n)*rij21n(2,4);
    elta_42n = lamda4_211n + lamda4_221n;

lamdai = [lamda1_1_n,0,0,0,lamda5_2_n,lamda6_2_n,lamda7_2_n,lamda8_2_n];
% lamda_iq = [elta_2qn,elta_3qn,elta_4qn];  % elta做λ_itn，用于转诊L排队长度公式，求ρ_ien

% 约束
    
    % 整数约束: x1 和 x2 必须是整数 
    tic; 
    % 通过非线性约束实现整数约束
    
    % x0 = [2,18,2,58,2,8,2,18,...
    %       18,0,13,0,8,0,5,0];
    % 初始点
    % x0 = [2,18,1,59,4,8,0,18,...
    %       9,0,13,0,4,0,5,0]; 
    x01 = [10,13,10,50,6,8,5,18,...
          18,0,13,0,8,0,5,0];  % 最优初始值
    % x0 = [15,2,13,50,6,9,5,10,...
    %       18,0,15,0,8,0,7,0];
    x02 = ones(34,1);
    x0 = [x01, x02'];
    
    % 从.mat文件导入x_global数据并赋值给x0

    % load('matlab_long_raodong_0.005_tao_0_yuanshi.mat', 'x_global');
    % x0 = x_global;

    % objectiveFunction_play1(x0)
    % objectiveFunction_play(x_global)
    % max1 = 3*(18+13+8+5);
    % max2 = 3*(10+10+13+50+6+5+8+18);
     % 不等式约束
    sigma = 0.3;   % 长期约束↓ (x0必须满足sigma，所以应减小)
    A = [sigma-1,0,0,0,0,0,0,0,sigma,0,0,0,0,0,0,0;
        0,0,sigma-1,0,0,0,0,0,0,0,sigma,0,0,0,0,0;
        0,0,0,0,sigma-1,0,0,0,0,0,0,0,sigma,0,0,0;
        0,0,0,0,0,0,sigma-1,0,0,0,0,0,0,0,sigma,0;
        1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0;
        0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0;
        0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0;
        0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0;
        0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0;
        0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0;
        0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0;
        0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1;
        ];
    A = [A, zeros(12, 34)];
    b = [0;
        0;
        0;
        0;
        C1-1;
        C1-1;
        C1-1;
        C1-1;
        C2-1;
        C2-1;
        C2-1;
        C2-1;
        ];


    % 等式约束
    % Aeq = [];
    % 
    % beq = [];
    Aeq = [0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0;
        0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0;
        0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0;
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1];
    Aeq = [Aeq, zeros(4, 34)];
    beq = [0;
            0;
            0;
            0;];
    
    lb1 = zeros(16,1)-0.5 ; % 初始化为0的16x1向量2
    lb2 = zeros(34,1); % 不确定自变量下边界
    lb = [lb1; lb2];
    
    % x0 = [2,18,2,58,2,8,2,18,...
    %       18,2,13,2,8,2,5,2];
    % ub = [20,10,20,60,20,20,20,20,...
    %       20,0,20,0,10,0,10,0];
    ub1 = [80,80,80,80,80,80,80,80,...
         80,0,80,0,80,0,80,0]+0.5 ;
    ub2 = Inf(34,1); % 不确定自变量上边界
    ub = [ub1, ub2'];

    % options = optimoptions('fmincon', ...
    %     'EnableFeasibilityMode', true, ...
    %     'MaxFunctionEvaluations', 10000, ...  % 增加函数计算次数
    %     'MaxIterations', 5000, ...            % 增加迭代次数
    %     'Algorithm', 'interior-point', ...  % 选择算法（如内点法）
    %     'Display', 'iter');       
    % [x_global, fval] = fmincon(@objectiveFunction, x0, A, b, Aeq, beq, lb, ub, @nonlcon, options);
    % fmincon_elapsed_time = toc;

    % 配置fmincon优化问题

    problem = createOptimProblem('fmincon', ...
        'objective', @objectiveFunction, ...
        'x0', x0, ...
        'Aineq', A, ...
        'bineq', b, ...
        'Aeq', Aeq, ...
        'beq', beq, ...
        'lb', lb, ...
        'ub', ub, ...
        'nonlcon', @nonlcon);

    gs = GlobalSearch('NumTrialPoints', 150000, 'NumStageOnePoints', 1000);   
    % gs = GlobalSearch('NumTrialPoints', 1000, 'NumStageOnePoints', 200); 
    [x_global, fval] = run(gs, problem);
    fmincon_elapsed_time = toc;

    % 输出结果  
    disp('最优解:');                                               
    disp(x_global);  
    disp('目标函数值:');  
    disp(fval);
    disp(['fmincon 求解时间: ', num2str(fmincon_elapsed_time/60/60), ' 小时']);

 % x_global = [27,18,5,37,28,8,7,27,...
 %          19,0,20,0,8,0,8,0];
 result = objectiveFunction_play(x_global);
 
% 目标函数
function f_d = objectiveFunction(x) 
    global c_t c_t_ cf;
    %  自变量
    yi1 = [x(1),x(2),x(3),x(4),x(5),x(6),x(7),x(8)];
    yi2 = [x(9),x(10),x(11),x(12),x(13),x(14),x(15),x(16)];
    zetai10 = [x(17),x(18),x(19),x(20),x(21),x(22),x(23),x(24)];
    zetai20 = [x(25),x(26),x(27),x(28),x(29),x(30),x(31),x(32)];
    theta0 = x(33);
    zetai11 = [x(34),x(35),x(36),x(37),x(38),x(39),x(40),x(41)];
    zetai21 = [x(42),x(43),x(44),x(45),x(46),x(47),x(48),x(49)];
    theta1 = x(50);

    yis = [yi1; yi2];
    zetas0 = [zetai10; zetai20];
    zetas1 = [zetai11; zetai21];
    thetas = [theta0; theta1];  

    global y1 y2 y3 y4 y5 y6 y7 y8;
    global lamda1_1_n;
    global lamda5_2_n;
    global lamda6_2_n;
    global lamda7_2_n;
    global lamda8_2_n;
    global miui L1n L5n L6n L7n L8n l_11n l_12n l_51n l_52n l_61n l_62n l_71n l_72n l_81n l_82n;
    global C1;
    C1 = 60; % 线下系统容量限制
    global C2;
    C2 = 30; % 线上系统容量限制
   
    % 节点1

    % 服务强度 service_strength_ien= arrive_rate / (c * service_rate);
    y1 = yi1(1) + yi2(1);
    rou_11n = lamda1_1_n / (y1 * miui(1));
    result1 = 0; % 初始化求和结果
    for d = 0:y1
        result1 = result1 + (y1 * rou_11n)^d / gamma(y1);
    end 
    % disp(result1);
    
    L1n = ((rou_11n*(rou_11n*y1)^y1)*(1-rou_11n^(C1-y1)-(C1-y1)*rou_11n^(C1-y1)*(1-rou_11n)))...
        /(gamma(y1)*((1-rou_11n)^2)*(result1+y1^y1*rou_11n*(rou_11n^y1-rou_11n^C1)/(gamma(y1)*(1-rou_11n))));
    % t类(t=1)患者预期排队长度
    global lamda1_1_1_n;
    l_11n = (lamda1_1_1_n*L1n)/lamda1_1_n;
    % t类(t=2)患者预期排队长度s
    global lamda1_2_1_n;
    l_12n = (lamda1_2_1_n*L1n)/lamda1_1_n;
    
    
    % 节点5

    % 服务强度 service_strength_ien= arrive_rate / (c * service_rate);
    y5 = yi1(5) + yi2(5);
    rou_52n = lamda5_2_n / (y5 * miui(5));
    
    % 节点5排队长度
    % L_q = ((c * service_strength)^c * service_strength * P_0) / (gamma(c) * (1 - service_strength)^2);
    result5 = 0; % 初始化求和结果
    for d2 = 0:y5
        result5 = result5 + (y5 * rou_52n)^d2 / gamma(y5);
    end
    % disp(result5);
    
    L5n = ((rou_52n*(rou_52n*y5)^y5)*(1-rou_52n^(C2-y5)-(C2-y5)*rou_52n^(C2-y5)*(1-rou_52n)))...
        /(gamma(y5)*((1-rou_52n)^2)*(result5+y5^y5*rou_52n*(rou_52n^y5-rou_52n^C2)/(gamma(y5)*(1-rou_52n))));
    % t类(t=1)患者预期排队长度
    global lamda5_1_2_n;
    l_51n = (lamda5_1_2_n*L5n)/lamda5_2_n;
    % t类(t=2)患者预期排队长度
    global lamda5_2_2_n;
    l_52n = (lamda5_2_2_n*L5n)/lamda5_2_n;


    % 节点6

    % 服务强度 service_strength_ien= arrive_rate / (c * service_rate);
    y6 = yi1(6) + yi2(6);
    rou_62n = lamda6_2_n / (y6 * miui(6));
    
    % 节点5排队长度
    % L_q = ((c * service_strength)^c * service_strength * P_0) / (gamma(c) * (1 - service_strength)^2);
    result6 = 0; % 初始化求和结果
    for d2 = 0:y6
        result6 = result6 + (y6 * rou_62n)^d2 / gamma(y6);
    end
    % disp(result6);
    
    L6n = ((rou_62n*(rou_62n*y6)^y6)*(1-rou_62n^(C2-y6)-(C2-y6)*rou_62n^(C2-y6)*(1-rou_62n)))...
        /(gamma(y6)*((1-rou_62n)^2)*(result6+y6^y6*rou_62n*(rou_62n^y6-rou_62n^C2)/(gamma(y6)*(1-rou_62n))));
    % t类(t=1)患者预期排队长度
    global lamda6_1_2_n;
    l_61n = (lamda6_1_2_n*L6n)/lamda6_2_n;
    % t类(t=2)患者预期排队长度
    global lamda6_2_2_n;
    l_62n = (lamda6_2_2_n*L6n)/lamda6_2_n;


    % 节点7

    % 服务强度 service_strength_ien= arrive_rate / (c * service_rate);
    y7 = yi1(7) + yi2(7);
    rou_72n = lamda7_2_n / (y7 * miui(7));
    
    % 节点5排队长度
    % L_q = ((c * service_strength)^c * service_strength * P_0) / (gamma(c) * (1 - service_strength)^2);
    result7 = 0; % 初始化求和结果
    for d2 = 0:y7
        result7 = result7 + (y7 * rou_72n)^d2 / gamma(y7);
    end
    % disp(result7);
    
    L7n = ((rou_72n*(rou_72n*y7)^y7)*(1-rou_72n^(C2-y7)-(C2-y7)*rou_72n^(C2-y7)*(1-rou_72n)))...
        /(gamma(y7)*((1-rou_72n)^2)*(result7+y7^y7*rou_72n*(rou_72n^y7-rou_72n^C2)/(gamma(y7)*(1-rou_72n))));
    % t类(t=1)患者预期排队长度
    global lamda7_1_2_n;
    l_71n = (lamda7_1_2_n*L7n)/lamda7_2_n;
    % t类(t=2)患者预期排队长度
    global lamda7_2_2_n;
    l_72n = (lamda7_2_2_n*L7n)/lamda7_2_n;


    % 节点8

    % 服务强度 service_strength_ien= arrive_rate / (c * service_rate);
    y8 = yi1(8) + yi2(8);
    rou_82n = lamda8_2_n / (y8 * miui(8));
    
    % L_q = ((c * service_strength)^c * service_strength * P_0) / (gamma(c) * (1 - service_strength)^2);
    result8 = 0; % 初始化求和结果
    for d2 = 0:y8
        result8 = result8 + (y8 * rou_82n)^d2 / gamma(y8);
    end
    % disp(result8);
    
    L8n = ((rou_82n*(rou_82n*y8)^y8)*(1-rou_82n^(C2-y8)-(C2-y8)*rou_82n^(C2-y8)*(1-rou_82n)))...
        /(gamma(y8)*((1-rou_82n)^2)*(result8+y8^y8*rou_82n*(rou_82n^y8-rou_82n^C2)/(gamma(y8)*(1-rou_82n))));
    % t类(t=1)患者预期排队长度
    global lamda8_1_2_n;
    l_81n = (lamda8_1_2_n*L8n)/lamda8_2_n;
    % t类(t=2)患者预期排队长度
    global lamda8_2_2_n;
    l_82n = (lamda8_2_2_n*L8n)/lamda8_2_n;


    % 节点2-转诊

    global Q elta_21n elta_22n elta_31n elta_32n elta_41n elta_42n;
    global L_21n L_31n L_41n L_22n L_32n L_42n;
    global result21 result22 sigma_2_1 sigma_2_2 sigma_3_1 sigma_3_2 sigma_4_1 sigma_4_2...
        rou_a21 rou_a22 rou_a31 rou_a32 rou_a41 rou_a42;
    
    % 节点2排队长度
    rou_a21 = 0.2; % ρa1 是顾客被阻塞而没有进入系统的比例
    y2 = yi1(2) + yi2(2);
    rou_211n = elta_21n / (y2 * miui(2)); 
    
    result21 = 0; % 初始化求和结果
    for d1 = 0:y2-1
        result21 = result21 + ((y2 * rou_211n)^(d1-y2)) / gamma(d1);
    end
    % disp(result21);
    z_21 = Q(1);
    sigma_2_1 = (elta_21n/(y2*miui(2))) .^ z_21;  % sigma_2_1的值
    
    L_21n = (elta_21n*(1-rou_a21)*(gamma(y2)*(1-rou_211n)*y2*miui(2)*result21+y2*miui(2))^(-1))/(1-sigma_2_1);  
    % t类(t=1)患者预期排队长度
    global lamda2_111n; 
    global l_211n;
    l_211n = (lamda2_111n*L_21n)/elta_21n;
    % t类(t=2)患者预期排队长度
    global lamda2_121n;
    global l_212n;
    l_212n = (lamda2_121n*L_21n)/elta_21n;  % l_itq
    
   
    % 节点2-非转诊 q=2

    rou_a22 = 0.2; % ρa1 是顾客被阻塞而没有进入系统的比例
    y2 = yi1(2) + yi2(2);
    rou_212n = elta_22n / (y2 * miui(2));
    result22 = 0;
    for d1 =1:Q(2)   % 节点2的n遍历时，用d1表示。
        result22 = result22 +  elta_22n;
    end
    % disp(result22); 
    
    result221 = 0; % 初始化求和结果
    for d1 = 0:y2-1
        result221 = result221 + ((y2 * rou_212n)^(d1-y2)) / gamma(d1);
    end
    % disp(result221);
    z_22 = Q(2);
    sigma_2_2 = (result22/(y2*miui(2))) .^ z_22;  % sigma_2_2的值
    
    L_22n = (elta_22n*(1-rou_a22)*(gamma(y2)*(1-rou_212n)*y2*miui(2)*result221+y2*miui(2))^(-1))/((1-sigma_2_2)*(1-sigma_2_2^2));  
    % t类(t=1)患者预期排队长度
    global lamda2_211n; 
    global l_221n;
    l_221n = (lamda2_211n*L_22n)/elta_22n;
    % t类(t=2)患者预期排队长度
    global lamda2_221n;
    global l_222n;
    l_222n = (lamda2_221n*L_22n)/elta_22n;  % l_itq


    % 节点3-转诊 q=1

    % 节点3排队长度
    rou_a31 = 0.3; % ρa1 是顾客被阻塞而没有进入系统的比例
    y3 = yi1(3) + yi2(3);
    rou_311n = elta_31n / (y3 * miui(3));
    
    result31 = 0; % 初始化求和结果
    for d1 = 0:y3-1
        result31 = result31 + ((y3 * rou_311n)^(d1-y3)) / gamma(d1);
    end
    % disp(result31);
    z_31 = Q(1);
    sigma_3_1 = (elta_31n/(y3*miui(3))) .^ z_31;  % sigma_2的值
    
    L_31n = (elta_31n*(1-rou_a31)*(gamma(y3)*(1-rou_311n)*y3*miui(3)*result31+y3*miui(3))^(-1))/(1-sigma_3_1);  
    % t类(t=1)患者预期排队长度
    global lamda3_111n l_311n;
    l_311n = (lamda3_111n*L_31n)/elta_31n;
    % t类(t=2)患者预期排队长度
    global lamda3_121n l_312n;
    l_312n = (lamda3_121n*L_31n)/elta_31n;  

    
    % 节点3-非转诊 q=2

    % 节点3排队长度
    rou_a32 = 0.3; % ρa1 是顾客被阻塞而没有进入系统的比例
    y3 = yi1(3) + yi2(3);
    rou_312n = elta_32n / (y3 * miui(3));
    
    result32 = 0;
    for d1 =1:Q(2)   % 节点2的n遍历时，用d1表示。改前原for d1 =1:q
        result32 = result32 +  elta_32n;
    end
    % disp(result32); 
    
    result321 = 0; % 初始化求和结果
    for d1 = 0:y3-1
        result321 = result321 + ((y3 * rou_312n)^(d1-y3)) / gamma(d1);
    end
    % disp(result321);
    z_32 = Q(2);
    sigma_3_2 = (result32/(y3*miui(3))) .^ z_32;  % sigma_2的值
    
    L_32n = (elta_32n*(1-rou_a32)*(gamma(y3)*(1-rou_312n)*y3*miui(3)*result321+y3*miui(3))^(-1))/((1-sigma_3_2)*(1-sigma_3_2^2));  
    % t类(t=1)患者预期排队长度
    global lamda3_211n l_321n;
    l_321n = (lamda3_211n*L_32n)/elta_32n;
    % t类(t=2)患者预期排队长度
    global lamda3_221n l_322n;
    l_322n = (lamda3_221n*L_32n)/elta_32n;  



    % 节点4-转诊 q=1

    % 节点4排队长度
    rou_a41 = 0.3; % ρa1 是顾客被阻塞而没有进入系统的比例
    y4 = yi1(4) + yi2(4);
    rou_411n = elta_41n / (y4 * miui(4));
    
    result41 = 0; % 初始化求和结果
    for d1 = 0:y4-1
        result41 = result41 + ((y4 * rou_411n)^(d1-y4)) / gamma(d1);
    end
    % disp(result41);
    z_41 = Q(1);
    sigma_4_1 = (elta_41n/(y4*miui(4))) .^ z_41;  % sigma_2的值
    
    L_41n = (elta_41n*(1-rou_a41)*(gamma(y4)*(1-rou_411n)*y4*miui(4)*result41+y4*miui(4))^(-1))/(1-sigma_4_1);  
    % t类(t=1)患者预期排队长度
    global lamda4_111n l_411n;
    l_411n = (lamda4_111n*L_41n)/elta_41n;
    
    % t类(t=2)患者预期排队长度
    % global lamda4_121n l_412n;
    % l_412n = (lamda4_121n*L_41n)/elta_41n; 



   % 节点4-非转诊 q=2

    % 节点4排队长度
    rou_a42 = 0.3; % ρa1 是顾客被阻塞而没有进入系统的比例
    y4 = yi1(4) + yi2(4);
    rou_412n = elta_42n / (y4 * miui(4));
    
    result42 = 0;
    for d1 =1:Q(2)   % 节点2的n遍历时，用d1表示。改前原for d1 =1:q
        result42 = result42 +  elta_42n;
    end
    % disp(result42); 
    
    result421 = 0; % 初始化求和结果
    for d1 = 0:y4-1
        result421 = result421 + ((y4 * rou_412n)^(d1-y4)) / gamma(d1);
    end
    % disp(result421);
    z_42 = Q(2);
    sigma_4_2 = (result32/(y4*miui(4))) .^ z_42;  % sigma_2的值
    
    L_42n = (elta_42n*(1-rou_a42)*(gamma(y4)*(1-rou_412n)*y4*miui(4)*result421+y4*miui(4))^(-1))/((1-sigma_4_2)*(1-sigma_4_2^2));  
    % t类(t=1)患者预期排队长度
    global lamda4_211n l_421n;
    l_421n = (lamda4_211n*L_42n)/elta_42n;
    % t类(t=2)患者预期排队长度
    global lamda4_221n l_422n;
    l_422n = (lamda4_221n*L_42n)/elta_42n;  


    li1 = [l_11n,0,0,0,l_51n,l_61n,l_71n,l_81n];
    li2 = [l_12n,0,0,0,l_52n,l_62n,l_72n,l_82n];
    lit = [li1;li2];

    l_i11n = [0,l_211n,l_311n,l_411n]; % l_iqtn
    l_i12n = [0,l_212n,l_312n,0];
    l_i1tn = [l_i11n;l_i12n];           % l_iqn

    l_i21n = [0,l_221n,l_321n,l_421n];
    l_i22n = [0,l_222n,l_322n,l_422n];
    l_i2tn = [l_i21n;l_i22n];


    eltai = [0, elta_21n,elta_22n, elta_31n, elta_32n, elta_41n, elta_42n, 0,0,0,0];

    rou_ien = [rou_11n,0,0,0,rou_52n,rou_62n,rou_72n,rou_82n];
    rou_ie1n = [0,rou_211n,rou_311n,rou_411n,0,0,0,0];
    rou_ie2n = [0,rou_212n,rou_312n,rou_412n,0,0,0,0];

    % part1
    global c_i_s_1;
    global c_i_s_0;
    part1  = 0;
    for i =1:8 
        for s= 1:2
            part1 = part1 + (rou_ien(i)+rou_ie1n(i)+rou_ie2n(i)) .* c_i_s_1(s,i) .* yis(s,i) + (3 - rou_ien(i)-rou_ie1n(i)-rou_ie2n(i)) .* c_i_s_0(s,i) .* yis(s,i);
        end
    end

    % part11 不确定对偶化部分
    %% 不确定参数 
    global tao0 tao1;
    part11 = 0;
    part11 = part11 + tao0 * thetas(1) + tao1 * thetas(2);
    for i =1:8 
        for s= 1:2
            part11 = part11 + zetas0(s,i) + zetas1(s,i);
        end
    end

    % part21
    part21 = 0;
    for i = 1:4
        for t = 1:2
            part21 = part21 + c_t(t)*lit(t,i);
        end
    end
   
    % part22 q=1 l_iqtn
    part22 = 0;
    for i = 1:4
        for t = 1:2
            part22 = part22 + c_t(t)*l_i1tn(t,i);
        end
    end
    
    % part23  q=2 l_iqtn
    part23 = 0;
    for i = 1:4
        for t = 1:2
            part23 = part23 + c_t(t)*l_i2tn(t,i);
        end
    end

    % part3
    part3 = 0;
    for i = 5:1:8
        for t = 1:2
            part3 = part3 + c_t_(t) * lit(t,i);
        end
    end


    % part4
    part4 = 0;
    for i = 1:4
        part4 = part4 + cf * eltai(i);
    end

    % 非线性目标函数示例  
    f_d = part1 + part11 + part21 + part22 + part23 + part3 + part4;
end  

% 目标函数
function f_d = objectiveFunction_play(x) 
    global c_t c_t_ cf;
    %  自变量
    yi1 = [x(1),x(2),x(3),x(4),x(5),x(6),x(7),x(8)];
    yi2 = [x(9),x(10),x(11),x(12),x(13),x(14),x(15),x(16)];
    zetai10 = [x(17),x(18),x(19),x(20),x(21),x(22),x(23),x(24)];
    zetai20 = [x(25),x(26),x(27),x(28),x(29),x(30),x(31),x(32)];
    theta0 = x(33);
    zetai11 = [x(34),x(35),x(36),x(37),x(38),x(39),x(40),x(41)];
    zetai21 = [x(42),x(43),x(44),x(45),x(46),x(47),x(48),x(49)];
    theta1 = x(50);

    yis = [yi1; yi2];
    zetas0 = [zetai10; zetai20];
    zetas1 = [zetai11; zetai21];
    thetas = [theta0; theta1];  

    global y1 y2 y3 y4 y5 y6 y7 y8;
    global lamda1_1_n;
    global lamda5_2_n;
    global lamda6_2_n;
    global lamda7_2_n;
    global lamda8_2_n;
    global miui L1n L5n L6n L7n L8n l_11n l_12n l_51n l_52n l_61n l_62n l_71n l_72n l_81n l_82n;
    global C1;
    C1 = 60; % 线下系统容量限制
    global C2;
    C2 = 30; % 线上系统容量限制
   
    % 节点1

    % 服务强度 service_strength_ien= arrive_rate / (c * service_rate);
    y1 = yi1(1) + yi2(1);
    rou_11n = lamda1_1_n / (y1 * miui(1))
    result1 = 0; % 初始化求和结果
    for d = 0:y1
        result1 = result1 + (y1 * rou_11n)^d / gamma(y1);
    end 
    % disp(result1);
    
    L1n = ((rou_11n*(rou_11n*y1)^y1)*(1-rou_11n^(C1-y1)-(C1-y1)*rou_11n^(C1-y1)*(1-rou_11n)))...
        /(gamma(y1)*((1-rou_11n)^2)*(result1+y1^y1*rou_11n*(rou_11n^y1-rou_11n^C1)/(gamma(y1)*(1-rou_11n))))
    % t类(t=1)患者预期排队长度
    global lamda1_1_1_n;
    l_11n = (lamda1_1_1_n*L1n)/lamda1_1_n
    % t类(t=2)患者预期排队长度s
    global lamda1_2_1_n;
    l_12n = (lamda1_2_1_n*L1n)/lamda1_1_n
    
    
    % 节点5

    % 服务强度 service_strength_ien= arrive_rate / (c * service_rate);
    y5 = yi1(5) + yi2(5);
    rou_52n = lamda5_2_n / (y5 * miui(5))
    
    % 节点5排队长度
    % L_q = ((c * service_strength)^c * service_strength * P_0) / (gamma(c) * (1 - service_strength)^2);
    result5 = 0; % 初始化求和结果
    for d2 = 0:y5
        result5 = result5 + (y5 * rou_52n)^d2 / gamma(y5);
    end
    % disp(result5);
    
    L5n = ((rou_52n*(rou_52n*y5)^y5)*(1-rou_52n^(C2-y5)-(C2-y5)*rou_52n^(C2-y5)*(1-rou_52n)))...
        /(gamma(y5)*((1-rou_52n)^2)*(result5+y5^y5*rou_52n*(rou_52n^y5-rou_52n^C2)/(gamma(y5)*(1-rou_52n))))
    % t类(t=1)患者预期排队长度
    global lamda5_1_2_n;
    l_51n = (lamda5_1_2_n*L5n)/lamda5_2_n
    % t类(t=2)患者预期排队长度
    global lamda5_2_2_n;
    l_52n = (lamda5_2_2_n*L5n)/lamda5_2_n


    % 节点6

    % 服务强度 service_strength_ien= arrive_rate / (c * service_rate);
    y6 = yi1(6) + yi2(6);
    rou_62n = lamda6_2_n / (y6 * miui(6))
    
    % 节点5排队长度
    % L_q = ((c * service_strength)^c * service_strength * P_0) / (gamma(c) * (1 - service_strength)^2);
    result6 = 0; % 初始化求和结果
    for d2 = 0:y6
        result6 = result6 + (y6 * rou_62n)^d2 / gamma(y6);
    end
    % disp(result6);
    
    L6n = ((rou_62n*(rou_62n*y6)^y6)*(1-rou_62n^(C2-y6)-(C2-y6)*rou_62n^(C2-y6)*(1-rou_62n)))...
        /(gamma(y6)*((1-rou_62n)^2)*(result6+y6^y6*rou_62n*(rou_62n^y6-rou_62n^C2)/(gamma(y6)*(1-rou_62n))))
    % t类(t=1)患者预期排队长度
    global lamda6_1_2_n;
    l_61n = (lamda6_1_2_n*L6n)/lamda6_2_n
    % t类(t=2)患者预期排队长度
    global lamda6_2_2_n;
    l_62n = (lamda6_2_2_n*L6n)/lamda6_2_n


    % 节点7

    % 服务强度 service_strength_ien= arrive_rate / (c * service_rate);
    y7 = yi1(7) + yi2(7);
    rou_72n = lamda7_2_n / (y7 * miui(7))
    
    % 节点5排队长度
    % L_q = ((c * service_strength)^c * service_strength * P_0) / (gamma(c) * (1 - service_strength)^2);
    result7 = 0; % 初始化求和结果
    for d2 = 0:y7
        result7 = result7 + (y7 * rou_72n)^d2 / gamma(y7);
    end
    % disp(result7);
    
    L7n = ((rou_72n*(rou_72n*y7)^y7)*(1-rou_72n^(C2-y7)-(C2-y7)*rou_72n^(C2-y7)*(1-rou_72n)))...
        /(gamma(y7)*((1-rou_72n)^2)*(result7+y7^y7*rou_72n*(rou_72n^y7-rou_72n^C2)/(gamma(y7)*(1-rou_72n))))
    % t类(t=1)患者预期排队长度
    global lamda7_1_2_n;
    l_71n = (lamda7_1_2_n*L7n)/lamda7_2_n
    % t类(t=2)患者预期排队长度
    global lamda7_2_2_n;
    l_72n = (lamda7_2_2_n*L7n)/lamda7_2_n


    % 节点8

    % 服务强度 service_strength_ien= arrive_rate / (c * service_rate);
    y8 = yi1(8) + yi2(8);
    rou_82n = lamda8_2_n / (y8 * miui(8))
    
    % L_q = ((c * service_strength)^c * service_strength * P_0) / (gamma(c) * (1 - service_strength)^2);
    result8 = 0; % 初始化求和结果
    for d2 = 0:y8
        result8 = result8 + (y8 * rou_82n)^d2 / gamma(y8);
    end
    % disp(result8);
    
    L8n = ((rou_82n*(rou_82n*y8)^y8)*(1-rou_82n^(C2-y8)-(C2-y8)*rou_82n^(C2-y8)*(1-rou_82n)))...
        /(gamma(y8)*((1-rou_82n)^2)*(result8+y8^y8*rou_82n*(rou_82n^y8-rou_82n^C2)/(gamma(y8)*(1-rou_82n))))
    % t类(t=1)患者预期排队长度
    global lamda8_1_2_n;
    l_81n = (lamda8_1_2_n*L8n)/lamda8_2_n
    % t类(t=2)患者预期排队长度
    global lamda8_2_2_n;
    l_82n = (lamda8_2_2_n*L8n)/lamda8_2_n


    % 节点2-转诊

    global Q elta_21n elta_22n elta_31n elta_32n elta_41n elta_42n;
    global L_21n L_31n L_41n L_22n L_32n L_42n;
    global result21 result22 sigma_2_1 sigma_2_2 sigma_3_1 sigma_3_2 sigma_4_1 sigma_4_2...
        rou_a21 rou_a22 rou_a31 rou_a32 rou_a41 rou_a42;
    
    % 节点2排队长度
    rou_a21 = 0.2; % ρa1 是顾客被阻塞而没有进入系统的比例
    y2 = yi1(2) + yi2(2);
    rou_211n = elta_21n / (y2 * miui(2))
    
    result21 = 0; % 初始化求和结果
    for d1 = 0:y2-1
        result21 = result21 + ((y2 * rou_211n)^(d1-y2)) / gamma(d1);
    end
    % disp(result21);
    z_21 = Q(1);
    sigma_2_1 = (elta_21n/(y2*miui(2))) .^ z_21;  % sigma_2_1的值
    
    L_21n = (elta_21n*(1-rou_a21)*(gamma(y2)*(1-rou_211n)*y2*miui(2)*result21+y2*miui(2))^(-1))/(1-sigma_2_1)
    % t类(t=1)患者预期排队长度
    global lamda2_111n; 
    global l_211n;
    l_211n = (lamda2_111n*L_21n)/elta_21n
    % t类(t=2)患者预期排队长度
    global lamda2_121n;
    global l_212n;
    l_212n = (lamda2_121n*L_21n)/elta_21n  % l_itq
    
   
    % 节点2-非转诊 q=2

    rou_a22 = 0.2; % ρa1 是顾客被阻塞而没有进入系统的比例
    y2 = yi1(2) + yi2(2);
    rou_212n = elta_22n / (y2 * miui(2))
    result22 = 0;
    for d1 =1:Q(2)   % 节点2的n遍历时，用d1表示。
        result22 = result22 +  elta_22n;
    end
    % disp(result22); 
    
    result221 = 0; % 初始化求和结果
    for d1 = 0:y2-1
        result221 = result221 + ((y2 * rou_212n)^(d1-y2)) / gamma(d1);
    end
    % disp(result221);
    z_22 = Q(2);
    sigma_2_2 = (result22/(y2*miui(2))) .^ z_22;  % sigma_2_2的值
    
    L_22n = (elta_22n*(1-rou_a22)*(gamma(y2)*(1-rou_212n)*y2*miui(2)*result221+y2*miui(2))^(-1))/((1-sigma_2_2)*(1-sigma_2_2^2)) 
    % t类(t=1)患者预期排队长度
    global lamda2_211n; 
    global l_221n;
    l_221n = (lamda2_211n*L_22n)/elta_22n
    % t类(t=2)患者预期排队长度
    global lamda2_221n;
    global l_222n;
    l_222n = (lamda2_221n*L_22n)/elta_22n  % l_itq


    % 节点3-转诊 q=1

    % 节点3排队长度
    rou_a31 = 0.3; % ρa1 是顾客被阻塞而没有进入系统的比例
    y3 = yi1(3) + yi2(3);
    rou_311n = elta_31n / (y3 * miui(3))
    
    result31 = 0; % 初始化求和结果
    for d1 = 0:y3-1
        result31 = result31 + ((y3 * rou_311n)^(d1-y3)) / gamma(d1);
    end
    % disp(result31);
    z_31 = Q(1);
    sigma_3_1 = (elta_31n/(y3*miui(3))) .^ z_31;  % sigma_2的值
    
    L_31n = (elta_31n*(1-rou_a31)*(gamma(y3)*(1-rou_311n)*y3*miui(3)*result31+y3*miui(3))^(-1))/(1-sigma_3_1)
    % t类(t=1)患者预期排队长度
    global lamda3_111n l_311n;
    l_311n = (lamda3_111n*L_31n)/elta_31n
    % t类(t=2)患者预期排队长度
    global lamda3_121n l_312n;
    l_312n = (lamda3_121n*L_31n)/elta_31n 

    
    % 节点3-非转诊 q=2

    % 节点3排队长度
    rou_a32 = 0.3; % ρa1 是顾客被阻塞而没有进入系统的比例
    y3 = yi1(3) + yi2(3);
    rou_312n = elta_32n / (y3 * miui(3))
    
    result32 = 0;
    for d1 =1:Q(2)   % 节点2的n遍历时，用d1表示。改前原for d1 =1:q
        result32 = result32 +  elta_32n;
    end
    % disp(result32); 
    
    result321 = 0; % 初始化求和结果
    for d1 = 0:y3-1
        result321 = result321 + ((y3 * rou_312n)^(d1-y3)) / gamma(d1);
    end
    % disp(result321);
    z_32 = Q(2);
    sigma_3_2 = (result32/(y3*miui(3))) .^ z_32;  % sigma_2的值
    
    L_32n = (elta_32n*(1-rou_a32)*(gamma(y3)*(1-rou_312n)*y3*miui(3)*result321+y3*miui(3))^(-1))/((1-sigma_3_2)*(1-sigma_3_2^2))
    % t类(t=1)患者预期排队长度
    global lamda3_211n l_321n;
    l_321n = (lamda3_211n*L_32n)/elta_32n
    % t类(t=2)患者预期排队长度
    global lamda3_221n l_322n;
    l_322n = (lamda3_221n*L_32n)/elta_32n 



    % 节点4-转诊 q=1

    % 节点4排队长度
    rou_a41 = 0.3; % ρa1 是顾客被阻塞而没有进入系统的比例
    y4 = yi1(4) + yi2(4);
    rou_411n = elta_41n / (y4 * miui(4))
    
    result41 = 0; % 初始化求和结果
    for d1 = 0:y4-1
        result41 = result41 + ((y4 * rou_411n)^(d1-y4)) / gamma(d1);
    end
    % disp(result41);
    z_41 = Q(1);
    sigma_4_1 = (elta_41n/(y4*miui(4))) .^ z_41;  % sigma_2的值
    
    L_41n = (elta_41n*(1-rou_a41)*(gamma(y4)*(1-rou_411n)*y4*miui(4)*result41+y4*miui(4))^(-1))/(1-sigma_4_1)
    % t类(t=1)患者预期排队长度
    global lamda4_111n l_411n;
    l_411n = (lamda4_111n*L_41n)/elta_41n
    
    % t类(t=2)患者预期排队长度
    % global lamda4_121n l_412n;
    % l_412n = (lamda4_121n*L_41n)/elta_41n



   % 节点4-非转诊 q=2

    % 节点4排队长度
    rou_a42 = 0.3; % ρa1 是顾客被阻塞而没有进入系统的比例
    y4 = yi1(4) + yi2(4);
    rou_412n = elta_42n / (y4 * miui(4))
    
    result42 = 0;
    for d1 =1:Q(2)   % 节点2的n遍历时，用d1表示。改前原for d1 =1:q
        result42 = result42 +  elta_42n;
    end
    % disp(result42); 
    
    result421 = 0; % 初始化求和结果
    for d1 = 0:y4-1
        result421 = result421 + ((y4 * rou_412n)^(d1-y4)) / gamma(d1);
    end
    % disp(result421);
    z_42 = Q(2);
    sigma_4_2 = (result32/(y4*miui(4))) .^ z_42;  % sigma_2的值
    
    L_42n = (elta_42n*(1-rou_a41)*(gamma(y4)*(1-rou_412n)*y4*miui(4)*result421+y4*miui(4))^(-1))/((1-sigma_4_2)*(1-sigma_4_2^2))
    % t类(t=1)患者预期排队长度
    global lamda4_211n l_421n;
    l_421n = (lamda4_211n*L_42n)/elta_42n
    % t类(t=2)患者预期排队长度
    global lamda4_221n l_422n;
    l_422n = (lamda4_221n*L_42n)/elta_42n  


    
    li1 = [l_11n,0,0,0,l_51n,l_61n,l_71n,l_81n];
    li2 = [l_12n,0,0,0,l_52n,l_62n,l_72n,l_82n];
    lit = [li1;li2];

    l_i11n = [0,l_211n,l_311n,l_411n]; % l_iqtn
    l_i12n = [0,l_212n,l_312n,0];
    l_i1tn = [l_i11n;l_i12n];           % l_iqn

    l_i21n = [0,l_221n,l_321n,l_421n];
    l_i22n = [0,l_222n,l_322n,l_422n];
    l_i2tn = [l_i21n;l_i22n];


    eltai = [0, elta_21n,elta_22n, elta_31n, elta_32n, elta_41n, elta_42n, 0,0,0,0];

    rou_ien = [rou_11n,0,0,0,rou_52n,rou_62n,rou_72n,rou_82n];
    rou_ie1n = [0,rou_211n,rou_311n,rou_411n,0,0,0,0];
    rou_ie2n = [0,rou_212n,rou_312n,rou_412n,0,0,0,0];

    % part1
    global c_i_s_1;
    global c_i_s_0;
    part1  = 0;
    for i =1:8 
        for s= 1:2
            part1 = part1 + (rou_ien(i)+rou_ie1n(i)+rou_ie2n(i)) .* c_i_s_1(s,i) .* yis(s,i) + (3 - rou_ien(i)-rou_ie1n(i)-rou_ie2n(i)) .* c_i_s_0(s,i) .* yis(s,i);
        end
    end

    % part11 不确定对偶化部分
    %% 不确定参数 
    global tao0 tao1;
    part11 = 0;
    part11 = part11 + tao0 * thetas(1) + tao1 * thetas(2);
    for i =1:8 
        for s= 1:2
            part11 = part11 + zetas0(s,i) + zetas1(s,i);
        end
    end

    % part21
    part21 = 0;
    for i = 1:4
        for t = 1:2
            part21 = part21 + c_t(t)*lit(t,i);
        end
    end
   
    % part22 q=1 l_iqtn
    part22 = 0;
    for i = 1:4
        for t = 1:2
            part22 = part22 + c_t(t)*l_i1tn(t,i);
        end
    end
    
    % part23  q=2 l_iqtn
    part23 = 0;
    for i = 1:4
        for t = 1:2
            part23 = part23 + c_t(t)*l_i2tn(t,i);
        end
    end

    % part3
    part3 = 0;
    for i = 5:1:8
        for t = 1:2
            part3 = part3 + c_t_(t) * lit(t,i);
        end
    end


    % part4
    part4 = 0;
    for i = 1:4
        part4 = part4 + cf * eltai(i);
    end
    
    OC = part1 + part11
    WC = part21 + part22 + part23 + part3
    RC = part4
    % 非线性目标函数
    f_d = OC + WC + RC;

    %f_d = part1 + part11 + part21 + part22 + part23 + part3 + part4;
end  

% 通过非线性约束实现整数约束
function [c, ceq] = nonlcon(x)
    global a_i_s_1 a_i_s_0 lamda1_1_n lamda5_2_n lamda6_2_n lamda7_2_n lamda8_2_n elta_21n elta_22n elta_31n elta_32n elta_41n elta_42n miui;
     epsilon = 1e-6;
    c = [lamda1_1_n / ((x(1)+x(9)) * miui(1)) - 1 + epsilon;   % <= 1 的约束
         -lamda1_1_n / ((x(1)+x(9)) * miui(1));      % >= 0 的约束
         (elta_21n / ((x(2)+x(10)) * miui(2))) - 1 + epsilon; % 转正和非转诊分开写
         -(elta_21n / ((x(2)+x(10)) * miui(2)));
         (elta_22n / ((x(2)+x(10)) * miui(2))) - 1 + epsilon; % 转正和非转诊分开写
         -(elta_22n / ((x(2)+x(10)) * miui(2)));
          ((elta_21n+elta_22n) / ((x(2)+x(10)) * miui(2))) - 1 + epsilon; % 转正和非转诊分开写
         -((elta_21n+elta_22n) / ((x(2)+x(10)) * miui(2)));
         (elta_31n / ((x(3)+x(11)) * miui(3))) - 1 + epsilon;
         -(elta_31n / ((x(3)+x(11)) * miui(3)));
         (elta_32n / ((x(3)+x(11)) * miui(3))) - 1 + epsilon;
         -(elta_32n / ((x(3)+x(11)) * miui(3)));
          ((elta_31n + elta_32n) / ((x(3)+x(11)) * miui(3))) - 1 + epsilon;
         -((elta_31n + elta_32n) / ((x(3)+x(11)) * miui(3)));
         (elta_41n / ((x(4)+x(12)) * miui(4))) - 1 + epsilon;
         -(elta_41n / ((x(4)+x(12)) * miui(4)));
         (elta_42n / ((x(4)+x(12)) * miui(4))) - 1 + epsilon;
         -(elta_42n / ((x(4)+x(12)) * miui(4)));
          ((elta_41n+elta_42n) / ((x(4)+x(12)) * miui(4))) - 1 + epsilon;
         -((elta_41n+elta_42n) / ((x(4)+x(12)) * miui(4)));
         lamda5_2_n / ((x(5)+x(13)) * miui(5)) - 1 + epsilon;
         -lamda5_2_n / ((x(5)+x(13)) * miui(5));
         lamda6_2_n / ((x(6)+x(14)) * miui(6)) - 1 + epsilon;
         -lamda6_2_n / ((x(6)+x(14)) * miui(6));
         lamda7_2_n / ((x(7)+x(15)) * miui(7)) - 1 + epsilon;
         -lamda7_2_n / ((x(7)+x(15)) * miui(7));
         lamda8_2_n / ((x(8)+x(16)) * miui(8)) - 1 + epsilon;
         -lamda8_2_n / ((x(8)+x(16)) * miui(8));
        lamda1_1_n*a_i_s_1(1,1)*x(1)/((x(1)+x(9))*miui(1))-x(17)-x(33)+epsilon;
        lamda1_1_n*a_i_s_1(2,1)*x(9)/((x(1)+x(9))*miui(1))-x(25)-x(33)+epsilon;
        (elta_21n+elta_22n)*a_i_s_1(1,2)*x(2)/((x(2)+x(10))*miui(2))-x(18)-x(33)+epsilon;
        (elta_21n+elta_22n)*a_i_s_1(2,2)*x(10)/((x(2)+x(10))*miui(2))-x(26)-x(33)+epsilon;
        (elta_31n+elta_32n)*a_i_s_1(1,3)*x(3)/((x(3)+x(11))*miui(3))-x(19)-x(33)+epsilon;
        (elta_31n+elta_32n)*a_i_s_1(2,3)*x(11)/((x(3)+x(11))*miui(3))-x(27)-x(33)+epsilon;
        (elta_41n+elta_42n)*a_i_s_1(1,4)*x(4)/((x(4)+x(12))*miui(4))-x(20)-x(33)+epsilon;
        (elta_41n+elta_42n)*a_i_s_1(2,4)*x(12)/((x(4)+x(12))*miui(4))-x(28)-x(33)+epsilon;
        lamda5_2_n*a_i_s_1(1,5)*x(5)/((x(5)+x(13))*miui(5))-x(21)-x(33)+epsilon;
        lamda5_2_n* a_i_s_1(2,5)*x(13)/((x(5)+x(13))*miui(5))-x(29)-x(33)+epsilon;
        lamda6_2_n* a_i_s_1(1,6)*x(6)/((x(6)+x(14))*miui(6))-x(22)-x(33)+epsilon;
        lamda6_2_n* a_i_s_1(2,6)*x(14)/((x(6)+x(14))*miui(6))-x(30)-x(33)+epsilon;
        lamda7_2_n* a_i_s_1(1,7)*x(7)/((x(7)+x(15))*miui(7))-x(23)-x(33)+epsilon;
        lamda7_2_n* a_i_s_1(2,7)*x(15)/((x(7)+x(15))*miui(7))-x(31)-x(33)+epsilon;
        lamda8_2_n* a_i_s_1(1,8)*x(8)/((x(8)+x(16))*miui(8))-x(24)-x(33)+epsilon;
        lamda8_2_n* a_i_s_1(2,8)*x(16)/((x(8)+x(16))*miui(8))-x(32)-x(33)+epsilon;
        (1-lamda1_1_n/((x(1)+x(9))*miui(1)))*a_i_s_0(1,1)*x(1)-x(34)-x(50)+epsilon;
        (1-lamda1_1_n/((x(1)+x(9))*miui(1)))*a_i_s_0(2,1)*x(9)-x(42)-x(50)+epsilon;
        (1-(elta_21n+elta_22n)/((x(2)+x(10))*miui(2)))*a_i_s_0(1,2)*x(2)-x(35)-x(50)+epsilon;
        (1-(elta_21n+elta_22n)/((x(2)+x(10))*miui(2)))*a_i_s_0(2,2)*x(10)-x(43)-x(50)+epsilon;
        (1-(elta_31n+elta_32n)/((x(3)+x(11))*miui(3)))*a_i_s_0(1,3)*x(3)-x(36)-x(50)+epsilon;
        (1-(elta_31n+elta_32n)/((x(3)+x(11))*miui(3)))*a_i_s_0(2,3)*x(11)-x(44)-x(50)+epsilon;
        (1-(elta_41n+elta_42n)/((x(4)+x(12))*miui(4)))*a_i_s_0(1,4)*x(4)-x(37)-x(50)+epsilon;
        (1-(elta_41n+elta_42n)/((x(4)+x(12))*miui(4)))*a_i_s_0(2,4)*x(12)-x(45)-x(50)+epsilon;
        (1-lamda5_2_n/((x(5)+x(13))*miui(5)))*a_i_s_0(1,5)*x(5)-x(38)-x(50)+epsilon;
        (1-lamda5_2_n/((x(5)+x(13))*miui(5)))*a_i_s_0(2,5)*x(13)-x(46)-x(50)+epsilon;
        (1-lamda6_2_n/((x(6)+x(14))*miui(6)))*a_i_s_0(1,6)*x(6)-x(39)-x(50)+epsilon;
        (1-lamda6_2_n/((x(6)+x(14))*miui(6)))*a_i_s_0(2,6)*x(14)-x(47)-x(50)+epsilon;
        (1-lamda7_2_n/((x(7)+x(15))*miui(7)))*a_i_s_0(1,7)*x(7)-x(40)-x(50)+epsilon;
        (1-lamda7_2_n/((x(7)+x(15))*miui(7)))*a_i_s_0(2,7)*x(15)-x(48)-x(50)+epsilon;
        (1-lamda8_2_n/((x(8)+x(16))*miui(8)))*a_i_s_0(1,8)*x(8)-x(41)-x(50)+epsilon;
        (1-lamda8_2_n/((x(8)+x(16))*miui(8)))*a_i_s_0(2,8)*x(16)-x(49)-x(50)+epsilon;
        ];
    ceq = [x(1) - floor(x(1) + 0.5); x(2) - floor(x(2) + 0.5); x(3) - floor(x(3) + 0.5);
        x(4) - floor(x(4) + 0.5); x(5) - floor(x(5) + 0.5); x(6) - floor(x(6) + 0.5);
        x(7) - floor(x(7) + 0.5); x(8) - floor(x(8) + 0.5); x(9) - floor(x(9) + 0.5);
        x(10) - floor(x(10) + 0.5); x(11) - floor(x(11) + 0.5); x(12) - floor(x(12) + 0.5);
        x(13) - floor(x(13) + 0.5); x(14) - floor(x(14) + 0.5); x(15) - floor(x(15) + 0.5);
        x(16) - floor(x(16) + 0.5)]; % 等式约束，强制为整数
end
