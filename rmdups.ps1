############### configure script settings ##########
 # Absolute path to directory where duplicates might exist. May contain trailing slash. Folders paths only.
$startingdir = "D:\duplicatesfolder" 

# The name of the directory name where duplicates will be moved. Cannot contain the following characters:/ \ : * ? < > |
# NOTE: only used when mode == 1
$dupdir = "!dup" 

# 0 - list duplicates only. will not move or delete duplicates. 
# 1 - move duped files to $dupdir that will be created.  
# 2 - delete files to recycle bin.
$mode = 0

# log the duplicates for reference (duplicates.log). Log file will be created in same directory as powershell script.
# 0 - log the duplicates to file.
# 1 - do not log the duplicates to file
$output = 1

# 0 - turn off debugging.
# 1 - turn on debugging. 
$debug = 0
#############################################################

# Check parameters for invalid characters.
if(!$(Test-Path $startingdir -PathType Container)) {
    Write-Host 'Invalid starting directory! Must be a folder. ' -ForegroundColor Yellow
    pause; exit
}if ($startingdir -match '[\*\"\?\<\>\|]'){
    Write-Host 'Invalid starting directory! May not contain characters: : * ? < > | ' -ForegroundColor Yellow
    pause; exit
}
if ($dupdir -match '[\/\\\:\*\"\?\<\>\|]'){
    Write-Host 'Invalid duplicates temp directory! May not contain characters: / \ : * ? < > | ' -ForegroundColor Yellow
    pause; exit
}
if(($mode -gt 2) -or ($mode -lt 0)) { 
    Write-Host "Invalid mode! May be between 0 and 2. `n0 - list only.   `n1 - move duped files to $dupdir that will be created.  `n2 - delete files to recycle bin." -ForegroundColor Yellow
    pause; exit
}
if(($output -gt 1) -or ($output -lt 0)) { 
    Write-Host "Invalid output mode! May be between 0 and 1. `n0 - log the duplicates to file.   `n1 - do not log the duplicates to file" -ForegroundColor Yellow
    pause; exit
}
if(($debug -gt 1) -or ($debug -lt 0)) { 
    Write-Host "Invalid debug mode! May be between 0 and 1. `n0 - turn off debugging.   `n1 - turn on debugging." -ForegroundColor Yellow
    pause; exit
}

# cd to directory where dups might exist
cd $startingdir

# Begin prompts to user to confirm
Write-Host "Are you sure you want to run the script? Press x to exit the script now"
$continue = Read-Host; If ($continue -eq "x" -or $continue -eq "X") {exit}
Write-Host "Are you absolutely sure you want to run the script? Press x to exit the script now"
$continue = Read-Host; If ($continue -eq "x" -or $continue -eq "X") {exit}
Write-Host "`n[Looking for duplicates...]`n" $cd

# recursively get only directories (i.e. directories and sub-directories and sub-sub-directories). store in array.
$containers = @( Get-Item -Path $startingdir | ? {$_.psIscontainer} )
$containers += Get-ChildItem -Directory -Path $startingdir -Recurse -Exclude $dupdir #| ? {$_.psIscontainer}  # exclude $dupdirs
#if($debug){echo $containers}

