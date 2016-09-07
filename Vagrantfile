VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "puppetlabs/ubuntu-12.04-64-puppet"
  config.vm.network "private_network", ip: "10.0.0.100"
  config.vm.synced_folder ".", "/usr/bin/digcolproc"
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--cpus", 2]
    v.customize ["modifyvm", :id, "--memory", "2048"]
  end

  config.vm.provision 'shell', path: 'puppet.sh', args: ['ubuntu-12', 'test', '1']
end
