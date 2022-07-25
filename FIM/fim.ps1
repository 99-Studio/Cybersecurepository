Write-Host "What would you like to do?"
Write-Host "1 Collect new Baseline"
Write-Host "1 Begin monitoring files with saved Baseline?"

$response = Read-Host -Prompt "Please enter 'A' or 'B'"

Write-Host "User entered $($response)"

Function Calculate-File-Hash($filepath){
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA256
    return $filehash
}

Function Erase-Baseline-If-Already-Exists(){
    $baselineExists = Test-Path -Path .\baseline.txt

    if ($baselineExists) {
        #Delete it
        Remove-Item -Path .\baseline.txt
    }
}

if ($response -eq "A".ToUpper()) {
    #Calcule le hash du fichier cible et le stock dans le fichier baseline.txt


    Erase-Baseline-If-Already-Exists
    #Collect all files in the target folder
    $files = Get-ChildItem -Path .\Files

    #For each file, calculate the hash, and write to baseline.txt
    foreach ($f in $files){
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }

}
elseif ($response -eq "B".ToUpper()) {
    #Commence a monitorer les fichiers dans la Baseline sauvegardée
    $fileHashDictionnary =@{}
    $filePathesandHashes = Get-Content -Path .\baseline.txt

    foreach ($f in $filePathesandHashes) {
        $fileHashDictionnary.add($f.Split("|")[0],$f.Split("|")[1])
    }
    
    while($true){
        Start-Sleep -Seconds 1
        
        $files = Get-ChildItem -Path .\Files

        foreach ($f in $files) {
            $hash = Calculate-File-Hash $f.FullName
            #"$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append

            #Notifiy if a new file has been created
            if ($fileHashDictionnary[$hash.Path] -eq $null){
                # A new file has been created
                Write-Host "$($hash.Path) has been created" -ForegroundColor Green
            }
            else{

                #Notify if a new file has been changed
                if ($fileHashDictionnary[$hash.Path] -eq $hash.Hash){
                    #The file has not changed
                }
                else {
                    #The file has been compromise
                    Write-Host "$($hash.Path) has changed" -ForegroundColor Red
                }
            }

            foreach ($key in $fileHashDictionnary.Keys) {
                $baselineFileStillExists = Test-Path -Path $key
                if (-Not $baselineFileStillExists) {
                    #One of the baseline files have been deleted
                    Write-Host "$($key) has been deleted" -ForegroundColor DarkRed
                }
            }
        }
    }
}