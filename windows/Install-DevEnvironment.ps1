function Main {
	Write-Host "Starting installation process..."
	$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
	
	Install-WindowsTerminal -Session $session
	Install-FiraCodeNerdFont -Session $session
	Install-OhMyPosh -Session $session
	Install-WinFetch
	Install-MinGW -Session $session
	Install-Neovim -Session $session
	Install-Git -Session $session
	New-PowerShellProfile
	
	Write-Host "Installation process done."
}

function Install-WindowsTerminal {
	param (
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    if (-not (Get-AppxPackage -Name Microsoft.WindowsTerminal)) {
        Write-Host "Windows Terminal is not installed. Installing..."
        try {
            $url = "https://github.com/microsoft/terminal/releases/latest/"
            $request = [System.Net.WebRequest]::Create($url)
            $response = $request.GetResponse()
            $tagUrl = $response.ResponseUri.OriginalString
			$response.Dispose()
            $version = $tagUrl.Split("/")[-1].Trim("v")
            $fileName = "Microsoft.WindowsTerminal_$version`_8wekyb3d8bbwe.msixbundle"
			Write-Host $filename $version
            $downloadUrl = $tagUrl.Replace("tag", "download") + "/" + $fileName
            $outputPath = "$env:TEMP\$fileName"
            Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -WebSession $Session

            if (-not (Test-Path -Path $outputPath)) {
                throw "Failed to download Windows Terminal."
            }

            Add-AppxPackage -Path $outputPath -ErrorAction Stoprun

            Write-Host "Windows Terminal Installed."

            Write-Host "Overwriting settings.json file..."
            $settingsJsonUrl = "https://raw.githubusercontent.com/Dwarf1er/dotfiles/master/windows/windows-terminal/settings.json"
            $settingsJsonFilePath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
            Invoke-WebRequest -Uri $settingsJsonUrl -OutFile $settingsJsonFilePath -WebSession $Session
            Write-Host "Settings.json file overwritten."

        } catch {
            Write-Host "An error occurred: $_"
            Write-Host "Failed to install Windows Terminal."
        } finally {
			if ($outputPath -ne $null -and (Test-Path -Path $outputPath)) {
				Remove-Item $outputPath -Force
			}
        }
    } else {
        Write-Host "Windows Terminal is already installed."
    }
}

function Install-FiraCodeNerdFont {
	param (
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    $outputPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    
    try {
        Write-Host "Installing FiraCode NerdFont..."
		if (-not (Test-Path -Path $outputPath)) {
            Write-Host "Creating directory: $outputPath"
            New-Item -Path $outputPath -ItemType Directory | Out-Null
        }
        $url = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/FiraCode/Regular/FiraCodeNerdFontMono-Regular.ttf"
		$outputPath += "\FiraCodeNerdFontMono-Regular.ttf"
        Invoke-WebRequest -Uri $url -OutFile $outputPath -WebSession $Session
		
		$destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
		$destination.CopyHere($outputPath, 0x10)

        Write-Host "FiraCode NerdFont installed."
    } catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install FiraCode NerdFont."
    } finally {
		if ($outputPath -ne $null -and (Test-Path -Path $outputPath)) {
			Remove-Item $outputPath -Force
		}
	}
}

function Install-OhMyPosh {
	param (
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    $ohmyposhDirectory = "$env:LOCALAPPDATA\Programs\oh-my-posh"
    if (Test-Path -Path $ohmyposhDirectory) {
        Write-Host "Removing existing Oh My Posh installation..."
        try {
            Remove-Item $ohmyposhDirectory -Recurse -Force
            Write-Host "Existing Oh My Posh installation removed."
        } catch {
            Write-Host "An error occurred while removing existing Oh My Posh installation: $_"
        }
    }

    try {
		Write-Host "Installing Oh My Posh..."
		$url = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest"
		$request = [System.Net.WebRequest]::Create($url)
		$response = $request.GetResponse()
		$tagUrl = $response.ResponseUri.OriginalString
		$response.Dispose()
		$version = $tagUrl.Split("/")[-1].Trim("v")
		$fileName = "install-amd64.exe"
		$downloadUrl = $tagUrl.Replace("tag", "download") + "/" + $fileName
		$outputPath = "$env:TEMP\$fileName"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -WebSession $Session
        Start-Process $outputPath -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /CURRENTUSER" -Wait
        Write-Host "Oh My Posh installed."
    } catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install Oh My Posh."
    } finally {
		if ($outputPath -ne $null -and (Test-Path -Path $outputPath)) {
			Remove-Item $outputPath -Force
		}
    }
}

function Install-WinFetch {
    Write-Host "Installing WinFetch..."
    try {
		Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Script -Name pwshfetch-test-1 -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "WinFetch installed."
    } catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install WinFetch."
    }
}

