% eccv_analysis

dataset = 'sunrgbd';

input_layout2d = '../cvpr17data/output-cvpr17sun-v1-5/';
scorepath = '../cvpr17evaldata/ablations-cvpr17sun-5-5/';
scorepath = '../cvpr17evaldata/output-cvpr17sun-v1-5-rcnnsoft/';

outputdir = 'cvpr-top5-bbox-results-s5';
if ~exist(outputdir, 'dir')
    mkdir(outputdir);
end

filelist = dir(fullfile(input_layout2d, '*'));
filelist = {filelist(:).name};

use_thresh = false;
thresh = 0.5;

detection_dir = fullfile('detection-box', dataset);
detection.dataset = 'sunrgbd';
if ~exist('detection', 'var') || ~strcmp(detection.dataset, dataset)
detection = load(fullfile(detection_dir, 'detection_test.mat'));
detection.dataset = dataset;
end

imagepath_det = '/Users/ang/projects/layout3d/sunrgbd-dataset/sunrgbd_fastrcnn/detection-test-vis';
imagepath_gt = '/Users/ang/projects/layout3d/sunrgbd-dataset/SUNRGBDtoolbox/vis';
imagepath = '/Users/ang/projects/layout3d/sunrgbd-dataset/SUNRGBDtoolbox/gtimgs';

match_config = [];
match_config.n_scale = 5;
match_config.scales = 0.5:1/match_config.n_scale:1;
match_config.n_x = 10;
match_config.n_y = 10;
for ii = 1:length(filelist)
    if filelist{ii}(1) == '.'
        continue;
    end
imageid = filelist{ii};
if exist(fullfile(outputdir, imageid), 'dir')
    continue;
end

inputmat = fullfile(input_layout2d, imageid, 'layout2d.mat');
if ~exist(inputmat, 'file')
    continue;
end

clear layout2d
load(inputmat, 'layout2d');
% imageid = '2-00054';
index = strfind(imageid, '-');
if isempty(index)
    gtid = str2num(imageid);
else
    gtid = str2num(imageid(index+1:end));
end
    
if ~exist(fullfile(scorepath, [imageid, '.mat']), 'file')
    continue;
end
scores = load(fullfile(scorepath, [imageid, '.mat']));
scores = max(scores.final_score, [], 2);
bar(scores);

[~, rank_id] = sort(scores, 'descend');
[~, rank] = sort(rank_id);

% print gt score
gtscore = scores(gtid);
fprintf(1, 'GT (#%d) score: %f\n', gtid, gtscore);

% print gt rank
gtrank = rank(gtid);
fprintf(1, 'GT (#%d) rank: %d\n', gtid, gtrank);

if gtrank > 5
    continue
end

% show top 1 image
for topk = 1:5
top_id = rank_id(topk);
det_image = imread(fullfile(imagepath_det, num2str(top_id, 'vis_%05d.jpg')));
gt_image = imread(fullfile(imagepath_gt, num2str(top_id, 'vis_%05d.jpg')));
det_image_gt = imread(fullfile(imagepath_det, num2str(gtid, 'vis_%05d.jpg')));

k = top_id;

rgbpath = fullfile(imagepath, num2str(k, '%05d.jpg'));

I = imread(rgbpath);
det = detection.detection{k};
index = det.bg_conf < det.conf;
if use_thresh
    index = index & det.conf > thresh;
    det.conf(:) = 1.0;
end
det = det(index, :);


opt = [];
opt.score = -inf;
for i = 1:length(layout2d)
    layout = layout2d{i};
    tmp = layout.Y1;
    layout.Y1 = -layout.Y2;
    layout.Y2 = -tmp;
    layout = normalize_composition(layout);
    [score, s, x, y, iou, conf] = exhaustive_match(layout, det, match_config);
%     S = [S, max(score)];
    if max(score) > max(opt.score)
        opt.score = score;
        opt.s = s;
        opt.x = x;
        opt.y = y;
        opt.iou = iou;
        opt.conf = conf;
        opt.layout = layout;
    end
end

score = opt.score;
s = opt.s;
x = opt.x;
y = opt.y;
layout = opt.layout;
    h = imshow(I);
    [maxscore, index] = max(score);
    iou = opt.iou(:, index);
    conf = opt.conf(:, index);
    % compute matched layout
    picked = false(size(det,1),1);
    matchedlayout = {};
    for j = 1:size(layout, 1)
        classname = layout.classname{j};
        bb = layout(j, 2:end);
        bbox = [bb.X1, bb.Y1, bb.X2-bb.X1, bb.Y2-bb.Y1] * s(index) + [x(index), y(index), 0, 0];
        maxiou = 0;
        bestmatch = [];
        bestmatch.score = 0;
        bestmatch.k = 0;
        bestmatch.classname = classname;
        for k = 1:size(det, 1)
            dd = det(k,:);
            if picked(k) || ~strcmp(dd.classname, classname)
                continue
            end
            detbbox = [dd.X1, dd.Y1, dd.X2-dd.X1, dd.Y2-dd.Y1];
            myiou = computeIOU(bbox, detbbox);
            ss = myiou * dd.conf;
            if ss > bestmatch.score
                bestmatch.detbbox = detbbox;
                bestmatch.iou = myiou;
                bestmatch.conf = det.conf(k);
                bestmatch.score = ss;
                bestmatch.k = k;
            end
        end
%         assert(bestmatch.k);
        if bestmatch.k > 0
        picked(bestmatch.k) = true;
        else
            bestmatch.detbbox = bbox;
        end
        matchedlayout{j} = bestmatch;
    end
    for j = 1:size(layout, 1)
        classname = layout.classname{j};
        bb = layout(j, 2:end);
        bbox = [bb.X1, bb.Y1, bb.X2-bb.X1, bb.Y2-bb.Y1] * s(index) + [x(index), y(index), 0, 0];
%                 bbox = [bb.X1, bb.Y1, bb.X2-bb.X1, bb.Y2-bb.Y1];
        str = sprintf('%s\n(iou:%.2f,conf:%.2f)', classname, iou(j), conf(j));
        str = classname;
%         plotbbox_with_classname_only(bbox, [], [0, 0.9, 0], 2);
%         hold on;
        matchbbox = matchedlayout{j};
        if matchbbox.k > 0
            plotbbox_with_classname_only(matchbbox.detbbox, str, 'g', 2);
        else
            plotbbox_with_classname_only(matchbbox.detbbox, str, 'r', 2);
        end
        hold on;
    end
    hold off;
    suffix = '';
    if top_id == gtid
        suffix = '-gt';
        sz = size(I);
%         rectangle('Position', [1 1 sz(2)-1 sz(1)-1], 'edgecolor', [0 .618 0], 'linewidth', 10);
    end
    outputpath = fullfile(outputdir, imageid, [num2str(topk, '%d') suffix '.eps']);
    if ~exist(fullfile(outputdir, imageid), 'dir')
        mkdir(fullfile(outputdir, imageid));
    end
%     title(num2str(maxscore, 'Score = %.2f'));
    saveas(h, outputpath, 'ps2c');
    
end
end