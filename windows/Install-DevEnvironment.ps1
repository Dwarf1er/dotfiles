# Main logic of the install script
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
	
	$session.Dispose()
	Write-Host "Installation process done."
}

# Install Windows Terminal
function Install-WindowsTerminal {
	param (
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    if (!(Get-AppxPackage -Name Microsoft.WindowsTerminal)) {
        Write-Host "Windows Terminal is not installed. Installing..."
        try {
            $url = "https://github.com/microsoft/terminal/releases/latest/"
            $request = [System.Net.WebRequest]::Create($url)
            $response = $request.GetResponse()
            $tagUrl = $response.ResponseUri.OriginalString
			$response.Dispose()
            $version = $tagUrl.Split("/")[-1].Trim("v")
            $fileName = "Microsoft.WindowsTerminal_$version_8wekyb3d8bbwe.msixbundle"
            $downloadUrl = $tagUrl.Replace("tag", "download") + "/" + $fileName
            $outputPath = "$env:TEMP\$fileName"
            Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -WebSession $Session

            # Verify if download was successful
            if (!(Test-Path $outputPath)) {
                throw "Failed to download Windows Terminal."
            }

            Add-AppxPackage -Path $outputPath -ErrorAction Stop

            Write-Host "Windows Terminal Installed."

            # Overwrite settings.json file
            Write-Host "Overwriting settings.json file..."
            $settingsJsonUrl = "https://raw.githubusercontent.com/Dwarf1er/dotfiles/master/windows/windows-terminal/settings.json"
            $settingsJsonFilePath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
            Invoke-WebRequest -Uri $settingsJsonUrl -OutFile $settingsJsonFilePath -WebSession $Session -ErrorAction Stop
            Write-Host "Settings.json file overwritten."

        } catch {
            Write-Host "An error occurred: $_"
            Write-Host "Failed to install Windows Terminal."
        } finally {
            Remove-Item $outputPath -Force
        }
    } else {
        Write-Host "Windows Terminal is already installed."
    }
}

# Install FiraCode Nerd Font
function Install-FiraCodeNerdFont {
	param (
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    $outputPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\FiraCodeNerdFontMono-Regular.ttf"
    
    try {
        Write-Host "Installing FiraCode NerdFont..."
        $url = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/FiraCode/Regular/FiraCodeNerdFontMono-Regular.ttf"
        Invoke-WebRequest -Uri $url -OutFile $outputPath -WebSession $Session -ErrorAction Stop

        Write-Host "FiraCode NerdFont installed."
    } catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install FiraCode NerdFont."
    }
}

# Install Oh My Posh
function Install-OhMyPosh {
	param (
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    $ohmyposhDirectory = "$env:LOCALAPPDATA\Programs\oh-my-posh"
    if (Test-Path $ohmyposhDirectory) {
        Write-Host "Removing existing Oh My Posh installation..."
        try {
            Remove-Item $ohmyposhDirectory -Recurse -Force
            Write-Host "Existing Oh My Posh installation removed."
        } catch {
            Write-Host "An error occurred while removing existing Oh My Posh installation: $_"
        }
    }
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

    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -WebSession $Session -ErrorAction Stop
        Start-Process $outputPath -ArgumentList "/SILENT" -Wait
        Write-Host "Oh My Posh installed."
    } catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install Oh My Posh."
    } finally {
        Remove-Item $outputPath -Force
    }
}

# Install WinFetch
function Install-WinFetch {
    Write-Host "Installing WinFetch..."
    try {
        Install-Script -Name pwshfetch-test-1 -Scope CurrentUser -Force -ErrorAction Stop
        Write-Host "WinFetch installed."
    } catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install WinFetch."
    }
}

