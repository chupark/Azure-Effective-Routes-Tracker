<#
# @@ 
# input : $thisTime, $lastTime
# Type : String
# output : none
#>
function compareDiff() {
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