function Install-MinGW {
	param (
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    $mingwDirectory = "$env:LOCALAPPDATA\Programs\mingw64"
    if (Test-Path -Path $mingwDirectory) {
        Write-Host "Removing existing MinGW installation..."
        try {
            Remove-Item $mingwDirectory -Recurse -Force
            Write-Host "Existing MinGW installation removed."
        } catch {
            Write-Host "An error occurred while removing existing MinGW installation: $_"
        }
    }
    Write-Host "Installing MinGW..."
    try {
        $url = "https://sourceforge.net/projects/mingw-w64/files/"
        $response = Invoke-WebRequest -Uri $url

        $hrefTitleDict = @{}

        foreach($link in $response.Links) {
            $hrefTitleDict[$link.href] = $link.innerText
        }
		$response.Dispose()

        $downloadUrl = ($hrefTitleDict.GetEnumerator() | Where-Object { $_.Value -eq "x86_64-posix-seh" }).Key[0]
        $fileName = "mingw.7z"
        $outputPath = "$env:TEMP\$fileName"
        Invoke-WebRequest -UserAgent "Wget/1.24.5" -Uri $downloadUrl -OutFile $outputPath -WebSession $Session

        Install-Module -Scope CurrentUser -Name 7Zip4Powershell -ErrorAction Stop
        Expand-7Zip -ArchiveFileName $outputPath -TargetPath "$env:LOCALAPPDATA\Programs"
        Write-Host "MinGW installed."
    } catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install MinGW."
    } finally {
        if ($outputPath -ne $null -and (Test-Path -Path $outputPath)) {
            Remove-Item $outputPath -Force
        }
    }
}

function Install-Neovim {
	param (
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    $neovimDirectory = "$env:LOCALAPPDATA\Programs\nvim"
    $neovimConfigDirectory = "$env:LOCALAPPDATA\nvim"
    $neovimDataDirectory = "$env:LOCALAPPDATA\nvim-data"
    try {
        if (Test-Path -Path $neovimDirectory) {
            Write-Host "Removing existing Neovim installation..."
            Remove-Item $neovimDirectory -Recurse -Force
            Write-Host "Existing Neovim installation removed."
        }
        if (Test-Path -Path $neovimConfigDirectory) {
            Write-Host "Removing existing Neovim configuration..."
            Remove-Item $neovimConfigDirectory -Recurse -Force
            Write-Host "Existing Neovim configuration removed."
        }
        if (Test-Path -Path $neovimDataDirectory) {
            Write-Host "Removing existing Neovim data..."
	    # Remove-Item is still broken when there are symbolic links, see: https://github.com/powershell/powershell/issues/621
            cmd /c rmdir /s /q $neovimDataDirectory
            Write-Host "Existing Neovim data removed."
        }

        Write-Host "Installing Neovim..."
        $url = "https://github.com/neovim/neovim/releases/latest"
        $request = [System.Net.WebRequest]::Create($url)
        $response = $request.GetResponse()
        $tagUrl = $response.ResponseUri.OriginalString
		$response.Dispose()
        $version = $tagUrl.Split("/")[-1].Trim("v")
        $fileName = "nvim-win64.zip"
        $downloadUrl = $tagUrl.Replace("tag", "download") + "/" + $fileName
        $outputPath = "$env:TEMP\$fileName"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -WebSession $Session
        Expand-Archive -Path $outputPath -Destination "$env:LOCALAPPDATA\Programs" -Force
        Rename-Item -Path "$env:LOCALAPPDATA\Programs\nvim-win64" -NewName $neovimDirectory -Force
        Write-Host "Neovim installed."

        Write-Host "Downloading Neovim config files."
        $url = "https://github.com/Dwarf1er/dotfiles/archive/refs/heads/master.zip"
        $fileName = "master.zip"
        $outputPath = "$env:TEMP\$fileName"
        Invoke-WebRequest -Uri $url -OutFile $outputPath -WebSession $Session
        Expand-Archive -Path $outputPath -Destination "$env:TEMP" -Force
        Copy-Item -Path "$env:TEMP\dotfiles-master\.config\nvim" -Destination "$env:LOCALAPPDATA" -Recurse -Force
        Write-Host "Neovim config files downloaded."
    } catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install Neovim."
    } finally {
		if(Test-Path -Path "$env:TEMP\nvim-win64.zip") {
			Remove-Item "$env:TEMP\nvim-win64.zip" -Force
		}
        if ($outputPath -ne $null -and (Test-Path -Path $outputPath)) {
            Remove-Item $outputPath -Force
        }
        if (Test-Path -Path "$env:TEMP\dotfiles-master") {
            Remove-Item -Path "$env:TEMP\dotfiles-master" -Recurse -Force
        }
    }
}

