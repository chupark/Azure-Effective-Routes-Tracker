## https://stackoverflow.com/questions/31409009/how-to-have-a-powershell-function-return-a-table

Function MakeTable ($TableName, $ColumnArray) {
    $table = New-Object System.Data.DataTable("$TableName")
    foreach($Col in $ColumnArray)
    {
        $MCol = New-Object System.Data.DataColumn $Col;
        $table.Columns.Add($MCol)

      }
    return , $table
}

# by me cwpark!

function findVMNameWithNICName ([String]$nicName, $inputVMS) {
    foreach ($inputVm in $inputVMS) {
        foreach ($nic in $inputVm.NetworkProfile.NetworkInterfaces.Id) {
            $aa = $nic -match "/Microsoft.Network/networkInterfaces/(?<nicName>.+)"
            if ($Matches.nicName.ToString() -eq $nicName) {
                return $inputVm.Name
            }
        }
    }
}

function resourceKind() {
    param(
        [String]$resourceId
    )
    Import-Module -Name ($env:psLibrary + "tools.psm1") -Force
    $Matches = $null
    $col = @("module", "resourceKind", "resourceGroup", "resourceName")
    $resourceTable = MakeTable -TableName "resourceTable" -ColumnArray $col
    $resourceRegex = $resourceId -match "/resourceGroups/(?<resourceGroup>.+)/providers/(?<module>.+)/(?<resourceKind>.+)/(?<resourceName>.+)"
    $row = $resourceTable.NewRow()
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