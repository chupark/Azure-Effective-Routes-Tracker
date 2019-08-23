### 작성 중

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
main.ps1 파일을 실행시킵니다.

### 작업 스캐줄 설정
Windows의 경우 스케줄 작업
Linux에 PowerShell Core를 설치했을 경우 Cronjob을 추가 합니다.

--- 나중에 더 추가 