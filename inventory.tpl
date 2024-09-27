[all]
%{ for name in vm_names ~}
${name} ansible_host=${vm_ips[name]} ansible_user=centos
%{ endfor }

[master]
%{ for name in vm_names ~}
%{ if name == "master" }
${name}
%{ endif }
%{ endfor }

[workers]
%{ for name in vm_names ~}
%{ if name != "master" }
${name}
%{ endif }
%{ endfor }
