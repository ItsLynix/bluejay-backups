# main menu
function Show-Menu {
    Clear-Host
    Write-Host "=== Backup Manager ==="
    Write-Host "1. Create Backup"
    Write-Host "2. Restore Backup"
    Write-Host "3. Patch a vendor image"
    Write-Host "4. Exit"
}

# create function
function Create-Backup {
    $script = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "windows\create.ps1"
    & $script
}

# restore function
function Restore-Backup {
    $script = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "windows\restore.ps1"
    & $script
}

# patch function
function Patch-Vendor {
    $script = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "windows\disencrypt-rwify-vendor.ps1"
    & $script
}

# main script
$warningFilePath = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "backup_warning.txt"

if (!(Test-Path $warningFilePath)) {
    Write-Host "To use this backup system, you need to modify your vendor partition to allow your data to be decrypted. Note that this means you'll have to flash the modified vendor with fastboot and then wipe data to make sure the data is not encrypted. You will also need to flash that vendor image every time you restore to the ROM. This backup system cannot be used to restore backups on a different ROM than the one it was taken on. This is useful for testing other ROMs and going back to your original one."

    $createPatchedVendor = Read-Host "Do you want to create a patched vendor image? (yes/no)"

    if ($createPatchedVendor.ToLower() -eq "yes") {
        Patch-Vendor
    }

    # Create the warning file to indicate that the message has been displayed
    New-Item -ItemType File -Path $warningFilePath -Force | Out-Null

    # Wait for input to continue
    Write-Host "`nPress any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

do {
    Show-Menu
    $input = Read-Host "Please select an option"

    switch ($input) {
        "1" { Create-Backup }
        "2" { Restore-Backup }
        "3" { Patch-Vendor }
        "4" { break }
        default { Write-Host "Invalid option selected." }
    }

    # Wait for input to continue
    Write-Host "`nPress any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} while ($input -ne "4")
