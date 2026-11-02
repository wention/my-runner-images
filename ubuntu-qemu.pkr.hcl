packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = ">= 1.0.0"
    }
  }
}

# 定义 QEMU 构建源
source "qemu" "ubuntu" {
  iso_url            = "/home/wention/Downloads/noble-server-cloudimg-amd64.img"
  iso_checksum       = "none"
  output_directory   = "output_builds"
  disk_image         = true
  use_backing_file   = true

  # 定义虚拟机的硬件配置
  machine_type       = "q35"
  cpus               = 4  # CPU 数量
  memory             = 8192  # 内存大小，单位 MB
  disk_size          = "120G"  # 磁盘大小，单位 GB
  format             = "qcow2"
  accelerator        = "kvm"
  vm_name            = "test.qcow2"
  net_device         = "virtio-net"
  disk_interface     = "virtio"
  disk_compression   = true
  headless           = false
  vnc_bind_address   = "0.0.0.0"
  vnc_port_max       = 5900
  boot_wait          = "-1s"
  
  # 安装后关机命令
  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"

  # 配置 QEMU 硬件参数
  qemuargs           = [
    #["-drive", "file=/home/wention/Data/ISOs/virtio-win-0.1.215.iso,media=cdrom,index=3"],
    #["-drive", "file=/home/wention/Data/ISOs/cn_windows_server_2019_x64_dvd_4de40f33.iso,media=cdrom,index=2"],
    # ["-drive", "file=output_builds/{{ .Name }},if=virtio,cache=writeback,discard=ignore,format=qcow2,index=1"],
  ]

  # 通过 cloud-init 注入 SSH 公钥
  # Packer 会启动一个 HTTP 服务来提供这些文件
  http_directory = "http"
  cd_files         = ["./cloud-init/*"]
  cd_label         = "cidata"

  # WinRM 配置，用于远程通信
  communicator = "ssh"
  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
}

# 定义构建过程
build {
  sources = ["source.qemu.ubuntu"]

  # PowerShell 脚本进行后期配置
  provisioner "shell" {
    inline = [
      "cat /etc/os-release",
    ]
  }
}

