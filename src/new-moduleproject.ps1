<#PSScriptInfo
.VERSION
1.3.10

.GUID
55ef3a83-4365-4e5e-844b-6ab2d323963b

.AUTHOR
Christian Hoejsager

.COMPANYNAME
ScriptingChris

.COPYRIGHT
Copyright (c) 2021 ScriptingChris

.TAGS
module project build

.LICENSEURI
https://scriptingchris.tech/posts/how-to-get-started-developing-a-powershell-module/

.PROJECTURI
https://github.com/hoejsagerc/New-ModuleProject

.ICONURI


.EXTERNALMODULEDEPENDENCIES


.REQUIREDSCRIPTS


.EXTERNALSCRIPTDEPENDENCIES


.RELEASENOTES
Created a lot of bug fixes to the build.ps1 script.
Added the the process of exporting aliases from the public functions aswell

#>

<#
.SYNOPSIS
Script for easily creating a new module projects folder
.DESCRIPTION
Script which quickly creates a folder structure, Module Manifest and downloads a build.ps1 script
to use with Invoke-Build module for easy developing, maintaining, building and publishing your
powershell module.
Follow project at: https://github.com/hoejsagerc/New-ModuleProject/
For in-depth help: https://scriptingchris.tech/new-moduleproject_ps1/
.EXAMPLE
PS C:\> New-ModuleProject.ps1 -Path ".\" -ModuleName "MyTestModule" -Prerequisites -Initialize -Scripts

This script will create a new folder structure in the path: ".\"
It will create the following folder structure:

MyTestModule\
    |_Docs\
    |_Output\
    |_Source\
    |   |_Public\
    |   |_Private\
    |   |_MyTestModule.psd1
    |_Tests\
    |_build.ps1

It will then make sure you have to follwoing modules installed:
- PowerSehllGet (For publishing modules)
- PlatyPS (For managing Help documentation)
- Pester (For Unit Testing)
- PSScriptAnalyzer (For Lint analyzing scripts)
- InvokeBuild (For building the module)

It will then download the build.ps1 script from the GitHub repository
https://raw.githubusercontent.com/hoejsagerc/New-ModuleProject/main/Source/build.ps1

The build script will be used for testing, building and publishing the module.
Help to use the build script can be found here: https://scriptingchris.tech/new-moduleproject_ps1/
.PARAMETER Path
Provide the Path to where the module should be placed (without the module name itself)
.PARAMETER ModuleName
Provice the name of your module
.PARAMETER Prerequisites
Parameter which will tricker installing of several modules:
- PowerShellGet
- PlatyPS
- Pester
- InvokeBuild
.PARAMETER Initialize
Parameter which will tricker the creation of the Module folder structure.
.PARAMETER Scripts
Parameter which will tricker the download of the default build script from:
https://raw.githubusercontent.com/hoejsagerc/New-ModuleProject/main/Source/build.ps1
.INPUTS
N/A
.OUTPUTS
N/A
.NOTES
N/A
#>


Param(
    [Parameter(Mandatory = $True)][String]$Path,
    [Parameter(Mandatory = $True)][String]$ModuleName,
    [Parameter(Mandatory = $false)][Switch]$Prerequisites,
    [Parameter(Mandatory = $true)][Switch]$Initialize,
    [Parameter(Mandatory = $false)][Switch]$Scripts,
    [Parameter(Mandatory = $false)][Switch]$RemoveExistingModule
)

