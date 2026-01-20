# Define the payload
$body = @{
    username = "maheshpanta2_admin"
    email    = "panta2@admin.com"
    password = "12345678"
    is_admin = "True" # Use $true (boolean) instead of "True" (string)
} | ConvertTo-Json

# Execute the POST request
$params = @{
    Uri         = "http://127.0.0.1:6969/auth/signup"
    Method      = "POST"
    Headers     = @{ "Content-Type" = "application/json; charset=utf-8" }
    Body        = $body
}

try {
    Invoke-RestMethod @params
} catch {
    $_.Exception.Response.GetResponseStream() | ForEach-Object {
        $reader = New-Object System.IO.StreamReader($_)
        $reader.ReadToEnd()
    }
}
Write-Host "Action completed successfully!" -ForegroundColor Green