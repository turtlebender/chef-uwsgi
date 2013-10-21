def get_socket(socket_name)
    if socket_name.include?(":") || socket_name.start_with?('/')
        return socket_name
    else
        return "#{node['uwsgi']['socket_path']}/#{socket_name}"
    end
end
