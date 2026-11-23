param(
    [string]$Repo = "locsummer/network-analyzer-wifi-scan"
)

Write-Host "Monitoring GitHub Actions iOS build for $Repo..." -ForegroundColor Cyan

while ($true) {
    try {
        $runs = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/actions/runs?per_page=5" -Headers @{"User-Agent"="PowerShell"}
        $latest = $runs.workflow_runs | Where-Object { $_.name -match "Build iOS IPA" } | Select-Object -First 1

        if ($latest) {
            Write-Host "Run ID: $($latest.id) | Status: $($latest.status) | Conclusion: $($latest.conclusion)" -ForegroundColor Yellow

            if ($latest.status -eq "completed") {
                if ($latest.conclusion -eq "success") {
                    Write-Host "Build successful! Checking for Release or Artifacts..." -ForegroundColor Green

                    # 1. Try Release download
                    try {
                        $releaseUrl = "https://github.com/$Repo/releases/download/v1.0.0/NetworkAnalyzer.ipa"
                        Write-Host "Downloading from Release: $releaseUrl" -ForegroundColor Cyan
                        Invoke-WebRequest -Uri $releaseUrl -OutFile "NetworkAnalyzer.ipa"
                        Write-Host "Downloaded NetworkAnalyzer.ipa successfully!" -ForegroundColor Green
                        break
                    } catch {
                        Write-Host "Release asset not ready yet, checking artifacts..." -ForegroundColor Yellow
                    }

                    # 2. Try nightly.link
                    try {
                        $nightlyUrl = "https://nightly.link/$Repo/workflows/build-ios/master/NetworkAnalyzer-iOS-IPA.zip"
                        Write-Host "Downloading from nightly.link: $nightlyUrl" -ForegroundColor Cyan
                        Invoke-WebRequest -Uri $nightlyUrl -OutFile "NetworkAnalyzer-IPA.zip"
                        Expand-Archive -Path "NetworkAnalyzer-IPA.zip" -DestinationPath "." -Force
                        Remove-Item "NetworkAnalyzer-IPA.zip" -Force
                        Write-Host "Extracted NetworkAnalyzer.ipa successfully!" -ForegroundColor Green
                        break
                    } catch {
                        Write-Host "Error downloading artifact: $_" -ForegroundColor Red
                    }
                } else {
                    Write-Host "Workflow finished with conclusion: $($latest.conclusion)" -ForegroundColor Red
                    break
                }
            }
        }
    } catch {
        Write-Host "Error polling GitHub: $_" -ForegroundColor Red
    }

    Start-Sleep -Seconds 20
}
