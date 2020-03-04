enum Mode {
    New
}

[DscResource()]
class ConfigurePandora
{
    [DscProperty(Key)]
    [string]$Selections

    [DscProperty(Mandatory)]
    [Mode]$Mode

    [void] Set()
    {
        if ($this.Mode -eq [Mode]::New)
        {
            $this.New()
        }
    }

    [bool] Test()
    {
        $present = $this.TestPandoraConfig()
        if ($this.Mode -eq [Mode]::New)
        {
            return $present
        }
        else 
        {
            return -not $present
        }
    }

    [ConfigurePandora] Get()
    {
        $present = $this.TestPandoraConfig()
        if ($present)
        {
            $this.Mode = [Mode]::New
        }

        return $this
    }

    [array] CopyModules()
    {
        $path = $null
        $items = $null
        $insertSelections = @()
        $modules = @()
        $getSelections = $this.Selections.split(",")
        for ($i = 0; $i -lt $getSelections.Count; $i++)
        {
            $insertSelections += $getSelections[$i]
        }

        if ($insertSelections)
        {
            foreach ($selection in $insertSelections)
            {
                switch ($selection)
                {
                    "Default"
                    {
                        $path = $null
                        $module = $null
                    }

                    "Microsoft SQL"
                    {
                        $path = "C:\Temp\AzPandora\Microsoft SQL"
                        $module = Get-Content -Path "$path\Microsoft SQL.txt"
                        $modules += $module
                    }

                    "SquareFootageWeb"
                    {
                        $path = "C:\Temp\AzPandora\SquareFootageWeb"
                        $module = Get-Content -Path "$path\SquareFootageWeb.txt"
                        $modules += $module
                    }
                }
                $pandoraPath = "C:\Program Files\pandora_agent"

                if ($path)
                {
                    $items = Get-ChildItem -Path $path -ea Ignore
                }

                if ($items)
                {
                    Write-Verbose "Copying selected modules"
                    foreach ($item in $items)
                    {
                        switch ($item.Name)
                        {
                            "util"
                            {
                                $originUtil = "$path\util"
                                $utilPath = "$pandoraPath"
                                $util = Get-ChildItem -Path $originUtil
                                foreach ($file in $util)
                                {
                                    Write-Verbose "Copying: $originUtil\$($file.Name)"
                                    Copy-Item -Path "$originUtil\$($file.Name)" -Destination "$utilPath\$($file.Name)" -Force
                                }
                            }
                    
                            "scripts"
                            {
                                $originScripts = "$path\scripts"
                                $scriptsPath = "$pandoraPath\scripts"
                                $scripts = Get-ChildItem -Path $originScripts
                                foreach ($file in $scripts)
                                {
                                    Write-Verbose "Copying: $originScripts\$($file.Name)"
                                    Copy-Item -Path "$originScripts\$($file.Name)" -Destination "$scriptsPath\$($file.Name)" -Force
                                }
                            }
                        }
                    }
                }
            }
        }
        return $modules
    }

    [void] New()
    {
        Stop-Service -Name PandoraFMSAgent -Force -ea Ignore
        Write-Verbose "Configuring Pandora FMS agent for the first time"
        $pandoraCfg = "C:\Temp\AzPandora\pandora_agent.conf"
        $pandoraPath = "C:\Program Files\pandora_agent"
        Copy-Item -Path $PandoraCfg -Destination "$pandoraPath\pandora_agent.conf" -Force
        $modules = $this.CopyModules()
        if ($modules)
        {
            Write-Verbose "Inserting modules into '$pandoraPath\pandora_agent.conf'"
            [System.Collections.ArrayList]$pandoraConfig = Get-Content -Path "$pandoraPath\pandora_agent.conf"
            $pandoraConfig.Add($modules) | Out-Null
            Set-Content -Value $pandoraConfig -Path "$pandoraPath\pandora_agent.conf" -Force
            $ip = (Test-Connection -ComputerName $env:COMPUTERNAME -Count 1).IPv4Address.IPAddressToString
            Write-Verbose "Inserting server IP '$ip' into '$pandoraPath\pandora_agent.conf'"
        }
        else 
        {
            $ip = (Test-Connection -ComputerName $env:COMPUTERNAME -Count 1).IPv4Address.IPAddressToString
            Write-Verbose "Inserting server IP '$ip' into '$pandoraPath\pandora_agent.conf'"    
        }

        $pandoraConfig = Get-Content -Path "$pandoraPath\pandora_agent.conf"
        $pandoraConfig[50] = "address $ip"
        Set-Content -Value $pandoraConfig -Path "$pandoraPath\pandora_agent.conf" -Force
        Write-Verbose "Starting 'Pandora Agent Service'"
        Start-Service -Name PandoraFMSAgent
    }

    [bool] TestPandoraConfig()
    {
        $ip = (Test-Connection -ComputerName $env:COMPUTERNAME -Count 1).IPv4Address.IPAddressToString
        $pandoraPath = "C:\Program Files\pandora_agent"
        $pandoraConfig = Get-Content -Path "$pandoraPath\pandora_agent.conf" -ea Ignore
        if ($pandoraConfig[50] -eq "address $ip")
        {
            return $true
        }
        else 
        {
            return $false
        }
    }
}