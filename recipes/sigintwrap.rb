cookbook_file "#{Chef::Config[:file_cache]}/sigintwrap.c" do
  source 'sigintwrap.c'
end

execute 'compile sigintwrap' do
  command "gcc -o /usr/local/bin/sigintwrap #{Chef::Config[:file_cache]}/sigintwrap.c"
  not_if 'test -f /usr/local/bin/sigintwrap'
end
