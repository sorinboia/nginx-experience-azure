resource "azurerm_public_ip" "controller_pip" {
  name = "controller_pip"
  location = var.controller_location
  resource_group_name = azurerm_resource_group.az_resourcegroup.name
  allocation_method = "Dynamic"
  sku = "Basic"
}

resource "azurerm_network_interface" "controller_vm1nic" {
  name = "controller-vm1-nic-${random_id.random-string.dec}"
  location = var.controller_location
  resource_group_name = azurerm_resource_group.az_resourcegroup.name
  ip_configuration {
    name = "ipconfig1"
    subnet_id = azurerm_subnet.frontendsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.controller_pip.id
  }
}

resource "azurerm_virtual_machine" "example" {
  name                  = "controller-${random_id.random-string.dec}"
  location              = var.controller_location
  resource_group_name   = azurerm_resource_group.az_resourcegroup.name
  network_interface_ids = [azurerm_network_interface.controller_vm1nic.id]
  vm_size               = "Standard_D4_v2"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb = "100"
  }
  os_profile {
    computer_name  = "controller"
    admin_username = "ubuntu"
    admin_password = "Password1234!"
    custom_data = <<-EOF
      #!/bin/bash
      apt-get update
      swapoff -a
      ufw disable
      apt-get install awscli jq -y
      wget https://sorin.blob.core.windows.net/nginx/offline-controller-installer-1902719.tar.gz -O /home/ubuntu/controller.tar.gz
      tar zxvf /home/ubuntu/controller.tar.gz -C /home/ubuntu/
      host_ip=$(curl -s ifconfig.me)
      export HOME=/home/ubuntu
      /home/ubuntu/controller-installer/install.sh -n --accept-license --smtp-host $host_ip --smtp-port 25 --smtp-authentication false --smtp-use-tls false --noreply-address no-reply@sorin.nginx --fqdn $host_ip --organization-name nginx1 --admin-firstname NGINX --admin-lastname Admin --admin-email nginx@f5.com --admin-password Admin2020 --self-signed-cert --auto-install-docker --tsdb-volume-type local
      curl -k -c cookie.txt -X POST --url "https://$host_ip/api/v1/platform/login" --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "nginx@f5.com","password": "Admin2020"}}'
      curl -k -b cookie.txt -c cookie.txt --header "Content-Type: application/json" --request POST --url "https://$host_ip/api/v1/platform/license-file" --data '{"content":"TUlNRS1WZXJzaW9uOiAxLjAKQ29udGVudC1UeXBlOiBtdWx0aXBhcnQvc2lnbmVkOyBwcm90b2NvbD0iYXBwbGljYXRpb24veC1wa2NzNy1zaWduYXR1cmUiOyBtaWNhbGc9InNoYS0yNTYiOyBib3VuZGFyeT0iLS0tLTAxMUI3NzhGM0E1QkIxQTEyMjMzMkE1NjdFQUIwMjUyIgoKVGhpcyBpcyBhbiBTL01JTUUgc2lnbmVkIG1lc3NhZ2UKCi0tLS0tLTAxMUI3NzhGM0E1QkIxQTEyMjMzMkE1NjdFQUIwMjUyCld3b2dJQ0FnZXdvZ0lDQWdJQ0FnSUNKbGVIQnBjbmtpT2lBaU1qQXlNQzB4TVMweE1WUXhORG8wTURvd01pNHhOekUwTnpCYUlpd2cKQ2lBZ0lDQWdJQ0FnSW14cGJXbDBjeUk2SURJd0xDQUtJQ0FnSUNBZ0lDQWljSEp2WkhWamRDSTZJQ0pPUjBsT1dDQkRiMjUwY205cwpiR1Z5SUV4dllXUWdRbUZzWVc1amFXNW5JaXdnQ2lBZ0lDQWdJQ0FnSW5ObGNtbGhiQ0k2SURFNU5EY3NJQW9nSUNBZ0lDQWdJQ0p6CmRXSnpZM0pwY0hScGIyNGlPaUFpU1RBd01EQTVOVGcxT1NJc0lBb2dJQ0FnSUNBZ0lDSjBlWEJsSWpvZ0ltbHVkR1Z5Ym1Gc0lpd2cKQ2lBZ0lDQWdJQ0FnSW5abGNuTnBiMjRpT2lBeENpQWdJQ0I5TENBS0lDQWdJSHNLSUNBZ0lDQWdJQ0FpWlhod2FYSjVJam9nSWpJdwpNakF0TVRFdE1URlVNVFE2TkRBNk1ESXVNVGN4TnpVeFdpSXNJQW9nSUNBZ0lDQWdJQ0pzYVcxcGRITWlPaUF5TUN3Z0NpQWdJQ0FnCklDQWdJbkJ5YjJSMVkzUWlPaUFpVGtkSlRsZ2dRMjl1ZEhKdmJHeGxjaUJCVUVrZ1RXRnVZV2RsYldWdWRDSXNJQW9nSUNBZ0lDQWcKSUNKelpYSnBZV3dpT2lBeE9UUTNMQ0FLSUNBZ0lDQWdJQ0FpYzNWaWMyTnlhWEIwYVc5dUlqb2dJa2t3TURBd09UVTROVGtpTENBSwpJQ0FnSUNBZ0lDQWlkSGx3WlNJNklDSnBiblJsY201aGJDSXNJQW9nSUNBZ0lDQWdJQ0oyWlhKemFXOXVJam9nTVFvZ0lDQWdmUXBkCgotLS0tLS0wMTFCNzc4RjNBNUJCMUExMjIzMzJBNTY3RUFCMDI1MgpDb250ZW50LVR5cGU6IGFwcGxpY2F0aW9uL3gtcGtjczctc2lnbmF0dXJlOyBuYW1lPSJzbWltZS5wN3MiCkNvbnRlbnQtVHJhbnNmZXItRW5jb2Rpbmc6IGJhc2U2NApDb250ZW50LURpc3Bvc2l0aW9uOiBhdHRhY2htZW50OyBmaWxlbmFtZT0ic21pbWUucDdzIgoKTUlJRnZBWUpLb1pJaHZjTkFRY0NvSUlGclRDQ0Jha0NBUUV4RHpBTkJnbGdoa2dCWlFNRUFnRUZBREFMQmdrcQpoa2lHOXcwQkJ3R2dnZ016TUlJREx6Q0NBaGVnQXdJQkFnSUpBSU16cFhRSHBTeWFNQTBHQ1NxR1NJYjNEUUVCCkN3VUFNQzR4RWpBUUJnTlZCQW9NQ1U1SFNVNVlJRWx1WXpFWU1CWUdBMVVFQXd3UFEyOXVkSEp2Ykd4bGNpQkQKUVNBeE1CNFhEVEU0TURVeE1URXlNVE0xTVZvWERUSXlNRFV4TURFeU1UTTFNVm93TGpFU01CQUdBMVVFQ2d3SgpUa2RKVGxnZ1NXNWpNUmd3RmdZRFZRUUREQTlEYjI1MGNtOXNiR1Z5SUVOQklERXdnZ0VpTUEwR0NTcUdTSWIzCkRRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRFJWY1JHMW5XS1QyTy9zcnI2WWZzTWc3RUN5cEdocmgzckRzRmQKRXVwSzVRZFE3TVIvM0hrYjk0RFk4eDlMY0lkNVVjZnFXMVpZdXN4Z1pGTmx4OW9wbVlmaW5maXNXaHFyZXVZSgpNanBVTzZILzUvL1lRNk5sV05LQUdDMmp6NkxsR0QrVzAyakFTM2RHUGMzRXlOL2FnN3lVc1hKbUpldkVUK3UwCnFsUXI0QXBZanZnV1N2NG1pV0JjamYxbTEzczVGVDBhdWwrMUVJekhRWEtqK2xhR0xITUtzYUZ0MUdoL3EweVoKaEtNeXJpcFlMRGpHUWVNUW9zeDVsYUFBZ0o3TjNMbnhRbnpSaUE2Q3Q5QkZib3AvMEY3VDZ2NjRBcUJQR240Qgptem9sQ3Zlc1lnaWsranVDRGxNT0ZNbFV4cnFTejFBdlFlUHM4Z1lxb2FBcnRTY1RBZ01CQUFHalVEQk9NQjBHCkExVWREZ1FXQkJRU2FXR21XcXNtTXNzeFdwK1hqbHprd3luOFhUQWZCZ05WSFNNRUdEQVdnQlFTYVdHbVdxc20KTXNzeFdwK1hqbHprd3luOFhUQU1CZ05WSFJNRUJUQURBUUgvTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFDcAo3emFEMU52TTFEVEVQemtDTm84QjBtUDhkMTRLdWV5YVlwVi9td01La0Frc2xMdnB3MTlqLzl3Wng4Rm0yWkZOClROQlRSYi9tcEh0Zk5QQ1BKWTEzY21lUUo2R1BNQTV4bGcvSUx3SWJzTzdsSno0bEZsWFlhTWpoKytHdkVPL2sKWEVsL05VRnROcW1yYjRzelhKMlNoYnIySjFoMHpURm5rMncxWDNwVnBpazJWTmpKZjd1VDZ0NVROWldwREhGdApLVzRhZkl4d0U1dXNVcUs4REF3YnJLazFGQit4S01XTnBUS1gxeXM2TitGZmVVeWM2SHVaM0pGVzNCNlhNMys5Ckw5cmVKbGkyVFFrYm9pQk1QSXFLZFJGVFovbGRhNHR3TW5pREVGOVlkTTd6QnR6VmZ4VGlmN1F5YndpZ3cvUDEKaFRJRlFpaTNQSWpLdkNyZHdGQmZNWUlDVFRDQ0Fra0NBUUV3T3pBdU1SSXdFQVlEVlFRS0RBbE9SMGxPV0NCSgpibU14R0RBV0JnTlZCQU1NRDBOdmJuUnliMnhzWlhJZ1EwRWdNUUlKQUlNenBYUUhwU3lhTUEwR0NXQ0dTQUZsCkF3UUNBUVVBb0lIa01CZ0dDU3FHU0liM0RRRUpBekVMQmdrcWhraUc5dzBCQndFd0hBWUpLb1pJaHZjTkFRa0YKTVE4WERUSXdNRFV4TWpFME5ERXdNRm93THdZSktvWklodmNOQVFrRU1TSUVJSnNqM0RpUWNTYVh4Sjd3Q29EZAp2bVFBa2xqOFhFRzlFLzBkeFVQbHRhU1JNSGtHQ1NxR1NJYjNEUUVKRHpGc01Hb3dDd1lKWUlaSUFXVURCQUVxCk1Bc0dDV0NHU0FGbEF3UUJGakFMQmdsZ2hrZ0JaUU1FQVFJd0NnWUlLb1pJaHZjTkF3Y3dEZ1lJS29aSWh2Y04KQXdJQ0FnQ0FNQTBHQ0NxR1NJYjNEUU1DQWdGQU1BY0dCU3NPQXdJSE1BMEdDQ3FHU0liM0RRTUNBZ0VvTUEwRwpDU3FHU0liM0RRRUJBUVVBQklJQkFIMXZudnZETEdVQUM4bGk1YzFsWnBGSGNRVTllcWlPOXZwTFhxSWJxd2JQCnd5dktqKzJtY0x2SGQ3VDQyNUh6OUVQZ01uUVNwNHFUZHBJaXVoeFl0N0ZTUTRkMGUyU1YzeHRma3B5eXlrV2YKUnBwSFI0WVozWG5VcEIxRGhFeXNJM2hMWm5PcllhM21uWkc5NWJwS28vT2VGM0c3Zk5tLzltRkJ2S1VrdXQ5awpQb3FvaWIzaTEzZTlQMTJDaVUvekNGbWNIYlRLclQxb2J5MWcwcGlPa1oxckVMRVF1U2FkVE5nbHQ4V0hBRzRXCk1DdHh4cS85citIOGZyaFVtOTc5S2RVeHc2ancvY2srZnRoNm1qaVc4dUFlRU1JRWlqekpUQ2llb0wwdE9wYWkKcURoUitqZ3JxL3l1dUtLdnNJdEhoQTI5cnlRR3FEKzhUcGF3eWZUYWJKWT0KCi0tLS0tLTAxMUI3NzhGM0E1QkIxQTEyMjMzMkE1NjdFQUIwMjUyLS0KCg=="}'
    EOF
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}