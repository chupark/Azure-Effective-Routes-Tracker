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
    $vmStatuses = $null
    $vms = $null
    $resourceTable = $null
    $nics = $null

    $vmStatuses = Get-AzVM -Status
    $vms = $vmStatuses | Where-Object {$_.PowerState -eq "VM running"}
    $nics = Get-AzNetworkInterface
    $dt = Get-Date
    ### for Test
    # $dt = $dt.AddDays(1)
    ###
    $hashFileDate = (Get-Date $dt -Format "yyyy-MM-dd HH:mm:ss")
    $todayFile = (Get-Date $dt -Format "yyyy-MM-dd HH_mm")
    $batchSize = $config.batch.size

    ## File Names & Path
    $scriptPath = $env:effectiveRoute + "EffectiveRouteTable\src\utility\getCurrentEffectiveRoute.ps1"
    $csvFileName = $todayFile + "_route.csv"
    $hashHome = $env:effectiveRoute + "EffectiveRouteTable\outputs\hash\"
    $hashFileName = $env:effectiveRoute + "EffectiveRouteTable\outputs\hash\" + $todayFile  + "_fileHash.csv"
    # $saveFilePath = $env:effectiveRoute + "EffectiveRouteTable\outputs\routeTable\"
    
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
                $fornull = Get-Job | Wait-Job
            }
        }
    }
    makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("All Job is Finished")

    ##
    # @@ 
    # Primary output
    #
    ## Making Final RouteTable
    # 
    # 테이블 만들어서 csv로 정리
    # 파일 저장 시 Hash 값을 csv 파일에 같이 저장함, 이 때 항상 순서가 같아야 하므로 정렬이 필요함
    # @@
    # output : $out
    # Type : Object[]
    #
    makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("Starting make RouteTable")
    $fornull = Get-Job | Wait-Job
    $out = Get-Job | Receive-Job -Keep | Select-Object * -ExcludeProperty RunspaceId, PSComputerName, PSShowComputerName |
           Sort-Object -Property nicName, Name, DisableBgpRoutePropagation, State, Source, AddressPrefix, NextHopType, NextHopIpAddress
    
    ## 디렉토리 위치를 네트워크 별로 나눔
    $pathGroup = $out.path | Select -Unique

    ## group by Something.... [subnet || nicName]
    $grp = $config.csvGrouping
    ## 서브넷 별로 파일을 만들 것이냐, nic 이름별로 파일을 만들 것이냐.
    $csvGroup = $out.$grp | Select -Unique

    ## Making Directory Group by Vnet, Subnet
    foreach ($path in $pathGroup) {
        if (!(Test-Path $path)) {
            New-Item -ItemType Directory -Force -Path $path
        }
        $diffPathRegex = $path -match "(?<pathHeader>.+)\\routeTable\\(?<pathFooter>.+)"
        $diffPath = $Matches.pathHeader + "\diff\" + $Matches.pathFooter
        if (!(Test-Path $diffPath)) {
            New-Item -ItemType Directory -Force -Path $diffPath
        }
    }

    ## Grouping File Path
    ### 2019-08-23 여기까지 완성
    [Array]$realPathList = $null
    foreach ($gp in $pathGroup) {
        $zzz = $out | Where-Object {$_.path -eq $gp}
        foreach ($zz in $zzz) {
            if ($grp -eq "path") {
                $realPath = $zz.path + "\" + $csvFileName
            } elseif($grp -eq "nicName") {
                $realPath = $zz.path + "\" + $zz.$grp + $csvFileName
            }
            $zz | Export-Csv -Path $realPath -Append -NoTypeInformation
        }
        $realPathList += $realPath
    }
    foreach ($rp in $realPathList) {
        Set-ItemProperty -Path $rp -Name IsReadOnly -Value $true
    }
    makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("Making RouteTable ended")
    # Get-Job | Remove-Job

    # 저장한 파일의 Hash값을 따로 보관함
    # 파일의 내용이 일치하면 같은 Hash값을 가짐
    # @@
    # input : $csvFileName (파일 경로)
    # output : $hash
    # Type : Object[]
    makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("Recording Hash Value")
    foreach ($rp in $realPathList) {
        $hash = Get-FileHash $rp
        $hash.Hash
        $hash | Add-Member -MemberType NoteProperty -Name "date" -Value $hashFileDate
        $hash | Export-Csv $hashFileName -NoTypeInformation -Append -Encoding UTF8
    }
    Set-ItemProperty -Path $hashFileName -Name IsReadOnly -Value $true
    
    # 다른점 찾기
    # 전날 해쉬와 오늘 해쉬를 비교함
    # 가장 최신의 Hash 값과 그 이전의 Hash값을 비교함, Hash값이 다를 경우 변동이 있다고 판단
    # logs\diff 에 기록을 남기며, diff에 csv 비교를 시작한 시간의 이름으로 결과 파일을 남김
    # @@
    # input : $thisTime, $lastTime
    # Type : String
    # output : none
    $hashFiles = Get-ChildItem -Path "C:\powershell\Azure-Effective-Routes-Tracker\EffectiveRouteTable\outputs\hash\" | Sort-Object -Property LastWriteTime -Descending
    if(!$hashFiles) {
        return
    }
    $todayHash = $hashFiles[0].FullName
    $yesterdayHash = $hashFiles[1].FullName
    $todayHashCSV = Import-Csv -Path $todayHash
    $yesterdayHashCSV = Import-Csv -Path $yesterdayHash
    $diff = Compare-Object -ReferenceObject $yesterdayHashCSV.Hash -DifferenceObject $todayHashCSV.Hash

    [Array]$diffObj = $null
    foreach ($diffarr in $diff.InputObject) {
        $diffObj += $yesterdayHashCSV | Where-Object {$_.Hash -eq $diffarr}
        $diffObj += $todayHashCSV | Where-Object {$_.Hash -eq $diffarr}
    }
    
    foreach ($diff in $diffObj) {
        $Matches = $null
        $diff.Path -match "C:\\powershell\\Azure-Effective-Routes-Tracker\\(?<pathHeader>.+)\\routeTable\\(?<footer1>.+)\\(?<footer2>.+)\\"
        $dp = $env:effectiveRoute + $Matches.pathHeader + "\diff\" + $Matches.footer1 + "\" + $Matches.footer2 + "\"
        Copy-Item -Path $diff.Path -Destination $dp
    }

} catch {
    makeLogFile -logType "log.runtime.error" -fileName "runtime_error.log" -logMsg $_.Exception.Message
}
makeLogFile -logType "log.runtime.general" -fileName "runtime.log" -logMsg ("End Script=============")
Get-Job | Remove-Job