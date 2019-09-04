### 작성 중
 사용에 궁금한점이 있다면 qkrcldn12@gmail.com 으로 메일 주세용

# Azure NIC의 유효경로 변경사항 추적

### 환경 변수 설정
아래 두 가지 환경 변수를 시스템에 맞게 설정 합니다.
````
psLibrary
effectiveRoute
````

예를 들어 이 Repository를 Windows C:\PowerShell 에 저장했을 경우 아래와 같이 환경 변수를 설정합니다.
````
psLibrary = C:\powershell\Azure-Effective-Routes-Tracker\library\
effectiveRoute = C:\powershell\Azure-Effective-Routes-Tracker\
````

### 프로그램 실행
env.ps1 파일을 실행하여 outputs에 디렉토리를 만듭니다.
아래와 같은 디렉토리가 만들어져야 합니다.
````
EffectiveRouteTable\outputs\diff
EffectiveRouteTable\outputs\hash
EffectiveRouteTable\outputs\logs
EffectiveRouteTable\outputs\logs\diff
EffectiveRouteTable\outputs\logs\error
EffectiveRouteTable\outputs\logs\error\runtime
EffectiveRouteTable\outputs\logs\runtime
EffectiveRouteTable\outputs\routeTable
````
main.ps1 파일을 실행시킵니다.

### 작업 스캐줄 설정
Windows의 경우 스케줄 작업 <br>
Linux에 PowerShell Core를 설치했을 경우 Cronjob을 추가 합니다.

--- 나중에 더 추가 
## Output 구성
* EffectiveRouteTable\outputs\routeTable
    - 하위에 Subnet별 디렉토리가 만들어지고 Effective Route 테이블이 csv 파일로 만들어집니다.
* EffectiveRouteTable\outputs\hash
    - 하위에 각 파일별 hash값이 저장됩니다.
* EffectiveRouteTable\outputs\diff
    - 하위에 Subnet별 디렉토리가 만들어지고 Effective Route 값이 다르다면 해당 디렉토리 하위에 파일이 생성됩니다.