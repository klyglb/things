#!/usr/bin/env python3
# ansible/grep_ip_from_tf_output.py
import json
import subprocess

def get_terraform_outputs():
    # Получаем JSON-вывод Terraform
    output = subprocess.check_output(['terraform', 'output', '-json'], cwd="../terraform/aws_test")
    return json.loads(output)

def generate_inventory(terraform_outputs):
    # Получаем список IP-адресов из вывода Terraform
    public_ips = terraform_outputs['instance_public_ips']['value']

    # Формируем структуру инвентаря Ansible
    inventory = "[web]\n"
    for ip in public_ips:
        inventory += f"{ip}\n"

    return inventory

def main():
    terraform_outputs = get_terraform_outputs()
    inventory_content = generate_inventory(terraform_outputs)

    # Записываем инвентарь в файл inventory.ini
    with open("inventory.ini", "w") as f:
        f.write(inventory_content)

if __name__ == "__main__":
    main()
