enum Ensure {
    Absent
    Present
}

[DscResource()]
class DeployCode
{
    [DscProperty(Key)]
    [string]$Source

    [DscProperty(Mandatory)]
    [string]$Destination

    [DscProperty(Mandatory)]
    [string]$DotNetVersion

    [DscProperty(Mandatory)]
    [bool]$RsaKey

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [void] Set()
    {
        $exists = $this.TestSourceDestCount()
        if ($this.Ensure -eq [Ensure]::Present)
        {
            if (-not $exists)
            {
                $this.StartBuild()
            }
        }
        else 
        {
            if ($exists)
            {
                $this.RemoveBuild()
            }
        }
    }

    [bool] Test()
    {
        $present = $this.TestSourceDestCount()
        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $present
        }
        else 
        {
            return -not $present
        }
    }

    [DeployCode] Get()
    {
        $present = $this.TestSourceDestCount()

        if ($present)
        {
            $this.Ensure = [Ensure]::Present
        }
        else 
        {
            $this.Enusre = [Ensure]::Absent    
        }

        return $this
    }

    [bool] TestSourceDestCount()
    {
        $testSource = Get-ChildItem -Path "$($this.Source)\bin\Debug\$($this.DotNetVersion)\publish" -Recurse -ea SilentlyContinue
        $testDest = Get-ChildItem -Path $this.Destination -Recurse -ea SilentlyContinue
        
        if ($this.RsaKey)
        {
            $keyCount = 1
        } 
        else 
        {
            $keyCount = 0
        }

        if ($testSource -and $testDest)
        {
            if ($testSource.Count -eq ($testDest.Count - $keyCount)) 
            {
                return $true
            } else {
                return $false
            }
        } else {
            return $false
        }
    }

    [void] StartBuild()
    {
        $testPath = Test-Path -Path $this.Source -ea SilentlyContinue
        if ($testPath)
        {
            Set-Location -Path $this.Source
            Write-Verbose "Running .NET clean command..."
            dotnet clean | Write-Verbose
            Write-Verbose "Running .NET publish..."
            dotnet publish | Write-Verbose
        } else {
            throw "$($this.Source) is not a valid path"
        }

        Set-Location -Path "$($this.Source)\bin\debug\$($this.DotNetVersion)"
        $publishCode = Get-ChildItem -Path ".\publish" -ea SilentlyContinue
        if ($publishCode)
        {
            foreach ($file in $publishCode)
            {
                $root = $this.Destination
                $destinationTarget = "$($root)\$($file.Name)"
                $sourceTarget = ".\publish\$($file.Name)"
                Write-Verbose "Copying: '$sourceTarget' to '$destinationTarget'"
                Copy-Item -LiteralPath $sourceTarget -Destination $destinationTarget -Force -Recurse
            }
        } else {
            throw "Unable to collect files from repository"
        }
    }

    [void] RemoveBuild()
    {
        $removeCode = Get-ChildItem -Path $this.Destination
        foreach ($file in $removeCode)
        {
            $remove = "$($this.Destination)\$($file.Name)"
            Write-Verbose "Removing: '$remove'"
            Remove-Item -LiteralPath $remove -Force -Recurse
        }
    }
}