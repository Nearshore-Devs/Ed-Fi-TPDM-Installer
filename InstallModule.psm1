# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

############################################################
 
# Author: Douglas Loyo, Sr. Solutions Architect @ MSDF
 
# Description: Wrapper script that downloads the necesarry binaries and executes Ed-Fi installers.

############################################################

# 0) Helper Functions

Function Write-HostInfo($message) { 
    $divider = "----"
    for($i=0;$i -lt $message.length;$i++){ $divider += "-" }
    Write-Host $divider -ForegroundColor Cyan
    Write-Host " " $message -ForegroundColor Cyan
    Write-Host $divider -ForegroundColor Cyan 
}

Function Write-HostStep($message) { 
    Write-Host "*** " $message " ***"-ForegroundColor Green
}

Function Find-SoftwareInstalled($software) {
    # To debug use this in your powershell
    # (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName
    return (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -Contains $software
}

Function Install-Chrome {
    if(!(Find-SoftwareInstalled "Google Chrome"))
    {
        Write-Host "Installing: Google Chrome..."
        choco install googlechrome -y --ignore-checksums
    }else{Write-Host "Skipping: Google Chrome as it is already installed."}
}

Function Install-MsSSMS {
    if(!(Find-SoftwareInstalled 'SQL Server Management Studio'))
    {
        Write-Host "Installing: SSMS  Sql Server Management Studio..."
        choco install sql-server-management-studio -y
    }else{Write-Host "Skipping: SSMS  Sql Server Management Studio as it is already installed."}
}

Function Install-Chocolatey(){
    if(!(Test-Path "$($env:ProgramData)\chocolatey\choco.exe"))
    {
        #Ensure we use the windows compression as we have had issues with 7zip
        $env:chocolateyUseWindowsCompression = 'true'
        Write-Host "Installing: Cocholatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }else{Write-Host "Skipping: Cocholatey is already installed."}
}

Function Install-IISPrerequisites() {
    $allPreReqsInstalled = $true;
    # Throw this infront 'IIS-ASP', to make fail.
    $prereqs = @('IIS-WebServerRole', 'IIS-WebServer', 'IIS-CommonHttpFeatures', 'IIS-HttpErrors', 'IIS-ApplicationDevelopment', 'NetFx4Extended-ASPNET45', 'IIS-NetFxExtensibility45', 'IIS-HealthAndDiagnostics', 'IIS-HttpLogging', 'IIS-Security', 'IIS-RequestFiltering', 'IIS-Performance', 'IIS-WebServerManagementTools', 'IIS-ManagementConsole', 'IIS-BasicAuthentication', 'IIS-WindowsAuthentication', 'IIS-StaticContent', 'IIS-DefaultDocument', 'IIS-ISAPIExtensions', 'IIS-ISAPIFilter', 'IIS-HttpCompressionStatic', 'IIS-ASPNET45');
    # 'IIS-IIS6ManagementCompatibility','IIS-Metabase', 'IIS-HttpRedirect', 'IIS-LoggingLibraries','IIS-RequestMonitor''IIS-HttpTracing','IIS-WebSockets', 'IIS-ApplicationInit'?

    Write-Host "Ensuring all IIS prerequisites are already installed."
    foreach ($p in $prereqs) {
        if ((Get-WindowsOptionalFeature -Online -FeatureName $p).State -eq "Disabled") { $allPreReqsInstalled = $false; Write-Host "Prerequisite not installed: $p" }
    }

    if ($allPreReqsInstalled) { Write-Host "Skipping: All IIS prerequisites are already installed." }
    else { Enable-WindowsOptionalFeature -Online -FeatureName $prereqs }
}

Function Find-IfMsSQLServerInstalled($serverInstance) {
    If(Test-Path 'HKLM:\Software\Microsoft\Microsoft SQL Server\Instance Names\SQL') { return $true }
    try {
        $server = New-Object Microsoft.SqlServer.Management.Smo.Server $serverInstance
        $ver = $server.Version.Major
        Write-Host " MsSQL Server version detected :" $ver
        return ($ver -ne $null)
    }
    Catch {return $false}
    
    return $false
}

Function Install-MsSQLServerExpress {
    if(!(Find-IfMsSQLServerInstalled "."))
    {
        Write-Host "Installing: MsSQL Server Express..."
        choco install sql-server-express -o -ia "'/IACCEPTSQLSERVERLICENSETERMS /Q /ACTION=install /INSTANCEID=MSSQLSERVER /INSTANCENAME=MSSQLSERVER /SECURITYMODE=SQL /SAPWD=EdfiUs3r /TCPENABLED=1 /UPDATEENABLED=FALSE'" -f -y
        #Refres env and reload path in the Shell
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        refreshenv

        # Test to see if we need to close PowerShell and reopen.
        # If .Net is already installed then we need to check to see if the MsSQL commands for SMO are avaialble.
        # We do this check because if .net is not installed we will reboot later.
        if((IsNetVersionInstalled 4 8)){
            If(-Not (Find-PowershellCommand Restore-SqlDatabase)) {
                # Will need to restart so lets give the user a message and exit here.
                Write-BigMessage "SQl Server Express Requires a PowerShell Session Restart" "Please close this PowerShell window and open a new one as an Administrator and run install again."
                Write-Error "Please restart this Powershell session/window and try again." -ErrorAction Stop
            }
        }
    } else {
        Write-Host "Skipping: MsSQL Express there is already a SQL Server installed."
    }
}

Function IsNetCoreVersionInstalled($version) {
    $DotNetCoreItems = Get-Item -ErrorAction SilentlyContinue -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Updates\.NET Core'
    $DotNetCoreItems.GetSubKeyNames() | Where-Object { $_ -Match "Microsoft .NET Core $version.*Windows Server Hosting" } | ForEach-Object {
        Write-Host "The host has installed $_"
        return $True
    }
    
    return $False
}

Function Install-NetCoreHostingBundle() {
    $ver = "3.1.12"
    if (!(IsNetCoreVersionInstalled $ver)) {
        Write-Host "Installing: .Net Core Version $ver"
        choco install dotnetcore-windowshosting --version=$ver -y
        # Will need to restart so lets give the user a message and exit here.
        Write-Host ".Net Core Hosting Bundle May Require a Restart. Please restart this computer and re run the install."
        Write-Error "Please Restart" -ErrorAction Stop
    }
    else { Write-Host "Skiping: .Net Core Version $ver as it is already installed." }
}

Function Install-EdFiPackageSource() {
    $isPackageSourceInstalled = (Get-PackageSource).Name -Contains 'EdFi@Release';
    if($isPackageSourceInstalled){
        Write-Host "Skipping registration of Ed-Fi Pacakge Source as it is already installed"
    }else{
        Write-Host "Installing Ed-Fi Pacakge Source..."
        Register-PackageSource -Name EdFi@Release -Location https://pkgs.dev.azure.com/ed-fi-alliance/Ed-Fi-Alliance-OSS/_packaging/EdFi%40Release/nuget/v2/ -ProviderName NuGet -Force
    }
}

Function Install-EdFiDatabases($dbBinaryPath) {
    $configurationJsonFilePath = $dbBinaryPath + "configuration.json"
    # Load the JSON file and update config settings.
    $configJson = (Get-Content $configurationJsonFilePath | Out-String | ConvertFrom-Json)

    $connStrings = @{
        EdFi_Ods= "server=(local);trusted_connection=True;database=EdFi_{0};Application Name=EdFi.Ods.WebApi";
        EdFi_Admin = "server=(local);trusted_connection=True;database=EdFi_Security;persist security info=True;Application Name=EdFi.Ods.WebApi";
        EdFi_Security= "server=(local);trusted_connection=True;database=EdFi_Admin;Application Name=EdFi.Ods.WebApi";
        EdFi_Master= "server=(local);trusted_connection=True;database=master;Application Name=EdFi.Ods.WebApi";
    }

    $configJson.ApiSettings.Mode = "Sandbox";
    $configJson.ApiSettings.Engine = "SQLServer";
    $configJson.ApiSettings.MinimalTemplateScript = "EdFiMinimalTemplate";
    $configJson.ApiSettings.PopulatedTemplateScript = "GrandBend";

    $configJson.ConnectionStrings = $connStrings;

    # Update File
    $configJson | ConvertTo-Json -depth 100 | Out-File $configurationJsonFilePath

    $pathDbInstallScript = $dbBinaryPath + "PostDeploy.ps1"

    Invoke-Expression -Command $pathDbInstallScript
}

Function Install-EdFiAPI($dbBinaryPath) {

    $parameters = @{
        PackageVersion = "5.2.14406"
        DbConnectionInfo = @{
            Engine="SqlServer"
            Server="localhost"
            UseIntegratedSecurity=$true
        }
        InstallType = "Sandbox"   
    }

    $path = "$dbBinaryPath"+"Install-EdFiOdsWebApi.psm1"
    Write-Host $path;

    Import-Module $path

    Install-EdFiOdsWebApi @parameters
}

Function Install-EdFiDocs($dbBinaryPath) {

    $computerName = [System.Net.Dns]::GetHostName()

    $parameters = @{
        PackageVersion = "5.2.14406"
        WebApiVersionUrl = "https://$computerName/WebApi"
    }

    $path = "$dbBinaryPath"+"Install-EdFiOdsSwaggerUI.psm1"

    Import-Module $path

    Install-EdFiOdsSwaggerUI @parameters
}

Function Install-EdFiSandboxAdmin($dbBinaryPath) {

    $computerName = [System.Net.Dns]::GetHostName()

    $parameters = @{
    PackageVersion = "5.2.14406"
    OAuthUrl = "https://$computerName/WebApi"
}

    $path = "$dbBinaryPath"+"Install-EdFiOdsSandboxAdmin.psm1"

    Import-Module $path

    Install-EdFiOdsSandboxAdmin @parameters
}

Function Install-EdFi520Sandbox {

    # 1) Ensure the working directories exists
    $pathToWorkingDir = "C:\Ed-Fi\BinWrapper\"

    Write-Host "Step: Ensuring working path is accessible. (pathToWorkingDir)"
    New-Item -ItemType Directory -Force -Path $pathToWorkingDir

    Write-Host "Step: Ensure Prerequisits are installed."

    ## Install Prerequisits ##
    # Ensure the EdFi PackageSource is installed:
    Install-EdFiPackageSource
    Install-Chocolatey
    Install-IISPrerequisites
    Install-NetCoreHostingBundle
    Install-MsSQLServerExpress

    Write-Host "Step: Downloading all binaries."

    $binaries = @(  
            @{  name = "EdFi.Suite3.Installer.WebApi"; version = "5.2.59"; }
		    @{  name = "EdFi.Suite3.Installer.SwaggerUI"; version = "5.2.42"; }
		    @{  name = "EdFi.Suite3.Installer.SandboxAdmin"; version = "5.2.62"; }
		    @{  name = "EdFi.Suite3.RestApi.Databases"; version = "5.2.14406"; }
    )

    foreach ($b in $binaries) {
        Write-Host "Downloading " $b.name
        # Download
        Save-Package -Name $b.name -ProviderName NuGet -Source EdFi@Release -Path $pathToWorkingDir -RequiredVersion $b.version

        # Rename to .Zip
        $nupkgFileName = $b.name + "." + $b.version + ".nupkg"
        $srcPath = "$pathToWorkingDir\" + $nupkgFileName
        $zipFileName = $b.name + ".zip"
        $zipPath = "$pathToWorkingDir\" + $zipFileName

        if(Test-Path $zipPath){ Remove-Item $zipPath }
        Rename-Item -Path $srcPath -NewName $zipFileName -Force

        # UnZip them to the destination fodlers.
    
        $installPath = "$pathToWorkingDir\" + $b.name
    
        Expand-Archive -LiteralPath $zipPath -DestinationPath $installPath -Force
    }

    # Install EdFi Databases
    $dbBinaryPath = "$pathToWorkingDir" + $binaries[3].name + "\"
    Install-EdFiDatabases $dbBinaryPath

    # Install EdFi API
    $apiBinaryPath = "$pathToWorkingDir" + $binaries[0].name + "\"
    Install-EdFiAPI $apiBinaryPath

    # Install EdFi Docs / Swagger
    $docsBinaryPath = "$pathToWorkingDir" + $binaries[1].name + "\"
    Install-EdFiDocs $docsBinaryPath

    # Install EdFi Sandbox Admin
    $sandboxAdminBinaryPath = "$pathToWorkingDir" + $binaries[2].name + "\"
    Install-EdFiSandboxAdmin $sandboxAdminBinaryPath
}