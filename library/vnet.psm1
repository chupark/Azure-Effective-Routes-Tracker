function nicVnet() {
    param(
        [String]$nicName,
        [String]$vnetId
    )
    Import-Module -Name ($env:effectiveRoute + "EffectiveRouteTable\library\tools.psm1") -Force
    $Matches = $null
    $col = @("nicName", "vnetName", "subnetName")
    $resourceTable = MakeTable -TableName "resourceTable" -ColumnArray $col
    $resourceRegex = $vnetId -match "/Microsoft.Network/virtualNetworks/(?<vnetName>.+)/subnets/(?<subnetName>.+)"
    $row = $resourceTable.NewRow()
    $row.nicName = $nicName
    $row.vnetName = $Matches.vnetName 
    $row.subnetName = $Matches.subnetName
    
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


function vnetPeeringRemoveDuplicate() {
    Import-Module -Name "D:\PowerShell\PowerShell\AzurePowerShell\dev\library\tools.psm1" -Force

    $vnets1 = Get-AzVirtualNetwork
    # AV AF AG URG
    $col = @("srcVnet", "dstVnet", "connState", "srcPrefix", "dstPrefix", "sVA", "sFT", "sGT", "sRG")
    $peeringTable = MakeTable "peeringTable" $col
    $duplicateFlage = $false

    foreach ($vnet1 in $vnets1) {
        $vnet1Peerings = Get-AzVirtualNetworkPeering -VirtualNetworkName $vnet1.Name -ResourceGroupName $vnet1.ResourceGroupName
        foreach ($vnet1Peering in $vnet1Peerings) {
            $vnet1 = Get-AzVirtualNetwork -ResourceGroupName R-NW-RG -Name R-VN2
            $Matches = $null
            $tmp = $vnet1Peering.RemoteVirtualNetwork.Id -match "/Microsoft.Network/virtualNetworks/(?<dstVnet>.+)"
            foreach ($tbl in $peeringTable) {
                if (($tbl.srcVnet -eq $Matches.dstVnet) -and ($tbl.dstVnet -eq $vnet1Peering.VirtualNetworkName)) {
                    $duplicateFlage = $true
                    Break;
                } else {
                    $duplicateFlage = $false
                }
            }
            if($duplicateFlage) {
                Continue;
            } else {
                $row = $peeringTable.NewRow()
                $row.srcVnet = $vnet1Peering.VirtualNetworkName
                $row.srcPrefix = $vnet1.addressSpace.AddressPrefixes -join ("^&&^")
                $row.dstVnet = $Matches.dstVnet
                $row.dstPrefix = $vnet1Peering.RemoteVirtualNetworkAddressSpace.AddressPrefixes -join ("^&&^")
                if($vnet1Peering.AllowVirtualNetworkAccess) { $row.sVA = "O" } else { $row.sVA = "X" }
                if($vnet1Peering.AllowForwardedTraffic) { $row.sFT = "O" } else { $row.sFT = "X" }
                if($vnet1Peering.AllowGatewayTransit) { $row.sGT = "O" } else { $row.sGT = "X" }
                if($vnet1Peering.UseRemoteGateways) { $row.sRG = "O" } else { $row.sRG = "X" }
                $peeringTable.Rows.Add($row)
            }
        }
    }

    return ,@($peeringTable)
}


function vnetPeeringAll() {
    Import-Module -Name "D:\PowerShell\PowerShell\AzurePowerShell\dev\library\tools.psm1" -Force

    $col = @("srcVnet", "dstVnet", "connState", "srcPrefix", "dstPrefix", "sVA", "sFT", "sGT", "sRG")
    $peeringTableAll = MakeTable "peeringTableAll" $col
    foreach ($vnet1 in $vnets1) {
        $vnet1Peerings = Get-AzVirtualNetworkPeering -VirtualNetworkName $vnet1.Name -ResourceGroupName $vnet1.ResourceGroupName
        foreach ($vnet1Peering in $vnet1Peerings) {
            $vnet1 = Get-AzVirtualNetwork -ResourceGroupName R-NW-RG -Name R-VN2
            $Matches = $null
            $tmp = $vnet1Peering.RemoteVirtualNetwork.Id -match "/Microsoft.Network/virtualNetworks/(?<dstVnet>.+)"
            $row = $peeringTableAll.NewRow()
            $row.srcVnet = $vnet1Peering.VirtualNetworkName
            $row.dstVnet = $Matches.dstVnet
            $row.connState = $vnet1Peering.PeeringState
            $row.srcPrefix = $vnet1.addressSpace.AddressPrefixes -join ("^&&^")
            $row.dstPrefix = $vnet1Peering.RemoteVirtualNetworkAddressSpace.AddressPrefixes -join ("^&&^")
            if($vnet1Peering.AllowVirtualNetworkAccess) { $row.sVA = "O" } else { $row.sVA = "X" }
            if($vnet1Peering.AllowForwardedTraffic) { $row.sFT = "O" } else { $row.sFT = "X" }
            if($vnet1Peering.AllowGatewayTransit) { $row.sGT = "O" } else { $row.sGT = "X" }
            if($vnet1Peering.UseRemoteGateways) { $row.sRG = "O" } else { $row.sRG = "X" }
            $peeringTableAll.Rows.Add($row)
        }
    }

    return ,@($peeringTableAll)
}

function vnetFinalPeering() {
    param(
        [Object]$vnetPeeringRemoveDuplicate,
        [Object]$vnetPeeringAll
    )
    Import-Module -Name "D:\PowerShell\PowerShell\AzurePowerShell\dev\library\tools.psm1" -Force
    $col = @("srcVnet", "dstVnet", "connState", "srcPrefix", "dstPrefix", "sVA", "sFT", "sGT", "sRG")
    $col3 = @("srcVnet", "dstVnet", "connState", "srcPrefix", "dstPrefix", "sVA", "sFT", "sGT", "sRG", "dVA", "dFT", "dGT", "dRG")
    $finalPeeringTable = MakeTable "finalPeering" $col3
    foreach ($tbl in $vnetPeeringRemoveDuplicate) {
        if($tt = $vnetPeeringAll | Where-Object {($_.srcVnet -eq $tbl.dstVnet) -and ($_.dstVnet -eq $tbl.srcVnet)}) {
            $row = $finalPeeringTable.NewRow()
            $i = 0
            for($i; $i -lt $col.Count; $i++) {
                $row[$i] = $tbl[$i]
            }
            for($i; $i -lt $col3.Count; $i++) {
                $row[$i] = $tt[$i - ($col3.Count - $col.Count)]
            }
            $finalPeeringTable.Rows.Add($row)
        }
    }
    return ,@($finalPeeringTable)
}
