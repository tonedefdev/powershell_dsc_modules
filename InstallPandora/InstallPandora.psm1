enum Ensure {
    Absent
    Present
}

[DscResource()]
class InstallPandora
{
    [DscProperty(Key)]
    [string]$InstallPath

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [void] Set()
    {
        $exists = $this.TestPandora()
        if ($this.Ensure -eq [Ensure]::Present)
        {
            if (-not $exists)
            {
                Write-Verbose "Installing Pandora FMS"
                Start-Process -FilePath $this.InstallPath -ArgumentList "/S"
                $pandoraCheck = $false
                while (-not $pandoraCheck)
                {
                    [bool]$pandoraCheck = Test-Path -Path "C:\Program Files\pandora_agent\PandoraAgent.exe"
                    Write-Verbose "Waiting for Pandora to finish installation"
                    Start-Sleep -Seconds 5
                }
            }
        }
        else 
        {
            if ($exists)
            {
                Write-Verbose "Removing Pandora FMS"
                Start-Process -FilePath $this.InstallPath -ArgumentList "/U"
            }
        }
    }

    [bool] Test()
    {
        $present = $this.TestPandora()
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else 
        {
            return -not $present
        }
    }

    [InstallPandora] Get()
    {
        $present = $this.TestPandora()
        if ($present)
        {
            $this.Ensure = [Ensure]::Present
        }
        else 
        {
            $this.Ensure = [Ensure]::Absent
        }

        return $this
    }

    [bool] TestPandora()
    {
        [bool]$pandoraCheck = Test-Path -Path "C:\Program Files\pandora_agent\PandoraAgent.exe"
        if ($pandoraCheck)
        {
            return $true
        }
        else 
        {
            return $false
        }
    }
}