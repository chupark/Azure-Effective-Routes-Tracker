Import-Module -Name D:\PowerShell\PowerShell\AzurePowerShell\dev\library\tools.psm1 -Force
$vms = Get-AzVM
$resourceTable = $null
$routeTable = $null

foreach ($vm in $vms) {
    foreach ($tmpNicId in $vm.NetworkProfile.NetworkInterfaces) {
        $resourceTable += resourceKind -resourceId $tmpNicId.Id
    }
}

foreach ($rsTable in $resourceTable) {
    $routeTable += Get-AzEffectiveRouteTable -ResourceGroupName $rsTable.resourceGroup -NetworkInterfaceName $rsTable.resourceName -ErrorAction SilentlyContinue -ErrorVariable anyError

}

$routeTable.PSObject.Properties.Remove('')