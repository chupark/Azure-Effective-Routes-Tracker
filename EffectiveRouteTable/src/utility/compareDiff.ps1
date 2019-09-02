<#
# @@ 
# input : $thisTime, $lastTime
# Type : String
# output : none
#>

function compareDiff() {
    param(
        $hashHome
    )
    Import-Module -Name ($env:effectiveRoute + "EffectiveRouteTable\src\utility\logger.psm1") -Force
    try {
        $todayHash = Get-FileHash -Path $hashFiles[0].FullName
        $yesterdayHash = Get-FileHash -Path $hashFiles[1].FullName
        if ($todayHash.Hash -ne $yesterdayHash.Hash) {
            $tdy = Import-CSV $todayHash.Path
            $ytd = Import-Csv $yesterdayHash.Path
            $compare = Compare-Object -ReferenceObject $tdy.Hash -DifferenceObject $ytd.Hash
            $hashSum = $tdy + $ytd
            [Array]$diffHash = $null
            foreach ($difHash in $compare.InputObject) {
                $diffHash += $hashSum | Where-Object {$_.Hash -eq $difHash}
            }
            makeLogFile -logType "customLog.differentLog" -fileName "diff.log" -logMsg $aa
        }
    } catch {
        makeLogFile -logType "log.error" -fileName "error.log" -logMsg $_.Exception.Message
    }
    return ,$diffHash
}



function compareDiff_main() {
    param(
        $thisTime,
        $lastTime
    )
    Import-Module -Name ($env:effectiveRoute + "EffectiveRouteTable\src\utility\logger.psm1") -Force
    try {
        $thisTimeCSV = Import-Csv $thisTime
        $beforeTimeCSV = Import-Csv $lastTime

        $diff = Compare-Object -ReferenceObject $thisTimeCSV -DifferenceObject $beforeTimeCSV
        $aa = Out-String -InputObject $diff.InputObject
        if ($diff) {
            makeLogFile -logType "customLog.differentLog" -fileName "diff.log" -logMsg $aa
            $filePrefix = (Get-Date -Format "yyyy-MM-dd HH_mm_ss")
            $diff.InputObject | Export-Csv ($env:effectiveRoute + "EffectiveRouteTable\outputs\diff\$filePrefix.csv") -NoTypeInformation
        }
    } catch {
        makeLogFile -logType "log.error" -fileName "error.log" -logMsg $_.Exception.Message
    }
}
