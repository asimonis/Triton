function nn_ui_train_test_set_window(hObject,eventdata)

global REMORA

if ~isfield(REMORA.nn,'train_test_set')
    nn_ui_init_train_test_set
end

defaultPos = [0.35,.45,.3,.25];
initAxes = 0;
if isfield(REMORA.fig, 'nn')
    % check if the figure already exists. If so, don't move it.
    if isfield(REMORA.fig.nn, 'nn_train_test_set') && isvalid(REMORA.fig.nn.nn_train_test_set.figH)
        defaultPos = get(REMORA.fig.nn.nn_train_test_set.figH,'Position');
    else
        initAxes = 1;
    end
else 
    initAxes = 1;
end



if initAxes
    REMORA.fig.nn.nn_train_test_set.figH = figure;
    
    set(REMORA.fig.nn.nn_train_test_set.figH,...
        'Units','normalized',...
        'ToolBar', 'none',...
        'MenuBar','none',...
        'NumberTitle','off','Name',...
        'Neural Net Tool - v1.0: Train/Test Set options',...
        'Position',defaultPos,...
        'Visible','on');
end

clf

% Title
labelStr = 'Train and Test Set Options';
btnPos=[0 .9 1 .1];
REMORA.fig.nn.nn_train_test_set.headText = uicontrol(REMORA.fig.nn.nn_train_test_set.figH, ...
    'Style','text', ...
    'Units','normalized', ...
    'Position',btnPos, ...
    'String',labelStr, ...
    'FontSize',12,...
    'FontUnits','normalized', ...
    'FontWeight','bold',...
    'Visible','on');  %'BackgroundColor',bgColor3,...

btnPos=[0 .8 1 .1];
REMORA.fig.nn.nn_train_test_set.backgrnd = uicontrol(REMORA.fig.nn.nn_train_test_set.figH, ...
    'Style','text', ...
    'Units','normalized', ...
    'HorizontalAlignment','Left',...
    'Position',btnPos, ...
    'BackgroundColor',[.68,.92,.1],...
    'FontSize',11,...
    'FontUnits','normalized', ...
    'FontWeight','bold',...
    'Visible','on');  

labelStr = '  Data Type: ';
btnPos=[0.03 .8 .4 .08];
REMORA.fig.nn.nn_train_test_set.headText = uicontrol(REMORA.fig.nn.nn_train_test_set.figH, ...
    'Style','text', ...
    'Units','normalized', ...
    'HorizontalAlignment','Left',...
    'Position',btnPos, ...
    'BackgroundColor',[.68,.92,.1],...
    'String',labelStr, ...
    'FontSize',11,...
    'FontUnits','normalized', ...
    'FontWeight','bold',...
    'Visible','on');  

%% Bin Level Text
labelStr = 'Bin Level';
btnPos=[.3 .8 .25 .1];
REMORA.fig.nn.nn_train_test_set.binCheckTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','checkbox',...
    'Units','normalized',...
    'Position',btnPos,...
    'HorizontalAlignment','Right',...
    'BackgroundColor',[.68,.92,.1],...
    'String',sprintf(labelStr,'Interpreter','tex'),...
    'FontWeight','bold',...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on',...
    'Callback',{@nn_ui_train_test_set_control,'setBinLevel'});

%% Click Level Text
labelStr = 'Detection Level';
btnPos=[.6 .8 .25 .1];
REMORA.fig.nn.nn_train_test_set.clickCheckTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','checkbox',...
    'Units','normalized',...
    'Position',btnPos,...
    'HorizontalAlignment','Right',...
    'BackgroundColor',[.68,.92,.1],...
    'String',sprintf(labelStr,'Interpreter','tex'),...
    'FontWeight','bold',...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on',...
    'Callback',{@nn_ui_train_test_set_control,'setClickLevel'});
%% Input Folder Text
labelStr = 'Input Base Folder';
btnPos=[.02 .63 .25 .1];
REMORA.fig.nn.nn_train_test_set.inDirTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','text',...
    'Units','normalized',...
    'Position',btnPos,...
    'HorizontalAlignment','Right',...
    'String',sprintf(labelStr,'Interpreter','tex'),...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on');

btnPos=[.3 .67 .6 .08];
REMORA.fig.nn.nn_train_test_set.inDirEdTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','edit',...
    'Units','normalized',...
    'Position',btnPos,...
    'BackgroundColor','white',...
    'HorizontalAlignment','left',...
    'String',REMORA.nn.train_test_set.inDir,...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on',...
    'Callback',{@nn_ui_train_test_set_control,'setInDir'});

