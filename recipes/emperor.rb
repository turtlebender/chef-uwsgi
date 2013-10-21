include_recipe "uwsgi::default"

begin
  service "uwsgi" do
    provider Chef::Provider::Service::Upstart
    action :stop, :disable
  end
rescue
  # do nothing
end

%w{ app_path app_socket_dir log_dir }.each do |dirvar|
  directory node["uwsgi"]['emperor'][dirvar] do
    recursive true
    owner node["uwsgi"]["user"]
    group node["uwsgi"]["user"]
  end
end

template_vars = {
  :vassal_dir => node["uwsgi"]["app_path"],
  :log_dir => node["uwsgi"]["log_dir"],
  :broodlord_count => node["uwsgi"]["broodlord_count"],
  :user => node["uwsgi"]["user"],
  :group => node["uwsgi"]["user"],
  :uwsgi_bin => node['uwsgi']['bin'],
  :stats_server => node['uwsgi']['emperor']['stats_server'],
}


if node['uwsgi']['emperor']['init_style'] == 'runit'
  # Remove the upstart version if it was already installed
  service 'uwsgi_emperor' do
    provider Chef::Provider::Service::Upstart
    action [:stop, :disable]
    only_if 'test -f /etc/init/uwsgi_emperor.conf'
  end

  file '/etc/init/uwsgi_emperor.conf' do
    action :delete
    only_if 'test -f /etc/init/uwsgi_emperor.conf'
  end

  # Configure the runit version
  runit_service 'uwsgi-emperor' do
    options({
      'vassal_dir' => node["uwsgi"]["app_path"],
      'log_dir' => node["uwsgi"]["log_dir"],
      'broodlord_count' => node["uwsgi"]["broodlord_count"],
      'user' => node["uwsgi"]["user"],
      'group' => node["uwsgi"]["user"],
      'uwsgi_bin' => node['uwsgi']['bin'],
      'stats_server' => node['uwsgi']['emperor']['stats_server'],
    })
  end
else
  template "/etc/init/uwsgi_emperor.conf" do
    source "uwsgi_emperor.upstart.erb"
    mode "0644"
    variables(template_vars)
    notifies :restart, resources("service[uwsgi_emperor]")
  end

  service "uwsgi-emperor" do
    provider Chef::Provider::Service::Upstart
    action [:enable, :start]
  end
end
