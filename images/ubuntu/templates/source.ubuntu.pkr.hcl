# 定义 QEMU 构建源
source "qemu" "image" {
  iso_url            = "/home/wention/Downloads/noble-server-cloudimg-amd64.img"
  iso_checksum       = "none"
  output_directory   = local.output_dir
  disk_image         = true
  use_backing_file   = true

  # 定义虚拟机的硬件配置
  machine_type       = "q35"
  cpu_model          = "host"
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

  # 安装后关机命令（cloud-init 为 runner 配置了 NOPASSWD sudo）
  shutdown_command = "echo 'runner' | sudo -S shutdown -P now"

  # 通过 cloud-init (NoCloud/cidata) 注入用户与 SSH 公钥
  # 路径由 locals 基于 path.root 解析，与执行 packer 时的当前目录无关
  cd_files       = ["${local.cloud_init_dir}/*"]
  cd_label       = "cidata"

  # SSH 配置，用于远程通信（与 assets/cloud-init/user-data 中的 runner 用户一致）
  communicator = "ssh"
  ssh_username = "runner"
  ssh_password = "runner"
}
