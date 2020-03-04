enum Ensure {
    Absent
    Present
}

[DscResource()]
class DownloadPackages
{
    [DscProperty(Key)]
    [string]$DownloadSourceURI

    [DscProperty(Mandatory)]
    [string]$Destination

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty(NotConfigurable)]
    [Nullable[datetime]]$CreationTime

    [void] Set()
    {
        $fileExists = $this.TestFilePath($this.Destination)
        if ($this.Ensure -eq [Ensure]::Present)
        {
            if (-not $fileExists)
            {
                $this.StartDownload()
            }
        }
        else 
        {
            if ($fileExists)
            {
                Write-Verbose -Message "Deleting the file $($this.Destination)"
                Remove-Item -LiteralPath $this.Destination -Force
            }    
        }
    }

    [bool] Test()
    {
        $present = $this.TestFilePath($this.Destination)

        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        } else {
            return -not $present
        }
    }

    [DownloadPackages] Get()
    {
        $present = $this.TestFilePath($this.Destination)

        if ($present)
        {
            $file = Get-ChildItem -LiteralPath $this.Destination
            $this.CreationTime = $file.CreationTime
            $this.Ensure = [Ensure]::Present
        }
        else 
        {
            $this.CreationTime = $null
            $this.Ensure = [Ensure]::Absent    
        }

        return $this
    }

    [bool] TestFilePath([string]$location)
    {
        $present = $true
        $item = Get-ChildItem -LiteralPath $location -ea Ignore
        if (!($item))
        {
            $present = $false
        }
        elseif ($item.PSProvider.Name -ne "FileSystem")
        {
            throw "Path $($location) is not a file path."
        }
        elseif ($item.PsIsContainer)
        {
            throw "Path $($location) is a directory path."
        }
        return $present
    }

    [void] StartDownload()
    {
        Invoke-WebRequest -Uri $this.DownloadSourceURI -OutFile $this.Destination -Verbose
    }
}