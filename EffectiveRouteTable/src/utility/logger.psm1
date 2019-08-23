function makeLogFile() {
    param (
        [String]$logType,
        [String]$fileName,
        [Object]$logMsg,
        $timeZone
    )
    $log_dt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss").ToString()
    $fileName_dt = (Get-Date -Format "yyyy-MM-dd").ToString()
    $configFile = Get-Content -Raw -Path ($env:effectiveRoute + "EffectiveRouteTable\src\statics\config.json") | ConvertFrom-Json
    $config = Get-Content -Raw -Path $configFile.log.path | ConvertFrom-Json
    $splited = $logType.Split(".")
    $i = 0
    for ($i = 0; $i -lt $splited.Count; $i++) {
        New-Variable -Name "log$i" -Value $splited[$i]
    }
    for ($i = 0; $i -lt $splited.Count; $i++) {
        $aa = (Get-Variable -Name "log$i").Value
        if ($i -eq 0) {
            $pathTest = $config.$aa
        } else {
            $pathTest = $pathTest.$aa
        }
    }  
    $fileFullPath = $pathTest + $fileName_dt + "_" + $fileName
    $fullMsg = $log_dt + "`n" + $logMsg + "`n"
    $fullMsg >> $fileFullPath
}