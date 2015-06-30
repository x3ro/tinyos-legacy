function output=time_series_analysis(varargin)
output = feval(varargin{:});

function output = time_series_tree_established(time_series)
global protocol_params;
established_time = +Inf;
index=[];
for i=1:length(time_series.routes)
    last_index = index;
    index=find(time_series.routes(i,2:length(time_series.routes(i,:)))==protocol_params.invalid_parent);
    if isempty(index)
        output.established_time = time_series.simulation_time(i)/100000;
        output.last_nodes = last_index;
        break;
    end    
end

function time_series_actual_link=time_series_actual_link_cal(time_series)
global sim_params protocol_params radio_params;
time_series_actual_link=[];
for steps=1:length(time_series.simulation_time);    
    parents = time_series.routes(steps,:);
    for i=1:sim_params.total_mote
        if(parents(i) == protocol_params.invalid_parent)
            result(i) = -1;
        else
            result(i) = radio_params.prob_table(i, parents(i));
        end
    end
    time_series_actual_link = [time_series_actual_link; result];
end

function time_series_actual_path=time_series_actual_path_cal(time_series)
global sim_params protocol_params
time_series_actual_path=[];
for steps=1:length(time_series.simulation_time);
    defined = zeros(1, sim_params.total_mote);
    defined(sim_params.base_station) = 1;
    parents = time_series.routes(steps,:);
    result = ones(1, sim_params.total_mote);
    % find invalid parent
    invalid_parent_index = find(parents == protocol_params.invalid_parent);
    result(invalid_parent_index) = 0;
    result(sim_params.base_station) = 1;
    defined(invalid_parent_index) = 1;
    clean_visited = zeros(1, sim_params.total_mote);
    for i = 1:sim_params.total_mote
        visited = clean_visited;
        [path_est, defined, parents, result, visited] = calculate_actual_path_helper(i, defined, parents, result, visited);
    end
    time_series_actual_path = [time_series_actual_path; result];
end

function [path_est, defined, parents, result, visited] = calculate_actual_path_helper(current, defined, parents, result, visited)
global sim_params radio_params
if defined(current)
    path_est = result(current);
elseif visited(current)
    % cycle!
    result(current) =  0;
    defined(current) = 1;
    path_est = 0;
else
    visited(current) = 1;
    [parent_est, defined, parents, result, visited] = calculate_actual_path_helper(parents(current), defined, parents, result, visited);
    defined(current) = 1;
    result(current) = radio_params.prob_table(current, parents(current)) * parent_est;
    path_est = result(current);
end


function void = time_series_link_est_err(time_series)
time_series.actual_link = time_series_actual_link_cal(time_series);
err = abs(time_series.link_est - time_series.actual_link)./time_series.actual_link;
 
mean_err=[];
sd_err=[];
for i=1:size(time_series.simulation_time,1)
    cur_err = err(i,find(err(i,:)>0));
    if ~isempty(cur_err)
        mean_err = [mean_err; [time_series.simulation_time(i)/100000, mean(cur_err)]];
        sd_err = [sd_err; [time_series.simulation_time(i)/100000, std(cur_err)]];
    end
end
hold on;
plot(mean_err(:,1), mean_err(:,2)*100 );
plot(sd_err(:,1), sd_err(:,2)*100,'r' );
hold off;
axis([0 max(time_series.simulation_time)/100000 0 100])
title('Link Estimation Error');
xlabel('Time(s)');
ylabel('%');
legend('Mean Percent Error','SD');
void = -1;



function void = time_series_path_est_err(time_series)
actual_path = time_series_actual_path_cal(time_series);
err = abs(time_series.path_est - actual_path)./actual_path;
 
mean_err=[];
sd_err=[];
for i=1:size(time_series.simulation_time,1)
    cur_err = err(i,find(err(i,:)>0));
    if ~isempty(cur_err)
        mean_err = [mean_err; [time_series.simulation_time(i)/100000, mean(cur_err)]];
        sd_err = [sd_err; [time_series.simulation_time(i)/100000, std(cur_err)]];
    end
end
hold on;
plot(mean_err(:,1), mean_err(:,2)*100 );
plot(sd_err(:,1), sd_err(:,2)*100,'r' );
hold off;
axis([0 max(time_series.simulation_time)/100000 0 100])
title('Path Estimation Error');
xlabel('Time(s)');
ylabel('%');
legend('Mean Percent Error','SD');
void = -1;



% the following code does not work anymore, alec, please verify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function void = time_series_link_est_err(time_series, node)
% err = abs(time_series.link_est - time_series.actual_link)./time_series.actual_link;
% for i=2:size(err,2)
%     plot(time_series.link_est(:,1),err(:,i));
%     hold on;
% end
% axis([0 max(time_series.link_est(:,1)) 0 1]);
% mean_err=[];
% sd_err=[];
% for i=2:size(err,1)
%     cur_err = err(i,find(err(i,:)>0));
%     if ~isempty(cur_err)
%         mean_err = [mean_err; [time_series.link_est(i,1), mean(cur_err)]];
%         sd_err = [sd_err; [time_series.link_est(i,1), std(cur_err)]];
%     end
% end
% hold off;
% figure;
% errorbar(mean_err(:,1),mean_err(:,2),sd_err(:,2));
% mean_err
% void = -1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