#Region - Add-Folder
function Add-Folder
{
    <#
    .SYNOPSIS
        Create new folder
    .DESCRIPTION
        This functions will create a new folder if the folder does not exist
        The complete path can be specified all parent folders are created
    .PARAMETER folderPath
        The path of the new folder
    .EXAMPLE
        Add-Folder -folderPath .\result\$tenantId
    .EXAMPLE
        Add-Folder -folderPath C:\Temp\result
    .INPUTS
        folderPath
    .OUTPUTS
        The created folder, or nothing if it exists
    .NOTES
        Author: Wouter de Dood
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$folderPath,
        [Parameter(Mandatory = $false)]
        [switch]$removeIfPresent
    )
    begin
    {
        $functionName = $($MyInvocation.MyCommand.Name)
        Write-Verbose -Message "[$($functionName)] - Start process for folder [ $($folderPath) ]"
    }
    process
    {
        if ((Test-Path $folderPath) -and $removeIfPresent.IsPresent)
        {
            try
            {
                Write-Verbose -Message "[$($functionName)] - Folder [ $($folderPath) ] already exists, removing it"
                Remove-Item -Path $folderPath -Recurse -Force
            }
            catch
            {
                Write-Error -Message "[$($functionName)] - $($_.Exception.Message)"
                throw($($_.Exception.Message))
            }
        }
        if (!(Test-Path $folderPath))
        {
            try
            {
                New-Item -ItemType Directory -Path $folderPath | Out-Null
                Write-Verbose -Message "[$($functionName)] - Folder [ $($folderPath) ] created"
            }
            catch
            {
                Write-Error -Message "[$($functionName)] - $($_.Exception.Message)"
                throw($($_.Exception.Message))
            }
        }
        else
        {
            Write-Verbose -Message "[$($functionName)] - Folder [ $($folderPath) ] already exists, skipping creation"
        }
    }
    end
    {
        Write-Verbose -Message "[$($functionName)] - End process for folder [ $($folderPath) ]"
    }
}
#EndRegion


#Region - Prerequisites
if ($Prerequisites.IsPresent)
{
    Write-Verbose -Message "Initializing Module PowerShellGet"
    if (-not(Get-Module -Name PowerShellGet -ListAvailable))
    {
        Write-Warning "Module 'PowerShellGet' is missing or out of date. Installing module now."
        Install-Module -Name PowerShellGet -Scope CurrentUser -Force
    }

    Write-Verbose -Message "Initializing Module PSScriptAnalyzer"
    if (-not(Get-Module -Name PSScriptAnalyzer -ListAvailable))
    {
        Write-Warning "Module 'PSScriptAnalyzer' is missing or out of date. Installing module now."
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
    }

    Write-Verbose -Message "Initializing Module Pester"
    if (-not(Get-Module -Name Pester -ListAvailable))
    {
        Write-Warning "Module 'Pester' is missing or out of date. Installing module now."
        Install-Module -Name Pester -Scope CurrentUser -Force -MinimumVersion 5.1.1 -SkipPublisherCheck
    }

    Write-Verbose -Message "Initializing platyPS"
    if (-not(Get-Module -Name platyPS -ListAvailable))
    {
        Write-Warning "Module 'platyPS' is missing or out of date. Installing module now."
        Install-Module -Name platyPS -Scope CurrentUser -Force
    }

    Write-Verbose -Message "Initializing InvokeBuild"
    if (-not(Get-Module -Name InvokeBuild -ListAvailable))
    {
        Write-Warning "Module 'InvokeBuild' is missing or out of date. Installing module now."
        Install-Module -Name InvokeBuild -Scope CurrentUser -Force -AllowClobber
    }
}
#EndRegion - Prerequisites

#Region - Initialize
if ($Initialize.IsPresent)
{
    Write-Verbose -Message "Creating Module folder structure $($RemoveExistingModule)"
    Add-Folder -folderPath "$($Path)\$($ModuleName)" -removeIfPresent:$($RemoveExistingModule)

    $subFolders = @("Source\Private", "Source\Public", "Tests", "Output", "Docs")
    foreach ($subFolder in $subFolders)
    {
        $fullPath = Join-Path -Path "$($Path)\$($ModuleName)" -ChildPath $subFolder
        Add-Folder -folderPath $fullPath -removeIfPresent:$($RemoveExistingModule)
    }
}
#EndRegion - Initialize

#Region - Scripts
if ($Scripts.IsPresent)
{
    if (Test-Path "$($Path)\$($ModuleName)")
    {
        Write-Verbose -Message "Creating the Module Manifest"
        New-ModuleManifest -Path "$($Path)\$($ModuleName)\Source\$($ModuleName).psd1" -ModuleVersion "0.0.1"
    }

    Write-Verbose -Message "Downloading build script from: https://raw.githubusercontent.com/woutermation/New-ModuleProject/refs/heads/main/src/build.ps1"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/woutermation/New-ModuleProject/refs/heads/main/src/build.ps1" -OutFile "$($Path)\$($ModuleName)\build.ps1"

    if (Test-Path "$($Path)\$($ModuleName)\build.ps1")
    {
        Write-Verbose -Message "Build script was downloaded successfully"
    }
    else
    {
        throw "Failed to download the build script from: https://raw.githubusercontent.com/woutermation/New-ModuleProject/refs/heads/main/src/build.ps1"
    }
}
#EndRegion - Scripts
