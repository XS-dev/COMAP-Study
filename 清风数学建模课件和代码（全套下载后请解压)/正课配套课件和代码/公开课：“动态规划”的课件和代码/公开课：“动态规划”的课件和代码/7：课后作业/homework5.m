% 作业5：编辑距离
% 题目来源：力扣72. 编辑距离   链接：https://leetcode-cn.com/problems/edit-distance/
function f = homework5(word1,word2)
    m = length(word1);
    n = length(word2);
    FF = ones(m,n);  % 初始化DP数组
% 处理第一行
    ind = strfind(word2, word1(1));   % 在word2中找word1的第一个字母
    for j = 1:n
        if isempty(ind)  % word1的第1个字母不在word2中
            FF(1,j)=j;
        % word1的第一个字母在word2中时, ind里面可能有多个位置，我们只需要首次出现的位置
        elseif ind(1)==1   % word1和word2的第1个字母相同
            FF(1,j)=j-1;
        else
        % 如果位置不为1，那么该位置之前的FF(1,j)=j，该位置以及该位置之后的FF(1,j)=j-1
            if j < ind(1)
                FF(1,j)=j;
            else
                FF(1,j)=j-1;
            end
        end
    end
% 处理第一列
    ind = strfind(word1, word2(1));   % 在word1中找word2的第一个字母
    for i = 1:m
        if isempty(ind)  % word2的第1个字母不在word1中
            FF(i,1)=i;
        % word2的第一个字母在word1中时, ind里面可能有多个位置，我们只需要首次出现的位置
        elseif ind(1)==1   % word1和word2的第1个字母相同
            FF(i,1)=i-1;
        else
        % 如果位置不为1，那么该位置之前的FF(i,1)=i，该位置以及该位置之后的FF(i,1)=i-1
            if i < ind(1)
                FF(i,1)=i;
            else
                FF(i,1)=i-1;
            end
        end
    end    
% 循环计算右下部分的元素
    for i = 2:m
        for j = 2:n
            tmp1 = FF(i-1,j-1) + (word1(i) ~= word2(j))*1;
            %  先把 word1[1..i-1] 变换到 word2[1..j-1]，消耗掉FF(i-1,j-1)步，
            %  再把 word1[i] 改成 word2[j]，就行了。
            %  这里分为两种情况：如果 word1[i] == word2[j]，什么也不用做，一共消耗 FF(i-1,j-1) 步；
            %  否则需要替换最后一个字符，一共消耗 FF(i-1,j-1) + 1 步。
            tmp2 = FF(i-1,j) + 1;
            %  先把 word1[1..i-1] 变换到 word2[1..j]，消耗掉 FF(i-1,j) 步，
            %  再把 word1[i] 删除，这样word1[1..i] 就完全变成了 word2[1..j] 了，
            %  一共消耗FF(i-1,j)+ 1 步。
            tmp3 = FF(i,j-1) + 1;
            %  先把 word1[1..i] 变换成 word2[1..j-1]，消耗掉 FF(i,j-1) 步
            %  接下来，再插入一个字符 word2[j], word1[1..i] 就完全变成了 word2[1..j] 了。
            %  一共消耗FF(i,j-1)+ 1 步。
            FF(i,j) = min([tmp1,tmp2,tmp3]);
            % 从上面三个问题来看，word1[1..i] 变换成 word2[1..j] 主要有三种操作
            % 哪种操作步数最少就用哪种。
        end
    end
    f =FF(m,n);
end



% % 注意：代码文件仅供参考，一定不要直接用于自己的数模论文中
% % 国赛对于论文的查重要求非常严格，代码雷同也算作抄袭
% % 视频中提到的附件可在售后群（购买后收到的那个无忧自动发货的短信中有加入方式）的群文件中下载。包括讲义、代码、我视频中推荐的资料等。
% % 关注我的微信公众号《数学建模学习交流》，后台发送“软件”两个字，可获得常见的建模软件下载方法；发送“数据”两个字，可获得建模数据的获取方法；发送“画图”两个字，可获得数学建模中常见的画图方法。另外，也可以看看公众号的历史文章，里面发布的都是对大家有帮助的技巧。
% % 购买更多优质精选的数学建模资料，可关注我的微信公众号《数学建模学习交流》，在后台发送“买”这个字即可进入店铺(我的微店地址：https://weidian.com/?userid=1372657210)进行购买。
% % 视频价格不贵，但价值很高。单人购买观看只需要58元，三人购买人均仅需46元，视频本身也是下载到本地观看的，所以请大家不要侵犯知识产权，对视频或者资料进行二次销售。
% % 如何修改代码避免查重的方法：https://www.bilibili.com/video/av59423231（必看）