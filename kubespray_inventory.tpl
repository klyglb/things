[all]
%{ for name, ip in vm_ips ~}
${name} ansible_host=${ip} ip=${ip}
%{ endfor }

[kube_control_plane]
%{ for name in vm_ips.keys() ~}
%{ if name == "master" ~}
${name}
%{ endif ~}
%{ endfor }

[etcd]
%{ for name in vm_ips.keys() ~}
%{ if name == "master" ~}
${name}
%{ endif ~}
%{ endfor }

[kube_node]
%{ for name in vm_ips.keys() ~}
%{ if name != "master" ~}
${name}
%{ endif ~}
%{ endfor }

[k8s_cluster:children]
kube_control_plane
kube_node
etcd
