Write-Host "
  ______ _ _        _____       _                  _ _           __  __             _ _             
 |  ____(_) |      |_   _|     | |                (_) |         |  \/  |           (_) |            
 | |__   _| | ___    | |  _ __ | |_ ___  __ _ _ __ _| |_ _   _  | \  / | ___  _ __  _| |_ ___  _ __ 
 |  __| | | |/ _ \   | | | '_ \| __/ _ \/ _` | '__| | __| | | | | |\/| |/ _ \| '_ \| | __/ _ \| '__|
 | |    | | |  __/  _| |_| | | | ||  __/ (_| | |  | | |_| |_| | | |  | | (_) | | | | | || (_) | |   
 |_|    |_|_|\___| |_____|_| |_|\__\___|\__, |_|  |_|\__|\__, | |_|  |_|\___/|_| |_|_|\__\___/|_|   
                                         __/ |            __/ |                                     
                                        |___/            |___/                           @inukashi               
"



Function Calculate-File-Hash($filepath){
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline-If-Already-Exists(){
    $baselineExists = Test-Path -Path .\baseline.txt    

    if ($baselineExists) {
        # Delete it
        Remove-Item -Path .\baseline.txt
    }
}


while(1){
    
    Write-Host "`nWhat do you want to do ?`n"
    Write-Host "     1. Collect new Baseline ?"
    Write-Host "     2. Begin Monitoring Files with saved Baseline ?"
    Write-Host "     3. Exit Script`n"

    $response = Read-Host -Prompt ("Please Enter '1' or '2'")

    Switch ($response)
    {
        1 { # delete baseline if it already exists
            Erase-Baseline-If-Already-Exists
            
            # Calculate Hash from the target files and store in baseline.txt
            
            # Collect all the files in the target folder
            $files = Get-ChildItem -Path .\Files

            # For each file, calculte the hash, and write to baseline.txt
            foreach ($f in $files){
                $hash = Calculate-File-Hash $f.FullName
                "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
            }

            Write-Host "Calculating Hashs, and Making a new baseline.txt" -ForegroundColor Cyan
            #break (use break or exit according to need ; if we want to loop then use break , otherwise to directly get out of script use end)
            exit
          }

        2 { Write-Host "Reading Existing baseline.txt, and also Starting to Monitor Files. " -ForegroundColor Green

            $fileHashDictionary = @{}
        
            #Load file | hash from baseline.txt adn store then in a dictionary
            $filePathsAndHashes = Get-Content -Path .\baseline.txt
            
            foreach ($f in $filePathsAndHashes){
                $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
            }

            # Begin (Continuously) Monitoring files with saved Baseline
            while($true){
                Start-Sleep -Seconds 1

                $files = Get-ChildItem -Path .\Files

                # For each file, calculte the hash, and write to baseline.txt
                foreach ($f in $files){
                    $hash = Calculate-File-Hash $f.FullName
                    #"$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append

                    # Notify if a new file has been created
                    if($fileHashDictionary[$hash.Path] -eq $null){
                        # A new file has been created!
                        Write-Host "$($hash.Path) has been created!" -ForegroundColor DarkYellow
                    }
                    else {
                        # Notify if a file has been changed
                        if($fileHashDictionary[$hash.Path] -eq $hash.Hash){
                            # The file has not changed
                        }
                        else {
                            # File has been Compromised! Notify the user
                            Write-Host "$($hash.Path) has changed!!!" -ForegroundColor Blue
                        }
                    }
                }

                foreach ($key in $fileHashDictionary.Keys){
                    $baselineFileStillExists = Test-Path -Path $key
                    if (-Not $baselineFileStillExists) {
                        # One of the baseline files must have been deleted! Notify the user
                        Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed -BackgroundColor Gray

                    }
                }
            }
            
            #break
            exit
           }

        3 {exit}
        default {"No Action !!! `nPlease Enter '1' or '2'"}
    }
}