#!/usr/bin/ruby

if node[:dir_user_home].nil? || node[:dir_user_home].empty?
    dir_user_home = '/home/ubuntu'
else
    dir_user_home = node[:dir_user_home]
    unless dir_user_home.end_with?("/") then
        dir_user_home << '/'
    end
end

if node[:dir_tmp].nil? || node[:dir_tmp].empty?
    dir_tmp = '/tmp'
else
    dir_tmp = node[:dir_tmp]
    if dir_tmp.end_with?("/") then
        dir_tmp = dir_tmp.slice(0, dir_tmp.length - 1)
    end
end

if node[:h2o][:version].nil? || node[:h2o][:version].empty?
    h2o_version = '2.0.0'
else
    h2o_version = node[:h2o][:version]
end

if node[:h2o][:user].nil? || node[:h2o][:user].empty?
    h2o_user = 'nobody'
else
    h2o_user = node[:h2o][:user]
end

# h2o is not used group

if node[:h2o][:pid].nil? || node[:h2o][:pid].empty?
    h2o_pid = '/var/run/h2o/h2o.pid'
else
    h2o_pid = node[:h2o][:pid]
end

puts "h2o: dir_user_home: #{dir_user_home}"
puts "h2o: dir_tmp: #{dir_tmp}"
puts "h2o: build & install #{h2o_version} for Ubuntu/Trusty (use 'service' command)"
puts "h2o: exec user: #{h2o_user}"
puts "h2o: pid: #{h2o_pid}"

%w(cmake g++ libcurl4-openssl-dev libcrypto++-dev).each do |pkg|
    package pkg
end

execute 'build & install h2o web server' do
    command <<-"EOH"
cd #{dir_tmp}
wget -O h2o-#{h2o_version}.tar.gz https://github.com/h2o/h2o/archive/v#{h2o_version}.tar.gz
tar zxvf h2o-#{h2o_version}.tar.gz
cd h2o-#{h2o_version}
cmake -DWITH_BUNDLED_SSL=on .
make
make install
mkdir -p /var/log/h2o
mkdir -p /etc/h2o
EOH
    not_if "h2o -v 2>&1 |grep #{h2o_version}"
end

remote_file '/etc/h2o/h2o.conf' do
    source 'files/h2o.conf'
    not_if 'ls -la /etc/h2o |grep h2o.conf'
end

execute 'setting h2o.conf (user)' do
    command <<-"EOH"
sed -i 's%user: www-data%user: #{h2o_user}%' /etc/h2o/h2o.conf
EOH
    not_if "cat /etc/h2o/h2o.conf |grep #{h2o_user}"
end

execute 'setting h2o.conf (pid)' do
    command <<-"EOH"
sed -i 's%/var/run/h2o/h2o\.pid%#{h2o_pid}%' /etc/h2o/h2o.conf
EOH
    not_if "cat /etc/h2o/h2o.conf |grep #{h2o_pid}"
end

directory '/usr/lib/systemd/system' do
    not_if 'ls -la /usr/lib/systemd |grep system'
end

remote_file '/usr/lib/systemd/system/h2o.service' do
    mode '644'
    source 'files/h2o.service'
    not_if 'ls -la /usr/lib/systemd/system/h2o.service | grep h2o'
end

remote_file '/etc/init.d/h2o' do
    mode '755'
    source 'files/h2o.init.d'
    not_if 'ls -la /etc/init.d |grep h2o'
end

execute 'setting init.d/h2o (pid)' do
    command <<-"EOH"
cd #{dir_tmp}
sed -i 's%/var/run/h2o/h2o\.pid%#{h2o_pid}%' /etc/init.d/h2o
EOH
    not_if "cat /etc/init.d/h2o |grep #{h2o_pid}"
end

execute 'copy share/h2o/*' do
    command <<-"EOH"
cd #{dir_tmp}
cp -r ./share/h2o /usr/local/share/h2o
EOH
    not_if 'ls -la /usr/local/share |grep h2o'
end

directory '/usr/local/share/h2o' do
    not_if 'ls -la /usr/local/share |grep h2o'
end

execute 'setting ca-bundle.crt' do
    command <<-"EOH"
cd #{dir_tmp}/share/h2o
cp ca-bundle.crt /usr/local/share/h2o/ca-bundle.crt
EOH
    not_if "cat /etc/init.d/h2o |grep #{h2o_pid}"
end

service 'h2o' do
    action :start
    only_if 'service h2o status 2>&1 |grep stopped'
end

execute 'h2o: auto service start settings' do
    command <<-"EOH"
sysv-rc-conf h2o on
EOH
    not_if 'sysv-rc-conf --list |grep h2o.*2:on'
end
