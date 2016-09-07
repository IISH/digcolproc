VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.hostname=ENV['USER'] + '-digcolproc.sandbox.local'
  config.vm.box = 'puppetlabs/ubuntu-12.04-64-puppet'
  config.vm.network "private_network", ip: '10.0.0.100'
  config.vm.synced_folder '.', '/usr/bin/digcolproc'
  config.vm.provider 'virtualbox' do |v|
    v.customize ['modifyvm', :id, '--cpus', 2]
    v.customize ['modifyvm', :id, '--memory', 2048]
  end
  config.vm.provision 'shell', path: 'puppet.sh', args: ['ubuntu-12', 'test', '1']
  config.vm.network "forwarded_port", guest: 21, host: 21, auto_correct: true
  config.vm.network "forwarded_port", guest: 8080, host: 8080, auto_correct: true
  config.vm.network "forwarded_port", guest: 3306, host: 3306, auto_correct: true
end
