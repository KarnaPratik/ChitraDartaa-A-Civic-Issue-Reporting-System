# Define the payload
$body = @{
    username = "mahesh_admin"
    email    = "panta@gmail.com"
    password = "12345678"
    is_admin = $true
} | ConvertTo-Json

# Execute the POST request
$params = @{
    Uri         = "http://127.0.0.1:6969/auth/signup"
    Method      = "POST"
    Headers     = @{ "Content-Type" = "application/json; charset=utf-8" }
    Body        = $body
}

Invoke-RestMethod @params