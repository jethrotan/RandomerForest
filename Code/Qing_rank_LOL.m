%Plot optimal LOL projection of Qing's data, including unknowns

clear
close all
clc

fpath = mfilename('fullpath');
findex = strfind(fpath,'/');
rootDir=fpath(1:findex(end-1));
p = genpath(rootDir);
gits=strfind(p,'.git');
colons=strfind(p,':');
for i=0:length(gits)-1
endGit=find(colons>gits(end-i),1);
p(colons(endGit-1):colons(endGit)-1)=[];
end
addpath(p);

MarkerSize = 8;
LineWidth = 2;

[data,txt,raw] = xlsread('Qing Dataset 70 Samples Unnormalized (12-16-2014).xlsx');
Xtrain = data(:,1:46)';
Xtrain_rank = passtorank(Xtrain);
Xtest = data(:,47:end)';
Ytrain = zeros(size(Xtrain_rank,1),1);
Ytrain(27:46) = 1;
Xtest_rank = interpolate_rank(Xtrain,Xtest);
Ystr = cellstr(num2str(Ytrain));
samples = txt(1,2:end);
for i = 1:length(samples)
    if ~isempty(strfind(samples{i},'UNKNOWN'))
        samples{i} = samples{i}(strfind(samples{i},'_')+1:end);
    end
end

parms.types={'DENL'};
parms.Kmax = 3;

Proj = LOL(Xtrain_rank,Ystr,parms.types,parms.Kmax);
Xtrain_LOL = Xtrain_rank*transpose(Proj{1}.V);
Xtest_LOL = Xtest_rank*transpose(Proj{1}.V);
Xall_LOL = cat(1,Xtrain_LOL,Xtest_LOL);
Maxs = max(Xall_LOL);
Mins = min(Xall_LOL);

linclass = fitcdiscr(Xtrain_LOL,Ystr);
Yhats = predict(linclass,Xtest_LOL);
gmm = gmdistribution(linclass.Mu,linclass.Sigma);
post_prob = posterior(gmm,Xall_LOL);

fid = fopen('/Users/Tyler/Documents/MATLAB/CancerAnalysis/Results/Qing_rank_LOL_posteriors.txt','a');
T = cell2table(cat(2,cat(1,'Sample',samples'),cat(1,'p(Cancer|x)',cellstr(num2str(post_prob(:,2))))));
writetable(T,'/Users/Tyler/Documents/MATLAB/CancerAnalysis/Results/Qing_rank_LOL_posteriors.txt');
fclose(fid);

plot3(Xtrain_LOL(Ytrain==0,1),Xtrain_LOL(Ytrain==0,2),Xtrain_LOL(Ytrain==0,3),'bo',...
    Xtrain_LOL(Ytrain==1,1),Xtrain_LOL(Ytrain==1,2),Xtrain_LOL(Ytrain==1,3),'rx',...
    Xtest_LOL(strcmp(Yhats,'0'),1),Xtest_LOL(strcmp(Yhats,'0'),2),Xtest_LOL(strcmp(Yhats,'0'),3),'ko',...
    Xtest_LOL(strcmp(Yhats,'1'),1),Xtest_LOL(strcmp(Yhats,'1'),2),Xtest_LOL(strcmp(Yhats,'1'),3),'kx')
set(gcf,'Visible','On')
legend('Normal','Cancer','Unknown (predicted as normal)','Unknown (predicted as cancer)')
text(Xtest_LOL(strcmp(Yhats,'1'),1),Xtest_LOL(strcmp(Yhats,'1'),2),Xtest_LOL(strcmp(Yhats,'1'),3),...
    samples(strcmp(Yhats,'1')),'VerticalAlignment','bottom','HorizontalAlignment','left',...
    'FontSize',9)

L = linclass.Coeffs(1,2).Linear;
K = linclass.Coeffs(1,2).Const;
x1 = linspace(-11e4,-1e4);
x2 = linspace(-800,-100);
[x1_hyper,x2_hyper] = meshgrid(x1,x2);
x3_hyper = (-L(1)*x1_hyper - L(2)*x2_hyper - K)/L(3);
Maxs = max(Xall_LOL);
Mins = min(Xall_LOL);
ax = gca;
ax.XLim = [Mins(1) Maxs(1)];
ax.YLim = [Mins(2) Maxs(2)];
ax.ZLim = [Mins(3) Maxs(3)];
hold on
sf = surf(x1_hyper,x2_hyper,x3_hyper);
xmax = max(Xall_LOL(:,1));
xmin = min(Xall_LOL(:,1));
ymax = max(Xall_LOL(:,2));
ymin = min(Xall_LOL(:,2));
zmax = max(Xall_LOL(:,3));
zmin = min(Xall_LOL(:,3));
ax = gca;
ax.XLim = [xmin xmax];
ax.YLim = [ymin ymax];
ax.ZLim = [zmin zmax];
sf.FaceColor = 'k';
sf.FaceAlpha = 0.4;
sf.EdgeAlpha = 1;
sf.LineWidth = LineWidth;
ln = findobj(gca,'Type','Line');
ln(1).MarkerSize = MarkerSize;
ln(2).MarkerSize = MarkerSize;
ln(3).MarkerSize = MarkerSize;
ln(4).MarkerSize = MarkerSize;
ln(1).LineWidth = LineWidth;
ln(2).LineWidth = LineWidth;
ln(3).LineWidth = LineWidth;
ln(4).LineWidth = LineWidth;
ln(1).Color = 'm';
ln(2).Color = 'm';
ln(3).Color = 'c';
ln(4).Color = 'g';
grid on
xlabel('k1')
ylabel('k2')
zlabel('k3')
title('LOL on Ranked Data')
%fname = '~/Documents/MATLAB/CancerAnalysis/Plots/Qing_rank_LOL';
%save_fig(gcf,fname)