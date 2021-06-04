# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

############################################################
 
# Author: Douglas Loyo, Sr. Solutions Architect @ MSDF
 
# Description: Wrapper script that downloads the necesarry binaries and executes Ed-Fi installers.

############################################################
#Requires -Version 5
#Requires -RunAsAdministrator

Import-Module .\InstallModule -Force

Write-HostInfo "Wrapper for the Ed-Fi binary installers."
Write-Host "To install Ed-Fi run any of the following commands:" 
Write-HostStep " Ed-Fi ODS/APi & Tools 5.2.0"
Write-Host " Install-EdFi520Sandbox"
Write-Host " Install-EdFi520SharedInstance"
Write-Host " Install-EdFi520SandboxTPDM"
Write-Host " Install-EdFi520SharedInstanceTPDM"
Write-HostStep " Other Tools:"
Write-Host "    Install-TPDMDescriptors 'apiURL' 'key' 'secret'"
Write-Host "    Install-Chocolatey" 
Write-Host "    Install-Chrome" 
Write-Host "    Install-MsSSMS"
Write-Host "    Install-NotepadPlusPlus"
Write-Host ""