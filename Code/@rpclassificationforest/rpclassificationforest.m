classdef rpclassificationforest
    
    properties
        oobidx = {}; %indices of out of bag samples for each tree
        Tree = {};  %classification trees contained in the ensemble
        nTrees = []; %number of trees in the ensemble
        classname;
        RandomForest;
        Robust;
        NumVars = [];
    end
    
    methods
        function forest = rpclassificationforest(nTrees,X,Y,varargin)
            %class contstructor for RandomerForest object
            %nTrees is number of trees
            %X is an n x d matrix where n is number of samples and d is
            %number of dimensions (predictor variables)
            %Y is an n x 1 cell string of class labels
            
            %Optional Arguments:
            
                %s: s a parameter that specifies the sparsity of the random
                %projection matrix. Sparsity is computed as 1/(2*s). Only
                %used if sparsemethod is set to 'dense' or 'dgaussian'
                
                %mdiff: string 'on' or 'off'. Specifying 'on' allows the
                %difference in class-conditional means to sampled as a
                %projection
                
                %sparsemethod: string specifying the method for sampling
                %the random projection matrix. Options are 'dense' (dense
                %1s and 0s), 'sparse' (sparse 1s and 0s)
                %'dgaussian' (dense gaussian), 'uniform' (sparse uniform), and 'gaussian' (sparse gaussian)
                
                %RandomForest: logical true or false (default). Setting to
                %true performs regular random forest
                
                %Robust: logical true or false (defualt). Setting to true
                %passes the data to marginal ranks prior to any computing
                
                
            if ~iscell(Y)
                Y = cellstr(num2str(Y));
            end
            forest.classname = unique(Y);
            forest = growTrees(forest,nTrees,X,Y,varargin{:});
        end     %class constructor
        
        function forest = growTrees(forest,nTrees,X,Y,varargin)
            okargs =   {'priorprob' 'cost'    'splitcriterion'  'splitmin'...
                        'minparent' 'minleaf'   'nvartosample'...
                        'mergeleaves'   'categorical' 'prune' 'method' ...
                        'qetoler'   'names'   'weights' 'surrogate'...
                        'skipchecks'    'stream'    'fboot'...
                        'SampleWithReplacement' 's' 'mdiff' 'sparsemethod'...
                        'RandomForest'   'Robust'   'NWorkers'};
            defaults = {[]  []  'gdi'   []  []  1   ceil(size(X,2)^(2/3))...
                        'off'    []  'off'    'classification'  1e-6    {}...
                        []  'off'   false  []  1    true   3    'off'   'dense'...
                        false false 2};
            [Prior,Cost,Criterion,splitmin,minparent,minleaf,...
                nvartosample,Merge,categ,Prune,Method,qetoler,names,W,...
                surrogate,skipchecks,Stream,fboot,...
                SampleWithReplacement,s,mdiff,sparsemethod,RandomForest,...
                Robust,NWorkers,~,extra] = ...
                internal.stats.parseArgs(okargs,defaults,varargin{:});
            
            %Convert to double if not already
            if ~isa(X,'double')
                X = double(X);
            end
            
            if Robust
                %X = passtorank(X);
                X = tiedrank(X);
                forest.Robust = true;
            else
                forest.Robust = false;
            end
            nboot = ceil(fboot*length(Y));
            Tree = cell(nTrees,1);
            oobidx = cell(nTrees,1);
            poolobj = gcp('nocreate');
            if isempty(poolobj);
                parpool('local',NWorkers,'IdleTimeout',360);
            end
            parfor i = 1:nTrees
                sampleidx = 1:length(Y);
                go = true;
                while go
                    ibidx = randsample(sampleidx,nboot,SampleWithReplacement);
                    oobidx{i} = setdiff(sampleidx,ibidx);
                    go = isempty(oobidx{i});
                end
                if ~RandomForest
                    Tree{i} = rpclassregtree(X(ibidx,:),Y(ibidx,:),...
                        'priorprob',Prior,'cost',Cost,'splitcriterion',...
                        Criterion,'splitmin',splitmin,'minparent',...
                        minparent,'minleaf',minleaf,'nvartosample',...
                        nvartosample,'mergeleaves',Merge,'categorical',...
                        categ,'prune',Prune,'method',Method,'qetoler',...
                        qetoler,'names',names,'weights',W,'surrogate',...
                        surrogate,'skipchecks',skipchecks,'stream',Stream,...
                        's',s,'mdiff',mdiff,'sparsemethod',sparsemethod);
                else
                    Tree{i} = classregtree2(X(ibidx,:),Y(ibidx,:),...
                        'priorprob',Prior,'cost',Cost,'splitcriterion',...
                        Criterion,'splitmin',splitmin,'minparent',...
                        minparent,'minleaf',minleaf,'nvartosample',...
                        nvartosample,'mergeleaves',Merge,'categorical',...
                        categ,'prune',Prune,'method',Method,'qetoler',...
                        qetoler,'names',names,'weights',W,'surrogate',...
                        surrogate,'skipchecks',skipchecks,'stream',Stream);
                end  
            end     %parallel loop over i
            
            %Compute interpretability as total number of variables split on
            NumVars = NaN(1,nTrees);
            if RandomForest
                for i = 1:nTrees
                    NumVars(i) = sum(Tree{i}.var~=0);
                end
            else
                for i = 1:nTrees
                    internalnodes = transpose(Tree{i}.node(Tree{i}.var ~= 0));
                    TreeVars = zeros(1,length(Tree{i}.node));
                    for nd = internalnodes
                        if ~Tree{i}.isdelta(nd)
                            TreeVars(nd) = nnz(Tree{i}.rpm{nd});
                        end
                    end
                    NumVars(i) = sum(TreeVars);
                end
            end                        
            forest.Tree = Tree;
            forest.oobidx = oobidx;
            forest.nTrees = length(forest.Tree);
            forest.RandomForest = RandomForest;
            forest.NumVars = NumVars;
        end     %function rpclassificationforest
        
        function [err,varargout] = oobpredict(forest,X,Y,treenum)
            if nargin == 3
                treenum = 'last';
            end
            
            %Convert to double if not already
            if ~isa(X,'double')
                X = double(X);
            end
            
            if forest.Robust
                %X = passtorank(X);
                X = tiedrank(X);
            end
            nrows = size(X,1);
            predmat = NaN(nrows,forest.nTrees);
            predcell = cell(nrows,forest.nTrees);
            OOBIndices = forest.oobidx;
            trees = forest.Tree;
            Labels = forest.classname;
            if ~forest.RandomForest
                parfor i = 1:forest.nTrees
                    pred_i = num2cell(NaN(nrows,1));
                    pred_i(OOBIndices{i}) = rptreepredict(trees{i},X(OOBIndices{i},:));
                    predcell(:,i) = pred_i;
                end
            else
                parfor i = 1:forest.nTrees
                    pred_i = num2cell(NaN(nrows,1));
                    pred_i(OOBIndices{i}) = eval(trees{i},X(OOBIndices{i},:));
                    predcell(:,i) = pred_i;
                end
            end
            for j = 1:length(forest.classname)
                predmat(strcmp(predcell,Labels{j})) = j;
            end
            if strcmp(treenum,'every')
                err = NaN(forest.nTrees,1);
                parfor i = 1:forest.nTrees
                    ensemblepredictions = mode(predmat(:,1:i),2);
                    missing = isnan(ensemblepredictions);
                    predictions = Labels(ensemblepredictions(~missing));
                    wrong = ~strcmp(predictions,Y(~missing));
                    err(i) = mean(wrong);
                end
            else
                ensemblepredictions = mode(predmat,2);
                missing = isnan(ensemblepredictions);
                predictions = Labels(ensemblepredictions(~missing));
                wrong = ~strcmp(predictions,Y(~missing));
                err = mean(wrong);         
            end
            %if length(unique(Y)) == 2
            %    pos = num2str(max(str2num(char(Y))));
            %    neg = num2str(min(str2num(char(Y))));
                
                %varargout{1} = sum(strcmp(predictions(strcmp(pos,Y)),Y(~missing & strcmp(pos,Y))))/sum(strcmp(pos,Y));  %sensitivity
                %varargout{2} = sum(strcmp(predictions(strcmp(pos,Y)),Y(~missing & strcmp(pos,Y))))/sum(strcmp(pos,predictions));    %ppv
                %varargout{3} = sum(strcmp(predictions(strcmp(neg,Y)),Y(~missing & strcmp(neg,Y))))/sum(strcmp(neg,Y));  %specificity
                %varargout{4} = sum(strcmp(predictions(strcmp(neg,Y)),Y(~missing & strcmp(neg,Y))))/sum(strcmp(neg,predictions));    %npv
                %varargout{1} = sum(strcmp(predictions(strcmp(pos,Y)),Y(~missing & strcmp(pos,Y)))); %tp
                %varargout{2} = sum(~strcmp(predictions(strcmp(pos,Y)),Y(~missing & strcmp(pos,Y))));    %fn
                %varargout{3} = sum(strcmp(predictions(strcmp(neg,Y)),Y(~missing & strcmp(neg,Y)))); %tn
                %varargout{4} = sum(~strcmp(predictions(strcmp(neg,Y)),Y(~missing & strcmp(neg,Y))));    %fp
            %end
        end     %function oobpredict
        
        function Y = predict(forest,X,varargin)
            
            %Convert to double if not already
            if ~isa(X,'double')
                X = double(X);
            end
            
            if nargin == 3;
                Xtrain = varargin{1};
                if ~isa(Xtrain,'double')
                    Xtrain = double(Xtrain);
                end
            end
            
            if forest.Robust
                if nargin < 3
                    error('Training data is required as third input argument for predicting')
                end
                X = interpolate_rank(Xtrain,X);
            end
            n = size(X,1);
            predmat = NaN(n,forest.nTrees);
            YTree = cell(n,forest.nTrees);
            Tree = forest.Tree;
            if ~forest.RandomForest
                parfor i = 1:forest.nTrees
                    YTree(:,i) = rptreepredict(Tree{i},X);
                end
            else
                parfor i = 1:forest.nTrees
                    YTree(:,i) = eval(Tree{i},X);
                end
            end
            Labels = forest.classname;
            for j = 1:length(Labels)
                predmat(strcmp(YTree,Labels{j})) = j;
            end
            if length(Labels) > 2
                ensemblepredictions = mode(predmat,2);
                missing = isnan(ensemblepredictions);
                Y = Labels(ensemblepredictions(~missing));
            else
                Y = sum(predmat==2,2)./sum(~isnan(predmat),2);  %Y is fraction of trees that votes for positive class
            end
        end     %function predict
        
        function sp = db_sparsity(forest)
            %sparsity of decision boundary computed as sum #variables used
            %over all nodes
            
            sp = 0;
            for i = 1:forest.nTrees
                Tree = forest.Tree{i};
                if ~forest.RandomForest
                    internalnodes = Tree.node(Tree.var~=0);
                    for node = internalnodes'
                        sp = sp + sum(Tree.rpm{node}~=0);
                    end
                else
                    sp = sp + sum(Tree.var~=0);
                end
            end
        end
    end     %methods
end     %classdef
