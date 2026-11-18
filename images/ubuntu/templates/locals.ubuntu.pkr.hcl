locals {
  # 统一基于模板目录解析，避免依赖执行 packer 时的当前工作目录
  cloud_init_dir = abspath("${path.root}/../assets/cloud-init")
  http_dir       = abspath("${path.root}/http")
  output_dir     = abspath("${path.root}/../../../output_builds")
}