%% Output Folder Text
labelStr = 'Output Folder';
btnPos=[.02 .53 .25 .1];
REMORA.fig.nn.nn_train_test_set.saveDirTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','text',...
    'Units','normalized',...
    'Position',btnPos,...
    'HorizontalAlignment','Right',...
    'String',sprintf(labelStr,'Interpreter','tex'),...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on');

btnPos=[.3 .57 .6 .08];
REMORA.fig.nn.nn_train_test_set.saveDirEdTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','edit',...
    'Units','normalized',...
    'Position',btnPos,...
    'BackgroundColor','white',...
    'HorizontalAlignment','left',...
    'String',REMORA.nn.train_test_set.saveDir,...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on',...
    'Callback',{@nn_ui_train_test_set_control,'setSaveDir'});

%% Output File Name Text
labelStr = 'Output File Name';
btnPos=[.02 .43 .25 .1];
REMORA.fig.nn.nn_train_test_set.saveNameTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','text',...
    'Units','normalized',...
    'Position',btnPos,...
    'HorizontalAlignment','Right',...
    'String',sprintf(labelStr,'Interpreter','tex'),...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on');

btnPos=[.3 .47 .3 .08];
REMORA.fig.nn.nn_train_test_set.saveNameEdTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','edit',...
    'Units','normalized',...
    'Position',btnPos,...
    'BackgroundColor','white',...
    'HorizontalAlignment','left',...
    'String',REMORA.nn.train_test_set.saveName,...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on',...
    'Callback',{@nn_ui_train_test_set_control,'setSaveName'});

% trainPercent
%% Training Percentage Text
labelStr = '%% of Dataset for Training';
btnPos=[.02 .33 .25 .1];
REMORA.fig.nn.nn_train_test_set.trainPercTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','text',...
    'Units','normalized',...
    'Position',btnPos,...
    'HorizontalAlignment','Right',...
    'String',sprintf(labelStr,'Interpreter','tex'),...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on');

btnPos = [.3 .37 .1 .08];
REMORA.fig.nn.nn_train_test_set.trainPercEdTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','edit',...
    'Units','normalized',...
    'Position',btnPos,...
    'BackgroundColor','white',...
    'HorizontalAlignment','center',...
    'string',REMORA.nn.train_test_set.trainPerc,...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on',...
    'Callback',{@nn_ui_train_test_set_control,'setTrainPerc'});


%% Number of training examples 
labelStr = 'Training Set Size';
btnPos=[.45 .33 .17 .1];
REMORA.fig.nn.nn_train_test_set.trainSizeTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','text',...
    'Units','normalized',...
    'Position',btnPos,...
    'HorizontalAlignment','Right',...
    'String',sprintf(labelStr,'Interpreter','tex'),...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on');

btnPos = [.65 .37 .1 .08];
REMORA.fig.nn.nn_train_test_set.trainSizeEdTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','edit',...
    'Units','normalized',...
    'Position',btnPos,...
    'BackgroundColor','white',...
    'HorizontalAlignment','center',...
    'string',REMORA.nn.train_test_set.trainSize,...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on',...
    'Callback',{@nn_ui_train_test_set_control,'setTrainSize'});


%% Number of training examples 
labelStr = 'Bout Gap (minutes)';
btnPos=[.02 .23 .25 .1];
REMORA.fig.nn.nn_train_test_set.boutGapTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','text',...
    'Units','normalized',...
    'Position',btnPos,...
    'HorizontalAlignment','Right',...
    'String',sprintf(labelStr,'Interpreter','tex'),...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on');

btnPos = [.3 .27 .1 .08];
REMORA.fig.nn.nn_train_test_set.boutGapEdTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','edit',...
    'Units','normalized',...
    'Position',btnPos,...
    'BackgroundColor','white',...
    'HorizontalAlignment','center',...
    'string',REMORA.nn.train_test_set.boutGap,...
    'FontSize',10,...
    'FontUnits','normalized', ...
    'Visible','on',...
    'Callback',{@nn_ui_train_test_set_control,'setBoutGap'});

REMORA.fig.nn.nn_train_test_set.boutGapEdTxt = uicontrol(REMORA.fig.nn.nn_train_test_set.figH,...
    'Style','pushbutton',...
    'String','Run',...
    'Units','normalized',...
    'Position',[.3 .07 .4 .1],...
    'HandleVisibility','off',...
    'FontSize',10,...
    'Callback',{@nn_ui_train_test_set_control,'Run'});

function nn_ui_init_train_test_set
global REMORA

REMORA.nn.train_test_set.inDir = '';
REMORA.nn.train_test_set.saveDir = '';
REMORA.nn.train_test_set.saveName = '';
REMORA.nn.train_test_set.trainPerc = num2str(66);
REMORA.nn.train_test_set.trainSize = num2str(1000);
REMORA.nn.train_test_set.boutGap = num2str(15);