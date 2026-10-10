param([Parameter(Mandatory=$true)][string]$JsonPath)
$firebaseInput = Get-Content -LiteralPath $JsonPath -Raw | ConvertFrom-Json
$vireClient = $firebaseInput.client | Where-Object { $_.client_info.android_client_info.package_name -eq 'com.example.vire' } | Select-Object -First 1
if (-not $vireClient) { throw 'No Firebase Android client for com.example.vire was found.' }
$vireConfig = [ordered]@{
  FIREBASE_PROJECT_ID = $firebaseInput.project_info.project_id
  FIREBASE_SENDER_ID = $firebaseInput.project_info.project_number
  FIREBASE_APP_ID = $vireClient.client_info.mobilesdk_app_id
  FIREBASE_API_KEY = $vireClient.api_key[0].current_key
}
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot '../firebase-config.json'), ($vireConfig | ConvertTo-Json), [System.Text.UTF8Encoding]::new($false))
$vireNativePath = Join-Path $PSScriptRoot '../android/app/google-services.json'
if ([System.IO.Path]::GetFullPath($JsonPath) -ne [System.IO.Path]::GetFullPath($vireNativePath)) { Copy-Item -LiteralPath $JsonPath -Destination $vireNativePath }
Write-Output 'firebase-config.json created. Run Flutter with --dart-define-from-file=firebase-config.json.'
