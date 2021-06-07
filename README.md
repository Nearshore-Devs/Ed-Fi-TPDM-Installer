# TPDM Installer with Descriptors

This repository provides a powershell binary installer that installs the Ed-Fi ODS/API 
with TPDM plugin.

Supports:

* Ed-Fi Data Standard 3.0 and higher
* Ed-Fi ODS/API Technical Suite 3, version 3.0 and higher

Quick Start
------------

We tried to make this Quick Start as easy as possible to demo.


Install Localy or on a VM
------------
To run this installer locally on your machine or on a virtual machine please follwo these steps:

**1)** Open a Windows PowerShell as and Administrator.
From the **Windows Menu**, search for **PowerShell**, right click on it, and select **Run as Administrator**
<br/><img src="img/powershell1.png" width="600" >

**2)** Run the automated installer by pasting this command in to the PowerShell window:
> Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://github.com/Nearshore-Devs/Ed-Fi-TPDM-Installer/raw/main/install.ps1'))

**3)** Once everything has finished installing you should see a browser stood up.


## Legal Information

Copyright (c) 2021 Ed-Fi Alliance, LLC and contributors.

Licensed under the [Apache License, Version 2.0](LICENSE) (the "License").

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

See [NOTICES](NOTICES.md) for additional copyright and license notifications.