function Install-Git {
	param (
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    Write-Host "Installing Git..."
    try {
		$url = "https://github.com/git-for-windows/git/releases/latest"
        $request = [System.Net.WebRequest]::Create($url)
        $response = $request.GetResponse()
        $tagUrl = $response.ResponseUri.OriginalString
        $version = $tagUrl.Split("/")[-1].Trim("v")
		$response.Dispose()
        $fileName = "Git-" + $version.Substring(0,6) + "-64-bit.exe"
        $downloadUrl = $tagUrl.Replace("tag", "download") + "/" + $fileName
        $outputPath = "$env:TEMP\$fileName"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -WebSession $Session
		$gitOptions = @"
[Setup]
Lang=default
Dir=$env:LOCALAPPDATA\Programs\Git
Group=Git
NoIcons=1
SetupType=default
Components=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh,scalar
Tasks=
EditorOption=VIM
CustomEditorPath=
DefaultBranchOption=
PathOption=Cmd
SSHOption=OpenSSH
TortoiseOption=false
CURLOption=OpenSSL
CRLFOption=CRLFAlways
BashTerminalOption=MinTTY
GitPullBehaviorOption=Merge
UseCredentialManager=Enabled
PerformanceTweaksFSCache=Enabled
EnableSymlinks=Enabled
EnablePseudoConsoleSupport=Disabled
EnableFSMonitor=Disabled
"@
		$gitOptions | Set-Content -Path "$env:TEMP\git_options.ini"
        Start-Process $outputPath -ArgumentList "/SILENT /LOADINF=$env:TEMP\git_options.ini" -Wait
        Write-Host "Git installed."
	} catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install Git."
    } finally {
        if ($outputPath -ne $null -and (Test-Path -Path $outputPath)) {
            Remove-Item $outputPath -Force
        }
		if (Test-Path -Path "$env:TEMP\git_options.ini") {
            Remove-Item "$env:TEMP\git_options.ini" -Force
        }
    }
}

function New-PowerShellProfile {
    $powershellProfilePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    $powershellProfileContents = ""
    	if (-not (Get-AppxPackage -Name Microsoft.WindowsTerminal)) {
		$powershellProfileContents += '
Set-ItemProperty -Path "HKCU:\Console" -Name "FaceName" -Value "FiraCode Nerd Font Mono"
Set-ItemProperty -Path "HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe" -Name "FaceName" -Value "FiraCode Nerd Font Mono"
'
	}
 
    $powershellProfileContents += '`
& "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe" --init --shell pwsh --config "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\jandedobbeleer.omp.json" | Invoke-Expression
& "C:\Users\$env:USERNAME\Documents\WindowsPowershell\Scripts\pwshfetch-test-1.ps1"
$env:PATH += ";$env:LOCALAPPDATA\Programs\mingw64\bin"
$env:PATH += ";$env:LOCALAPPDATA\Programs\nvim\bin"
$env:PATH += ";$env:LOCALAPPDATA\Programs\Git\bin"
Set-Location -Path "$env:USERPROFILE"
'
	
    try {
        $powershellProfileContents | Out-File -FilePath $powershellProfilePath -Force -ErrorAction Stop
        Write-Host "PowerShell profile created successfully."
    } catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to create PowerShell profile."
    }
}

Main
