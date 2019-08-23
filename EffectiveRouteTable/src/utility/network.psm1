function network_dirWithNicVnet() {
    param(
        [String]$nicName,
        [String]$resourceId,
        [String]$vnetId
    )
    Import-Module -Name ($env:psLibrary + "tools.psm1") -Force
    $Matches = $null
    $col = @("module", "resourceKind", "resourceGroup", "resourceName", "nicName", "vnetName", "subnetName", "path")
    $resourceTable = MakeTable -TableName "resourceTable" -ColumnArray $col
    $resourceRegex = $vnetId -match "/Microsoft.Network/virtualNetworks/(?<vnetName>.+)/subnets/(?<subnetName>.+)"
    $row = $resourceTable.NewRow()
    $row.nicName = $nicName
    $row.vnetName = $Matches.vnetName 
    $row.subnetName = $Matches.subnetName
    $row.path = $env:effectiveRoute + "EffectiveRouteTable\outputs\routeTable\" + $Matches.vnetName + "\" + $Matches.subnetName
    $resourceRegex2 = $resourceId -match "/resourceGroups/(?<resourceGroup>.+)/providers/(?<module>.+)/(?<resourceKind>.+)/(?<resourceName>.+)"
    $row.module = $Matches.module
    $row.resourceKind = $Matches.resourceKind
    $row.resourceGroup = $Matches.resourceGroup
    $row.resourceName = $Matches.resourceName
    
    $resourceTable.Rows.Add($row)
    <#
    if(!$resourceRegex) {
        return 
    } else {
        return
    }
    #>

    return , @($resourceTable)
}