# For each directory, do
$containers | ForEach-Object {
    $j=0 # total dup count within this directory
    $t=0 # total file count within this directory
    $cd = $_.FullName # current directory's full path
    $cd_hash_dups = @{};  # declare/reset the current directory's dup store

    # store all files found only within this directory
    $files = Get-ChildItem -Path $cd -File | Sort-Object Name
    #if($debug){echo $files}
   
    # for each file, do
    :oloop foreach($f in $files) {
        $t++
        $hash_dups = @{}; # to store matches against this file. format: dupObj => thisObj
        $i=0 # against this file, number of matches 
        $f_md5 = Get-FileHash $f.PSPath -Algorithm MD5 # md5 hash of this file

        # skip over files already checked
		if($cd_hash_dups.ContainsKey($f)) {
            if($debug){Write-Host "`t>Skipping(oloop)......." $f} 
            continue oloop;
        }
		if($debug){Write-Host "`n[Looking in] -" $cd}
		
        # against this file, search through all files for dups
		:iloop foreach($_ in $files) {          
			# skip over dups alrdy stored in hash
		    if($cd_hash_dups.ContainsKey($_)) {if($debug){Write-Host "`t>Skipping(iloop)......." $_} continue iloop}

            $_md5 = Get-FileHash $_.PSPath -Algorithm MD5 # md5 hash of other file
            if($debug){Write-Host " - f.Name:" $f.Name "`t _Name" $_.Name}
            if($debug){Write-Host " - f.BaseName:" $f.BaseName "`t _BaseName" $_.BaseName}
            if($debug){Write-Host " - f.ext:" $f.Extension "`t _.ext:" $_.Extension}
            if($debug){Write-Host " - f dot count:"  "`t _ dot count:" ([regex]::Matches($_.Name, "\.").Count)}
            if($debug){Write-Host " - f md5:" $f_md5.Hash "`t _md5:" $_md5.Hash}

            # dup is found when: matches BaseName (i.e. removed path/extension), matches on size, last modified, number of periods (i.e. '.'), and hash.
			if(($_.Length -eq $f.Length) -and ($_.LastWriteTime.DateTime -eq  $f.LastWriteTime.DateTime) -and ($_.Extension -eq $f.Extension) -and ([regex]::Matches($f.Name, "\.").Count -eq ([regex]::Matches($_.Name, "\.").Count)) -and ($f_md5.Hash -eq $_md5.Hash) ) 
			{
				$i++;
				# store this first dup in hash
				if(!$hash_dups.ContainsKey($f)) {
					$hash_dups.add($_, $f ); # format: dupObj(key) => thisObj(value)
				}
				# store subsequent dups in hash
				if(!$hash_dups.ContainsKey($_)) {
					$hash_dups.add($_, $f ); # format: dupObj(key) => thisObj(value)
				}
				if($debug){Write-Host "`t> Match found. File comparison: `n`t`tname: $f" "`tlast modified:" $f.LastWriteTime "`tsize:" $f.Length " vs `n`t`tname:" $_ "`t`tlast modified:" $_.LastWriteTime "`tsize:" $_.Length;}
			 }else {
				if($debug){Write-Host " --- not a dupe ---" }
			 }
		}

		# if file matched itself only (i.e. 1 match) - no duplicates for this file. add to cd_hash to mark as done
		if($i -eq 1) { 
			$cd_hash_dups.add($f, $f ); # format: thisObj(key) => thisObj(value)
			if($debug){Write-Host "`t>No dups, Skipping(oloop)......." $_} 
		    if($debug){echo "-----#g----"}
		    if($debug){echo $cd_hash_dups}
			continue oloop;
		}

		# among dups, find the file with shortest file name. This will be the main/original file.
		$f_shortestName = $f.Name; 
		$len_shortest = $f.Name.Length;
		$hash_dups.GetEnumerator() | % { 
			$len = $_.Key.ToString().Length
			if($debug){Write-Host ">key: " $_.key "key length: $len" }
			if($len -lt $len_shortest) {
				$len_shortest = $len
				$f_shortestName = $_.Key.ToString()
				if($debug){Write-Host "(current) shortest string:" $len_shortest }
			}
		}

        # debug
		if($debug){echo "----#h(b4)-----"}
		if($debug){echo $hash_dups}
		if($debug){echo "----#h(af)-----"}
        
        # set main/original file name as value to all dups (All dups are mapped to the main/original file with the shortest name). then add them to cd_hash to mark as done
		foreach($key in $($hash_dups.keys)){
			$hash_dups[$key] = $f_shortestName
			# do not add global
			$cd_hash_dups.Add($key, $hash_dups[$key]) # format: dupObj(key) => oriObj(value)
		}
		
        # debug
        if($debug){echo $hash_dups}
		if($debug){echo "-----#cd----"}
		if($debug){echo $cd_hash_dups}
    }

    Write-Host "[Duplicates found in] " $cd

    if($mode -eq 0) {
        Write-Host "`tdup file`t`t`t`t`toriginal file`n`t----------`t`t`t`t`t--------------"
        $cd_hash_dups.GetEnumerator() | % {
            if($_.key.ToString() -ne $_.value.ToString()) { # exclude the original which has key==value
                Write-Host "`t" $_.key "`t`t`t`t`t"  $_.value 
            }
        }
    }elseif($mode -eq 1) {
        
        # create dup directory 
        $duppath = $cd + "\$dupdir"
        if(!$(Test-Path $duppath -PathType Container)) {
            New-Item -ItemType Directory -Force -Path $duppath
        }
        # move files
        $cd_hash_dups.GetEnumerator() | % { 
            if($debug){Write-Host "key vs value: " $_.key $_.value}
            if($_.key.ToString() -ne $_.value.ToString()) { # exclude the original which has key==value
                $j++
                $f = $_.key;
                Write-Host "`t`tMoving dup file  to: $dupdir\$f"
                Move-Item "$cd\$f" "$duppath\$f"
            }
        }   
    }elseif($mode -eq 2) {
        # delete files to recycle bin
        $cd_hash_dups.GetEnumerator() | % { 
            
            if($_.key.ToString() -ne $_.value.ToString()) { # exclude the original which has key==value
                $j++
                $f = $_.key
                $path = $cd + "\" + $f
                $shell = new-object -comobject "Shell.Application"
                $item = $shell.Namespace(0).ParseName("$path")
                $item.InvokeVerb("delete")
                # dont use Remove-item, it permanently deletes
                #Remove-item $falses
            }
        }

    }
	
    # show summary only if dups exist
    if ($j) {Write-Host " -summary: non-dup count:$($t-$j) vs dup count:$j vs total: $t"}
    
 }

if($output -eq 1) {
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path output.txt -append
# do some stuff
Stop-Transcript
}

pause


