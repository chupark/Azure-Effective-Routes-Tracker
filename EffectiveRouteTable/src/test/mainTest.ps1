## Import Library
Import-Module -Name ($env:psLibrary + "tools.psm1") -Force
Import-Module -Name ($env:effectiveRoute + "EffectiveRouteTable\src\utility\compareDiff.ps1") -Force
Import-Module -Name ($env:effectiveRoute + "EffectiveRouteTable\src\utility\logger.psm1") -Force
Import-Module -Name ($env:effectiveRoute + "EffectiveRouteTable\src\utility\network.psm1") -Force
$loginConfig = Get-Content -Raw -Path ($env:effectiveRoute + "loginCred.json") -Force | ConvertFrom-Json 
$config = Get-Content -Raw -Path ($env:effectiveRoute + "EffectiveRouteTable\src\statics\config.json") -Force | ConvertFrom-Json
$jsonConfig = Get-Content -Raw -Path ($env:effectiveRoute + "loginCred.json") | ConvertFrom-Json
$user = $jsonConfig.servicePrincipal.user
$pass = ConvertTo-SecureString -String $loginConfig.servicePrincipal.pass -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PsCredential -ArgumentList $user, $pass
Connect-AzAccount -ServicePrincipal -Credential $cred -Tenant $loginConfig.accountBasic.tenant `
                  -Subscription $loginConfig.accountBasic.subscription -SkipContextPopulation -WarningAction SilentlyContinue

makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("Starting Script=============")
try {
    ## Global Variables
    $vms = Get-AzVM
    $nics = Get-AzNetworkInterface
    $nicVnetTable
    $resourceTable = $null
    $dt = Get-Date
    $hashFileDate = (Get-Date $dt -Format "yyyy-MM-dd HH:mm:ss")
    $todayFile = (Get-Date $dt -Format "yyyy-MM-dd HH_mm")
    $batchSize = $config.batch.size

    ## File Names & Path
    $scriptPath = $env:effectiveRoute + "EffectiveRouteTable\src\utility\getCurrentEffectiveRoute.ps1"
    $csvFileName = $todayFile + "_route.csv"
    $hashFileName = $env:effectiveRoute + "EffectiveRouteTable\outputs\hash\fileHash.csv"
    $saveFilePath = $env:effectiveRoute + "EffectiveRouteTable\outputs\routeTable\"
    
    <#
    서브넷 별로 파일 떨구자.. 굿? ㅇㅋ 굿
    $vnets=Get-AzVirtualNetwork
    $nics = Get-AzNetworkInterface
    $nics[0].IpConfigurations[0].Subnet.Id
    #>
    foreach ($vm in $vms) {
        foreach ($tmpNicId in $vm.NetworkProfile.NetworkInterfaces) {
            $nic = $nics | Where-Object {$_.Id -eq $tmpNicId.Id}
            $resourceTable += network_dirWithNicVnet -nicName $nic.Name -resourceId $nic.Id -vnetId $nic.IpConfigurations[0].Subnet.Id
        }
    }
    
    makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("Starting jobs....")
    ## Starting Batch job
    foreach ($rsTable in $resourceTable) {
        Start-Job -FilePath $scriptPath -ArgumentList $rsTable.resourceGroup, $rsTable.resourceName, $rsTable.path
        if ($config.batch.value) {
            $jobCnt = [int](Get-job).Count % $batchSize
            if($jobCnt -eq 0) {
                Get-Job | Wait-Job
            }
        }
    }
    # 
    # 테이블 만들어서 csv로 정리
    # 파일 저장 시 Hash 값을 csv 파일에 같이 저장함, 이 때 항상 순서가 같아야 하므로 정렬이 필요함
    # @@
    # output : $out
    # Type : Object[]
    #
    makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("All Job is Finished")

    ##
    # @@ 
    # Primary output
    #
    ## Making Final RouteTable
    makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("Starting make RouteTable")
    Get-Job | Wait-Job
    $out = Get-Job | Receive-Job -Keep | Select-Object * -ExcludeProperty RunspaceId, PSComputerName, PSShowComputerName |
           Sort-Object -Property nicName, Name, DisableBgpRoutePropagation, State, Source, AddressPrefix, NextHopType, NextHopIpAddress
    $pathGroup = $out.path | Select -Unique

    ## group by Something.... [subnet || nicName]
    $grp = $config.csvGrouping
    $csvGroup = $out.$grp | Select -Unique

    ## Making Directory Group by Vnet, Subnet
    foreach ($path in $pathGroup) {
        if (!(Test-Path $path)) {
            New-Item -ItemType Directory -Force -Path $path
        }
    }

    ## Grouping File Path
    foreach ($gp in $pathGroup) {
        $zzz = $out | Where-Object {$_.path -eq $gp}
        foreach ($zz in $zzz) {
            $realPath = $zz.path + "\" + $zz.nicName + $csvFileName
            Write-Host $realPath
        }
    }

    $out | Select-Object * -ExcludeProperty RunspaceId, PSComputerName, PSShowComputerName |
        Sort-Object -Property nicName, Name, DisableBgpRoutePropagation, State, Source, AddressPrefix, NextHopType, NextHopIpAddress |
        Export-csv  $csvFileName -NoTypeInformation
        makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("Making RouteTable ended")
    # Get-Job | Remove-Job

    # 저장한 파일의 Hash값을 따로 보관함
    # 파일의 내용이 일치하면 같은 Hash값을 가짐
    # @@
    # input : $csvFileName (파일 경로)
    # output : $hash
    # Type : Object[]
    makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("Recording Hash Value")
    $hash = Get-FileHash $csvFileName
    $hash | Add-Member -MemberType NoteProperty -Name "date" -Value $hashFileDate
    $hash | Export-Csv $hashFileName -NoTypeInformation -Append -Encoding UTF8

    # 다른점 찾기
    # Hash 파일 기록 csv 파일에 2개 이상 데이터 row가 있을 경우 작동
    # 가장 최신의 Hash 값과 그 이전의 Hash값을 비교함, Hash값이 다를 경우 변동이 있다고 판단
    # logs\diff 에 기록을 남기며, diff에 csv 비교를 시작한 시간의 이름으로 결과 파일을 남김
    # @@
    # input : $thisTime, $lastTime
    # Type : String
    # output : none
    $csvFileTest = Import-Csv -Path $hashFileName
    makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("Compare")
    if($csvFileTest.Path.Count -ge 2) {
        $thisTime = $csvFileTest.Path[$csvFileTest.Count - 1]
        $beforeTime = $csvFileTest.Path[$csvFileTest.Count - 2]
        compareDiff -thisTime $thisTime -lastTime $beforeTime
    } else {
        makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("No Compar data")
    }
} catch {
    makeLogFile -logType "log.runtime.error" -fileName "runtime_error.log" -logMsg $_.Exception.Message
}
makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("End Script=============")
Get-Job | Remove-Job