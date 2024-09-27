# outputs.tf

output "vm_ips" {
  value = { for idx, dom in libvirt_domain.vm :
    dom.name => dom.network_interface[0].addresses[0] }
}
