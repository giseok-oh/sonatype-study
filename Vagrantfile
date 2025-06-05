# -*- mode: ruby -*-
# vi: set ft=ruby :
# Virtual Machines
VM_LIST = {
  "iq" => {
    :ip => "192.168.56.10",
    :cpus => 2,
    :memory => 8_192,
    :disksize => "64GB"
  },
  "nexus" => {
    :ip => "192.168.56.11",
    :cpus => 8,
    :memory => 16_384,
    :disksize => "64GB"
  }
}

Vagrant.configure("2") do |config|
  # Get Virtual Machine names
  vm_names = VM_LIST.keys

  # Get IP list
  ips = VM_LIST.map { |_, config| config[:ip] }

  # Define groups
  group_hash = vm_names.each_with_object({}) do |hostname, hash|
    hash["group_#{hostname}"] = [hostname]
  end
  group_hash["all:children"] = vm_names

  # Define Virtual Machines
  VM_LIST.each do |hostname, opts|
    config.vm.define hostname do |node|
      # Default box disk size: 64GB
      node.vm.box = "bento/rockylinux-8.10"
      node.vm.hostname = hostname
      node.vm.network :private_network, ip: opts[:ip]
      node.vm.disk :disk, size: opts[:disksize], primary: true
      node.vm.synced_folder '.', '/vagrant', disabled: true

      if hostname == "iq"
        node.vm.network "forwarded_port", guest: 8070, host: 8070, protocol: "tcp"
        node.vm.network "forwarded_port", guest: 8071, host: 8071, protocol: "tcp"
      elsif hostname == "nexus"
        node.vm.network "forwarded_port", guest: 8081, host: 8081, protocol: "tcp"
      end

      node.vm.provider "virtualbox" do |vbox|
        vbox.gui = false
        vbox.cpus = opts[:cpus]
        vbox.memory = opts[:memory]
      end
    end
  end

  # SSH settings
  config.vm.provision "shell", path: "./provisioning/shell/ssh.sh", args: ips

  # Install prerequisites
  config.vm.provision "shell", path: "./provisioning/shell/prerequisites.sh"
  
  # Run playbook
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "./provisioning/playbooks/playbook.yml"
    ansible.groups = group_hash
    ansible.extra_vars = {
      ansible_python_interpreter: "/usr/bin/python3"
    }
    ansible.compatibility_mode = "2.0"
  end
end