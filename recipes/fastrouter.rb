include_recipe "uwsgi::default"


service "uwsgi_fastrouter" do
    provider provider Chef::Provider::Service::Upstart
    supports :restart => true, :start => true, :stop => true
end

router_socket = get_socket(node['uwsgi']['fast_router']['router_socket'])
subscription_socket = get_socket(node['uwsgi']['fast_router']['subscription_socket'])

node.set['uwsgi']['fast_router_socket'] = router_socket

unless Chef::Config[:solo]
  node.save
end

user = node['uwsgi']['user']
group = node['uwsgi']['user']
uwsgi_bin = node['uwsgi']['bin']
chmodsocket = node['uwsgi']['chmodsocket']

if node['uwsgi']['fastrouter']['init_style'] == 'runit'
  # Remove upstart version if it has already been configured
  service 'uwsgi_fastrouter' do
    provider provider Chef::Provider::Service::Upstart
    action [:stop, :disable]
    only_if 'test -f /etc/init/uwsgi_fastrouter.conf'
  end

  file '/etc/init/uwsgi_fastrouter.conf' do
    action :delete
    only_if 'test -f /etc/init/uwsgi_fastrouter.conf'
  end

  # Configure runit version
  runit_service 'uwsgi-fastrouter' do
    default_logger true
    options({
      'router_socket' => router_socket,
      'subscription_socket' => subscription_socket,
      'user' => node['uwsgi']['user'],
      'group' => node['uwsgi']['user'],
      'log_dir' => node['uwsgi']['log_dir'],
      'uwsgi_bin' => node['uwsgi']['bin'],
      'chmodsocket' => chmodsocket,
      'fastrouter_timeout' => node['uwsgi']['fastrouter']['timeout'],
      'stats_server' => node['uwsgi']['fastrouter']['stats_server'],
    })
  end
else
  template '/etc/init/uwsgi_fastrouter.conf' do
      source 'uwsgi_fastrouter.upstart.erb'
      owner node['uwsgi']['user']
      group node['uwsgi']['user']
      mode '0644'
      variables({
          'router_socket' => router_socket,
          'subscription_socket' => subscription_socket,
          'user' => node['uwsgi']['user'],
          'group' => node['uwsgi']['user'],
          'log_dir' => node['uwsgi']['log_dir'],
          'uwsgi_bin' => node['uwsgi']['bin'],
      })
      notifies :restart, "service[uwsgi_fastrouter]"
  end

  service 'uwsgi_fastrouter' do
      provider provider Chef::Provider::Service::Upstart
      action [:enable, :start]
  end
end