# Install MinGW
function Install-MinGW {
	param (
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    $mingwDirectory = "$env:LOCALAPPDATA\Programs\mingw64"
    if (Test-Path $mingwDirectory) {
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
        Invoke-WebRequest -UserAgent "Wget/1.24.5" -Uri $downloadUrl -OutFile $outputPath -WebSession $Session -ErrorAction Stop

        Install-Module -Scope CurrentUser -Name 7Zip4Powershell -ErrorAction Stop
        Expand-7Zip -ArchiveFileName $outputPath -TargetPath "$env:LOCALAPPDATA\Programs" -ErrorAction Stop
        Write-Host "MinGW installed."
    } catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install MinGW."
    } finally {
        # Cleanup
        if (Test-Path $outputPath) {
            Remove-Item $outputPath -Force
        }
    }
}

# Install Neovim
function Install-Neovim {
	param (
        [Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )
    $neovimDirectory = "$env:LOCALAPPDATA\Programs\nvim"
    $neovimConfigDirectory = "$env:LOCALAPPDATA\nvim"
    $neovimDataDirectory = "$env:LOCALAPPDATA\nvim-data"
    try {
        if (Test-Path $neovimDirectory) {
            Write-Host "Removing existing Neovim installation..."
            Remove-Item $neovimDirectory -Recurse -Force
            Write-Host "Existing Neovim installation removed."
        }
        if (Test-Path $neovimConfigDirectory) {
            Write-Host "Removing existing Neovim configuration..."
            Remove-Item $neovimConfigDirectory -Recurse -Force
            Write-Host "Existing Neovim configuration removed."
        }
        if (Test-Path $neovimDataDirectory) {
            Write-Host "Removing existing Neovim data..."
            Remove-Item $neovimDataDirectory -Recurse -Force
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
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -WebSession $Session -ErrorAction Stop
        Expand-Archive -Path $outputPath -Destination "$env:LOCALAPPDATA\Programs" -Force
        Rename-Item -Path "$env:LOCALAPPDATA\Programs\nvim-win64" -NewName $neovimDirectory -Force
        Write-Host "Neovim installed."

        Write-Host "Downloading Neovim config files."
        $url = "https://github.com/Dwarf1er/dotfiles/archive/refs/heads/master.zip"
        $fileName = "master.zip"
        $outputPath = "$env:TEMP\$fileName"
        Invoke-WebRequest -Uri $url -OutFile $outputPath -WebSession $Session -ErrorAction Stop
        Expand-Archive -Path $outputPath -Destination "$env:TEMP" -Force
        Copy-Item -Path "$env:TEMP\dotfiles-master\.config\nvim" -Destination "$env:LOCALAPPDATA" -Recurse -Force
        Write-Host "Neovim config files downloaded."
    } catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install Neovim."
    } finally {
        # Cleanup
		if(Test-Path "$env:TEMP\nvim-win64.zip") {
			Remove-Item "$env:TEMP\nvim-win64.zip" -Force
		}
        if (Test-Path $outputPath) {
            Remove-Item $outputPath -Force
        }
        if (Test-Path "$env:TEMP\dotfiles-master") {
            Remove-Item -Path "$env:TEMP\dotfiles-master" -Recurse -Force
        }
    }
}

# Install Git
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
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -WebSession $Session -ErrorAction Stop
        Start-Process $outputPath -ArgumentList "/SILENT /INSTDIR=$env:LOCALAPPDATA\Programs" -Wait
        Write-Host "Git installed."
	} catch {
        Write-Host "An error occurred: $_"
        Write-Host "Failed to install Git."
    } finally {
        # Cleanup
        if (Test-Path $outputPath) {
            Remove-Item $outputPath -Force
        }
    }
}

# Create the PowerShell profile file
function New-PowerShellProfile {
    $powershellProfilePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    $powershellProfileContents = '
    & "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe" --init --shell pwsh --config "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\jandedobbeleer.omp.json" | Invoke-Expression
    & "C:\Users\$env:USERNAME\Documents\WindowsPowershell\Scripts\pwshfetch-test-1.ps1"
    $env:PATH += ";$env:LOCALAPPDATA\Programs\mingw64\bin"
    $env:PATH += ";$env:LOCALAPPDATA\Programs\nvim\bin"
    $env:PATH += ";$env:LOCALAPPDATA\Programs\Git\bin"
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
