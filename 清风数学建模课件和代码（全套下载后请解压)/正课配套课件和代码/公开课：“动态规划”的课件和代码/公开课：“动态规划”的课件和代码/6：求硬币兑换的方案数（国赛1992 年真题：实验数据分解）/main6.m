%% ��Ӳ�Ҷһ��ķ�����
coins = [2 3 5 6];
S = 10 ;
f = coin_change_numbers(coins, S)
% f = 5

coins = [1 2 3];
S = 4 ;
f = coin_change_numbers(coins, S)
% f = 4

%%  ����1992������
coins = [57,71,87,97,99,101,103,113,114,115,128,129,131,137,147,156,163,186]
[f, FF] = coin_change_numbers(coins, 1000);
ff = FF(end,:);  % ȡ��DP����(FF)�����һ�У�����������XΪ1��1000ʱ�ķ�������
ff(100:100:1000)  % ÿ��100���һ��ֵ
plot(ff,'LineWidth',2)   % �ߵĿ��ȡ2���ÿ�һ��
xlabel('������'); ylabel('������');   % x y����������ǩ
