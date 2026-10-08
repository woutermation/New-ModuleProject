<#
.SYNOPSIS
    Creates a new PowerShell module project scaffold.

.DESCRIPTION
    Generates a module folder structure, creates the module manifest, and optionally installs the
    required tooling and downloads the default Invoke-Build script used to test, build, and publish
    the module.

    This script is based on the original work by Christian Hoejsager (GitHub: hoejsagerc), whose
    project was the starting point for this module scaffolding workflow. The upstream project is no
    longer actively maintained, so this version continues the same functionality as a forked/custom
    build on top of the original implementation.

    Original project: https://github.com/hoejsagerc/New-ModuleProject/
    Additional guidance: https://scriptingchris.tech/new-moduleproject_ps1/

.EXAMPLE
    PS C:\> .\New-ModuleProject.ps1 -Path '.\' -ModuleName 'MyTestModule' -Prerequisites -Initialize -Scripts

    Creates the following structure under the provided path:

    MyTestModule\
        |_ Docs\
        |_ Output\
        |_ Source\
        |   |_ Public\
        |   |_ Private\
        |   |_ MyTestModule.psd1
        |_ Tests\
        |_ build.ps1

    The script also ensures the required development modules are installed and downloads the default
    build script for the project.

.PARAMETER Path
    The parent folder where the new module should be created. This is the folder that contains the
    module folder itself, not the module folder name.

.PARAMETER ModuleName
    The name of the new module. This value is used as the folder name and module manifest name.

.PARAMETER Prerequisites
    If specified, installs the modules required for building, testing, publishing, and help generation:
    PowerShellGet, PSScriptAnalyzer, Pester, platyPS, and InvokeBuild.

.PARAMETER Initialize
    If specified, creates the standard folder structure for the module project.

.PARAMETER Scripts
    If specified, creates the module manifest and downloads the default build script from the project
    repository.

.PARAMETER RemoveExistingModule
    If specified, removes an existing module folder at the target path before creating the new one.

.INPUTS
    None. You cannot pipe objects to this script.

.OUTPUTS
    None. The script creates files and folders on disk.

.NOTES
    Original author/developer: Christian Hoejsager (hoejsagerc)
    Based on the original New-ModuleProject work by hoejsagerc.
    This version is maintained as a fork/custom continuation of that project.
    Project: New-ModuleProject
    Original GitHub: https://github.com/hoejsagerc/New-ModuleProject/
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
        Creates a folder at the specified path if it does not already exist.
    .DESCRIPTION
        Ensures that the requested folder structure exists. Parent folders are created automatically.
        If the -removeIfPresent switch is supplied, an existing folder at the same path is removed first
        before the folder is recreated.
    .PARAMETER folderPath
        The full path of the folder to create.
    .PARAMETER removeIfPresent
        Removes the folder at the target path before recreating it.
    .EXAMPLE
        Add-Folder -folderPath '.\result\$tenantId'

        Creates the nested folder structure for the specified tenant path if it does not already exist.
    .EXAMPLE
        Add-Folder -folderPath 'C:\Temp\result' -removeIfPresent

        Deletes any existing folder at that path and recreates it.
    .INPUTS
        None. You cannot pipe input to this function.
    .OUTPUTS
        None. This function writes status information through verbose logging and does not return a value.
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
