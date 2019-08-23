param (
    $nicResourceGroupName,
    $nicName,
    $path
)
try {
    Import-Module -Name ($env:effectiveRoute + "EffectiveRouteTable\src\utility\logger.psm1") -Force
    makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ($nicName + "Starting")
    # change config file path here------------↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    $jsonConfig = Get-Content -Raw -Path ($env:effectiveRoute + "loginCred.json") | ConvertFrom-Json
    $user = $jsonConfig.servicePrincipal.user
    $pass = ConvertTo-SecureString -String $jsonConfig.servicePrincipal.pass -AsPlainText -Force
    $cred = New-Object -TypeName System.Management.Automation.PsCredential -ArgumentList $user, $pass
    $account = Connect-AzAccount -ServicePrincipal -Credential $cred -Tenant $jsonConfig.accountBasic.tenant -Subscription $jsonConfig.accountBasic.subscription -WarningAction SilentlyContinue
    $routeTable = Get-AzEffectiveRouteTable -ResourceGroupName $nicResourceGroupName -NetworkInterfaceName $nicName -ErrorAction SilentlyContinue -ErrorVariable anyError
    $routeTable | Add-Member -MemberType NoteProperty -Name "nicName" -Value $nicName
    $routeTable | Add-Member -MemberType NoteProperty -Name "path" -Value $path
    $routeTable
    if ($anyError) {
        # error --> log.error
        makeLogFile -logType "log.error" -fileName "error.log" -logMsg $anyError
    }
    makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ($nicName + "Ending")
} catch {
    makeLogFile -logType "log.runtime.error" -fileName "runtime_error.log" -logMsg $_.Exception.Message
}