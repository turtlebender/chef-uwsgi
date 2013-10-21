#
# Cookbook Name:: uwsgi
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "build-essential"
include_recipe "xml"
include_recipe "python"

cookbook_file "#{Chef::Config[:file_cache]}/sigintwrap.c" do
    source 'sigintwrap.c'
end

execute 'compile sigintwrap' do
    command "gcc -o /usr/local/bin/sigintwrap #{Chef::Config[:file_cache]}/sigintwrap.c"
      not_if 'test -f /usr/local/bin/sigintwrap'
end

libyaml = value_for_platform(
  ["centos", "redhat", "suse", "fedora", "scientific", "amazon"] => {
    "default" => "libyaml-devel"
  },
  ["ubuntu", "debian"] => {
    "default" => "libyaml-dev"
  }
)

package libyaml do
  action :install
end

user node["uwsgi"]["user"]

python_pip "uwsgi" do
  action :install
end

%w{log_dir socket_dir}.each do |attr|
  directory node['uwsgi'][attr] do
    recursive true
    owner "uwsgi"
    group "uwsgi"
    mode 0775
  end
end
