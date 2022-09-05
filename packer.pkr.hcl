packer {
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/virtualbox"
    }
    ansible = {
      version = ">= 1.0.3"
      source  = "github.com/hashicorp/ansible"
    }
  }    
}

variable "vagrant_box_name" {
  type    = string
  default = "${env("VAGRANT_BOX_NAME")}"
}

variable "vagrant_box_version" {
  type    = string
  default = "${env("VAGRANT_BOX_VERSION")}"
}

variable "vagrant_box_description" {
  type    = string
  default = "${env("VAGRANT_BOX_DESCRIPTION")}"
}

variable "vagrantcloud_user" {
  type    = string
  default = "${env("VAGRANTCLOUD_USER")}"
}

variable "vagrantcloud_token" {
  type    = string
  default = "${env("VAGRANTCLOUD_TOKEN")}"
}

source "virtualbox-iso" "ubuntu22-dev" {
  vm_name = "ubuntu22-dev"

  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot",
    "<enter>"
  ]

  boot_wait            = "5s"
  disk_size            = 10240
  guest_additions_mode = "upload"
  guest_os_type        = "Ubuntu_64"
  headless             = "true"

  virtualbox_version_file = ".vbox_version"
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--memory", "8192"],
    ["modifyvm", "{{ .Name }}", "--cpus", "2"]
  ]

  http_directory = "http"

  iso_checksum = "sha256:10f19c5b2b8d6db711582e0e27f5116296c34fe4b313ba45f9b201a5007056cb"
  iso_urls     = ["iso/ubuntu-22.04.1-live-server-amd64.iso", "https://releases.ubuntu.com/jammy/ubuntu-22.04.1-live-server-amd64.iso"]

  output_filename = "vagrant"

  ssh_handshake_attempts = 5
  ssh_username           = "vagrant"
  ssh_password           = "vagrant"
  ssh_port               = 22
  ssh_read_write_timeout = "300s"
  ssh_wait_timeout       = "90m"
  ssh_timeout            = "90m"

  shutdown_command = "sudo systemctl poweroff"
}

build {
  # Builder defined above
  sources = ["virtualbox-iso.ubuntu22-dev"]

  # Copy common files to host
  provisioner "file" {
    source      = "common/files"
    destination = "/tmp"
  }

  # Copy ansible collections
  provisioner "file" {
    source      = "ansible/collections.yml"
    destination = "/tmp/"
  }

  # Run setup.sh
  provisioner "shell" {
    script          = "scripts/setup.sh"
    execute_command = "echo vagrant | {{.Vars}} sudo -S -E bash '{{.Path}}'"
  }

  # Install ansible
  provisioner "shell" {
    script          = "scripts/ansible.sh"
    execute_command = "echo vagrant | {{.Vars}} sudo -S -E bash '{{.Path}}'"
  }

  # Install ansible collections
  provisioner "shell" {
    inline = [
      "ansible-galaxy collection install -r /tmp/collections.yml"
    ]
  }

  # Run ansible playbook
  provisioner "ansible-local" {
    galaxy_file       = "ansible/requirements.yml"
    galaxy_roles_path = "/home/vagrant/.ansible/roles"
    playbook_dir      = "ansible"
    playbook_file     = "ansible/main.yml"
  }

  # Run cleanup script
  provisioner "shell" {
    script          = "scripts/cleanup.sh"
    execute_command = "echo vagrant | {{.Vars}} sudo -S -E bash '{{.Path}}'"
  }

  post-processors {
    post-processor "vagrant" {
      compression_level = 9
      output            = "build/${var.vagrant_box_name}-${var.vagrant_box_version}.box"
    }

    post-processor "vagrant-cloud" {
      access_token        = "${var.vagrantcloud_token}"
      version             = "${var.vagrant_box_version}"
      version_description = "${var.vagrant_box_description}"
      box_tag             = "${var.vagrantcloud_user}/${var.vagrant_box_name}"
      no_release          = true
      keep_input_artifact = true
    }
  }
}
