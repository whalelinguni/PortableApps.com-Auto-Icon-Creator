cls

# save script dir
$scriptDir = $PWD

# Path to ResourcesExtract.exe
$resourcesExtractPath = Join-Path -Path $scriptDir -ChildPath "\ResourcesExtract.exe"

# Output directory to save the PNG file
$outputDirectory = $PWD

#debug
#Write-Host "Script Path: "$scriptDir
#Write-Host "ResourcesExtract.exee Path: "$resourcesExtractPath

# Path to the executable file from which to extract the icon
Write-Host "Enter the full path to the applications main exe residing in the application folder. Do NOT use the portable launcher exe!"
Write-Host "Ex: App\AppName\AppName.exe"
$exePath = Read-Host "Enter Path"

Write-Host " "
Write-Host "#####---   Starting ICO and PNG operations  ---#####"
Write-Host " "
Write-Host "[#] Starting process to create application icon ..."
$portableDir = Split-Path (Split-Path $exePath -Parent) -Parent
$portableAppInfo = Join-Path -Path $portableDir -ChildPath "\AppInfo"

# Ensure the output directory exists
if (-not (Test-Path -Path $outputDirectory -PathType Container)) {
    New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
}

Write-Host "[-] Extracting icon resources from exe ..."
# Construct the command to extract the icon
$command = "& '$resourcesExtractPath' /source '$exePath' /ExtractIcons 1 /FileExistMode 1 /OpenDestFolder 0 /DestFolder '$outputDirectory'"

# Execute the command
Invoke-Expression -Command $command

Start-Sleep -Seconds 3 #script too fast.
Write-Host "[+] Resources extracted."

# Get the extracted icon file

$iconFiles = Get-ChildItem -Path $outputDirectory -Filter "*.ico" | Select-Object -First 1

# Check if an icon file was found
if ($iconFiles) {
    $iconFile = $iconFiles.FullName
    Write-Host "[#] Icon extracted and saved as: $iconFile"
} else {
    Write-Host "Failed to extract the icon."
}

Write-Host "[-] Creating appicon.ico from extraction ..."

# Move the file referenced by $iconFile to "appicon.ico"
Move-Item -Path $iconFile -Destination "appicon.ico" -Force

# Update $iconFile to point to the new location
$iconFile = "appicon.ico[0]"

Write-Host "[+] appicon.ico created!"

Write-Host "[#] Starting process to create app pngs ..."

#convert to pngs
# Specify the sizes of the icons
$iconSizes = @("16", "32", "75", "128")

# Loop through each size and generate the corresponding icon
foreach ($size in $iconSizes) {
    Write-Host "[-] Generating appicon_$size.png"
    $convertExe = Join-Path -Path $scriptDir -ChildPath "\ImageMagick\convert.exe"
    $command = "& '$convertExe' '$iconFile' -thumbnail x$size appicon_$size.png"
    Invoke-Expression -Command $command
    Write-Host "[+] appicon_$size.png created!"
}

Write-Host "[+] PNG files created sucessfully!"

Write-Host "[-] Merging files into app directory ..."

$filesToMove = @(
    "appicon.ico",
    "appicon_16.png",
    "appicon_32.png",
    "appicon_75.png",
    "appicon_128.png"
)

foreach ($file in $filesToMove) {
    Move-Item -Path $file -Destination "$portableAppInfo\$file" -Force
}
Write-Host "[+] Files merged sucessfully!"
Write-Host " "
Write-Host "#####---  ICO and PNG operations complete.  ---#####"
Write-Host " "