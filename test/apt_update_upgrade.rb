Vagrant.configure('2') do |c|
  c.vm.provision 'shell', inline: <<-SHELL
      sudo apt -y -qq update
      sudo apt -y -qq upgrade
    SHELL
end
