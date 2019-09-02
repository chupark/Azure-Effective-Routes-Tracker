## outputs
[Array]$dirPaths = $null
$dirPaths += ($env:effectiveRoute + "EffectiveRouteTable\outputs\diff")
$dirPaths += ($env:effectiveRoute + "EffectiveRouteTable\outputs\hash")
$dirPaths += ($env:effectiveRoute + "EffectiveRouteTable\outputs\logs")
$dirPaths += ($env:effectiveRoute + "EffectiveRouteTable\outputs\logs\diff")
$dirPaths += ($env:effectiveRoute + "EffectiveRouteTable\outputs\logs\error")
$dirPaths += ($env:effectiveRoute + "EffectiveRouteTable\outputs\logs\error\runtime")
$dirPaths += ($env:effectiveRoute + "EffectiveRouteTable\outputs\logs\runtime")
$dirPaths += ($env:effectiveRoute + "EffectiveRouteTable\outputs\routeTable")

foreach ($dirPath in $dirPaths) {
    if (!(Test-Path $dirPath)) {
        New-Item -ItemType Directory -Force -Path $dirPath
    }
}