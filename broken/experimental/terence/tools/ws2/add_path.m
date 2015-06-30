function add_path(root_dir)

app_path=sprintf('%s\\src\\app',root_dir);
bin_path=sprintf('%s\\bin',root_dir);
gui_path=sprintf('%s\\src\\gui',root_dir);
neighbor_est_path=sprintf('%s\\src\\neighbor_est',root_dir);
parent_selection_path=sprintf('%s\\src\\parent_selection',root_dir);
model_path=sprintf('%s\\src\\model',root_dir);
radio_path=sprintf('%s\\src\\radio',root_dir);
report_path=sprintf('%s\\src\\report',root_dir);
simulator_path=sprintf('%s\\src\\simulator',root_dir);
time_daemon_path=sprintf('%s\\src\\time_daemon',root_dir);

path(time_daemon_path,path);
path(simulator_path,path);
path(report_path,path);
path(model_path,path);
path(radio_path,path);
path(parent_selection_path,path);
path(neighbor_est_path,path);
path(gui_path,path);
path(app_path,path);
path(bin_path,path);
