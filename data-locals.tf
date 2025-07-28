# PUBLIC IP - piped to var.my_ip
data "http" "default_ip" {
    url = "https://api.ipify.org"
}
locals {
    default_ip = "${trimspace(data.http.default_ip.body)}/32"
}
locals {
    effective_ip = var.my_ip != "" ? var.my_ip : local.default_ip
}