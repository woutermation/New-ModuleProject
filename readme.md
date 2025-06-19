# New-ModuleProject

Powershell script for starting a new Powershell module project

## Create new module

> &nbsp;  
> Navigate to the ModuleBuilder \ builder folder  
> &nbsp;

```powershell
$newModuleName = "VeryCoolModule"
.\New-ModuleProject.ps1 -Path ..\Modules\ -ModuleName $($newModuleName) -Prerequisites -Initialize -Scripts
```

Edit the [ ModuleName ]/Source/[ ModuleName.psd1 ], and apply all the settings:

- Author
- CompanyName
- Copyright
- Description
- ..

Now if you use my build.ps1 script you do not to have think about version control in your module.
The script will automatically calculate the correct version for you and provide the version to your Module manifest. It does this by calculating the number of cmdlets and function, and just append the build number by 1.
The only thing you would have to manually control is the Major versions. So if you had a new Major version change you would have to open the Module manifest located in: newmodule/Source/newmodule.psd1 and change the major version number.

Start with adding functions.

## Build

Once all the functions are created you van build the module.

Now to execute a debug build navigate to the root of my module folder, and run the following command:

> &nbsp;  
> Navigate to the new Module root folder  
> &nbsp;

```powershell
Invoke-Build -File ./build.ps1
```

A temp folder has been created inside the Output folder, and now you can test if the module actually works.

```powershell
Import-Module ./Output/temp/newmodule/0.0.1/newmodule.psm1
```

Test the module.

If testing is complete release the Build, run the following command:

```powershell
Invoke-Build -File ./build.ps1 -Configuration "Release"
```

## Source

[New-ModuleProjectNew-ModuleProject](https://github.com/hoejsagerc/New-ModuleProjectNew-ModuleProject)  
[how-to](https://scriptingchris.tech/2021/05/07/how-to-write-a-powershell-module/)

## Local linter

```bash
docker run --rm -e RUN_LOCAL=true --env-file "./.linter/super-linter.env" -v $PWD:/tmp/lint -w /tmp/lint ghcr.io/super-linter/super-linter:latest
```

```powershell
docker run --rm -e RUN_LOCAL=true --env-file "./.linter/super-linter.env" -v "$($PWD.Path):/tmp/lint" -w /tmp/lint ghcr.io/super-linter/super-linter:latest
```
