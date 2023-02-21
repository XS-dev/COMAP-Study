%% 怎么得到具体的硬币组合
function [f, IND] = coin_change2(coins, S)
    FF = +inf * ones(1,S+2);  
    FF(S+2) = 0;  % 最后一个元素改为0
    for x = 1:S
        tmp = x - coins;  
        tmp(tmp<0) = S+1;    
        tmp(tmp==0) = S+2;  
        FF(x) = min(FF(tmp))+1;
    end   
    % 利用FF来计算IND
    IND = [];  % IND表示我们选择的硬币组合，初始化为空向量
    if FF(S) < +inf  % 存在能凑成S的组合
        f = FF(S);
        ind = S;    % ind先指向最后一个位置S
        while FF(ind) > 1  % 如果FF(ind) = 1时就不用寻找了
            indd = ind;  % 保存前一个位置
            tmp = ind - coins;  
            tmp(tmp<0) = S+1;    % FF下标为S+1的元素为+inf
            tmp(tmp==0) = S+2;  % FF最后一个元素为0
            ind = tmp(find(FF(tmp) == (FF(ind) -1),1));  % 找到新的位置
            IND = [IND,indd-ind];  % 两个位置之差就是我们要添加的硬币
        end
        IND = [IND,ind];  % FF(ind) = 1时，把ind也放入到IND中
    else  % 如果没有任何一种硬币组合能组成总金额S就返回-1
        f = -1;   
    end
end


% % 注意：代码文件仅供参考，一定不要直接用于自己的数模论文中
% % 国赛对于论文的查重要求非常严格，代码雷同也算作抄袭
% % 视频中提到的附件可在售后群（购买后收到的那个无忧自动发货的短信中有加入方式）的群文件中下载。包括讲义、代码、我视频中推荐的资料等。
% % 关注我的微信公众号《数学建模学习交流》，后台发送“软件”两个字，可获得常见的建模软件下载方法；发送“数据”两个字，可获得建模数据的获取方法；发送“画图”两个字，可获得数学建模中常见的画图方法。另外，也可以看看公众号的历史文章，里面发布的都是对大家有帮助的技巧。
% % 购买更多优质精选的数学建模资料，可关注我的微信公众号《数学建模学习交流》，在后台发送“买”这个字即可进入店铺(我的微店地址：https://weidian.com/?userid=1372657210)进行购买。
% % 视频价格不贵，但价值很高。单人购买观看只需要58元，三人购买人均仅需46元，视频本身也是下载到本地观看的，所以请大家不要侵犯知识产权，对视频或者资料进行二次销售。
% % 如何修改代码避免查重的方法：https://www.bilibili.com/video/av59423231（必看）

