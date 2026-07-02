@{
    LabName            = 'istio-practical-lab'
    SwitchName         = 'IstioLabSwitch'
    InternetSwitchName = 'Default Switch'
    NatName            = 'IstioLabNat'
    NatPrefix          = '172.22.0.0/24'
    HostInterfaceIp    = '172.22.0.1'
    HostInterfacePrefix= 24
    VmPath             = 'C:\HyperV\IstioLab'
#    IsoPath            = 'C:\ISO\ubuntu-24.04.2-live-server-amd64.iso'
    IsoPath            = 'E:\ISO\ubuntu-24.04.3-live-server-amd64.iso'
    AutoinstallIsoPath = 'C:\ISO\ubuntu-24.04.3-live-server-amd64-autoinstall-v2.iso'
    SecureBootTemplate = 'MicrosoftUEFICertificateAuthority'
    StartupMemoryMode  = 'Fixed'
    Nodes = @(
        @{ Name='k8s-control-01'; ProcessorCount=4; StartupMemoryGB=6; VhdSizeGB=60; IpAddress='172.22.0.10'; LabMacAddress='00155D16000A'; InternetMacAddress='00155D26000A' },
        @{ Name='k8s-worker-01';  ProcessorCount=4; StartupMemoryGB=6; VhdSizeGB=80; IpAddress='172.22.0.11'; LabMacAddress='00155D16000B'; InternetMacAddress='00155D26000B' },
        @{ Name='k8s-worker-02';  ProcessorCount=4; StartupMemoryGB=6; VhdSizeGB=80; IpAddress='172.22.0.12'; LabMacAddress='00155D16000C'; InternetMacAddress='00155D26000C' }
    )
}
