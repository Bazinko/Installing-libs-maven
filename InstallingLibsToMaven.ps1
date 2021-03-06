$libsDest = "C:\Users\92sergeevem\IdeaProjects\SAT-VT-CBRF"
$extractDest = "$env:USERPROFILE\Desktop\Dependencies"
$fullFileNames = Get-ChildItem "$libsDest\lib" -recurse | where-object { $_.PSIsContainer -eq $false } | Select-Object -ExpandProperty FullName
$fileNames = Get-ChildItem "$libsDest\lib" -recurse | where-object { $_.PSIsContainer -eq $false } | Select-Object -ExpandProperty Name
$deps = "$extractDest\test.txt"

mkdir "$env:USERPROFILE\Desktop\Dependencies"
Out-File $deps

for ($i=0; $i -lt $fileNames.length; $i++) {
    mkdir $("$extractDest\" + $fileNames[$i])
    cd $("$extractDest\" + $fileNames[$i])
    jar xf $fullFileNames[$i] META-INF
    $collector = $fileNames[$i].split('.')
    if ($collector.length -gt 4) {
        for ($j=0; $j -lt 3; $j++) {
            if ($j -eq 2) { $DgroupId += $collector[$j] } else { $DgroupId += $collector[$j] + "." }
        }
        for ($j=3; $j -lt $collector.length-1; $j++) {
            if ($j -eq $collector.length-2) { $DartifactId += $collector[$j] } else { $DartifactId += $collector[$j] + "." }
        }
     } elseif ($collector.length -eq 4) {
              for ($j=0; $j -lt 2; $j++) {
                  if ($j -eq 1) { $DgroupId += $collector[$j] } else { $DgroupId += $collector[$j] + "." }
              }
              for ($j=2; $j -lt $collector.length-1; $j++) {
                  if ($j -eq $collector.length-2) { $DartifactId += $collector[$j] } else { $DartifactId += $collector[$j] + "." }
              }
     } elseif ($collector.length -lt 3) { $DgroupId = $collector[0]; $DartifactId = $collector[0] } 
       elseif ($collector.length -eq 3) { $DgroupId = $collector[0]; $DartifactId = $collector[1] }
     
     if (Test-Path $("$extractDest\" + $fileNames[$i] + "\META-INF\MANIFEST.MF")) {
        $firstPattern = Select-String $("$extractDest\" + $fileNames[$i] + "\META-INF\MANIFEST.MF") -Pattern "Specification-Version" -CaseSensitive | Select-Object -ExpandProperty Line
        if ([string]::IsNullOrEmpty($firstPattern) -eq $false) {
            $firstPattern = $firstPattern.split(' ')
            $check = $firstPattern[1].split('.')
            if ([bool]($check[0] -as [int])) { $Dversion = $firstPattern[1] } else { $Dversion = "1" }
        } else {
            $check = $DartifactId.split('_')
            if ([string]::IsNullOrEmpty($check[1]) -eq $false) { $Dversion = $check[1] } else { $Dversion = "1" }
        }
     } else { $Dversion = "1" }
     
     cd $libsDest
     write-host $("mvn install:install-file " + '"' + "-Dfile=" + $fullFileNames[$i] + '"' + ' "' + "-DgroupId=$DgroupId" + `
            '"' + ' "' + "-DartifactId=$DartifactId" + '"' + ' "' + "-Dversion=$Dversion" + '"' + ' "' + "-Dpackaging=jar" + '"')
     Invoke-Expression $("mvn install:install-file " + '"' + "-Dfile=" + $fullFileNames[$i] + '"' + ' "' + "-DgroupId=$DgroupId" + `
            '"' + ' "' + "-DartifactId=$DartifactId" + '"' + ' "' + "-Dversion=$Dversion" + '"' + ' "' + "-Dpackaging=jar" + '"')
            
     $checkFullPath = $fullFileNames[$i].split('\')
     $checkLibPath = $libsDest.split('\')
     for ($v=$checkLibPath.length; $v -lt $checkFullPath.length-1; $v++) {
         $buildedPath += $checkFullPath[$v] + "/" 
     }
     
     $dependency  = "<!--$buildedPath-->`r`n"
     $dependency += "    <dependency>`r`n"
     $dependency += "        <groupId>$DgroupId</groupId>`r`n"
     $dependency += "        <artifactId>$DartifactId</artifactId>`r`n"
     $dependency += "        <version>$Dversion</version>`r`n"
     $dependency += "    </dependency>`n`n"
     $dependency | Out-File $deps -Append
     
     $pathBuilded=""; $DgroupId=""; $DartifactId=""; $Dversion=""; $buildedPath=""
}