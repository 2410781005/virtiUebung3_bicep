param location string = resourceGroup().location
param usernameAdmin string = '' //Benutzername einfuegen
param vmLinuxType string = 'Standard_DS1_v2'
param sshPublicKey string = '' // SSH Key einfuegen

param vmNamen array = [
  'prodAlmaVM01'
  'prodAlmaVM02'
  'prodAlmaVM03'
]

/*
Definition der Namen der VM's und indirekt auch die Anzahl der VM's
*/

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'prod-alma-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

/*
Erstellung von IP-Adresse für alle VM's in der VmNamen liste. Mittels for werden, einfach und übersichtlich, mehrere in einem Deployment erstellt
*/

resource publicIPs 'Microsoft.Network/publicIPAddresses@2024-05-01' = [for vm in vmNamen: {
  name: '${vm}-publicIP'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}]

/*
Erstellung von dazugehörigen NIC's mit zuweiseung der public IP's
*/

resource nics 'Microsoft.Network/networkInterfaces@2024-05-01' = [for (vm, i) in vmNamen: {
  name: '${vm}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          publicIPAddress: {
            id: publicIPs[i].id
          }
        }
      }
    ]
  }
}]

/*
Endgültige Erstellung der VM's mit den definierten VM Namen, Benutzername, SSH-Key, NIC's und IP's
Zusätzlich wird noch ein benötigtes Storage mit dem Image "AlmaLinux" erstellt und der VM zugewiesen
*/

resource vms 'Microsoft.Compute/virtualMachines@2024-07-01' = [for (vm, i) in vmNamen: {
  name: vm
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmLinuxType
    }
    osProfile: {
      computerName: vm
      adminUsername: usernameAdmin
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${usernameAdmin}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'almalinux'
        offer: 'almalinux-x86_64'
        sku: '9-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nics[i].id
        }
      ]
    }
  }
}]



