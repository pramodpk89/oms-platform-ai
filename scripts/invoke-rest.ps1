param([string]$Environment, [string]$ConfigDir, [Parameter(Mandatory=$true)][string]$RequestFile,
      [switch]$ConfirmedWrite, [ValidateRange(1,300)][int]$TimeoutSeconds = 30,
      [ValidateRange(256,32768)][int]$MaxResponseChars = 4000)
. "$PSScriptRoot/shared/Common.ps1"
Add-Type -AssemblyName System.Net.Http
$c = Get-OmsContext $Environment $ConfigDir
$credential = Get-OmsCredential $c 'rest'
$request = Read-JsonFile $RequestFile
if (!$c.Settings.rest.baseUrl) { throw 'REST base URL is not configured; do not guess it.' }
$base = [Uri]$c.Settings.rest.baseUrl
if (!$base.IsAbsoluteUri -or $base.Scheme -notin @('https','http') -or $base.UserInfo -or $base.Query -or $base.Fragment) { throw 'Invalid REST base URL.' }
if ($base.Scheme -eq 'http' -and !$base.IsLoopback) { throw 'Use HTTPS for non-local environments.' }
$path = [string]$request.path
if ($path.StartsWith('/') -or $path.Contains('\') -or $path.Contains(':') -or $path.Contains('#') -or [Uri]::UnescapeDataString($path).Split('?')[0].Split('/') -contains '..') { throw 'Use a relative endpoint inside the configured REST base URL.' }
$uri = New-Object Uri ([Uri]($base.AbsoluteUri.TrimEnd('/') + '/')), $path
if ($uri.GetLeftPart([UriPartial]::Authority) -ne $base.GetLeftPart([UriPartial]::Authority) -or !$uri.AbsolutePath.StartsWith($base.AbsolutePath.TrimEnd('/') + '/')) { throw 'Endpoint escapes the configured REST base.' }
$method = ([string]$request.method).ToUpperInvariant()
if ($method -notin @('GET','HEAD','OPTIONS','POST','PUT','PATCH','DELETE')) { throw 'Unsupported HTTP method.' }
$effect = [string]$request.effect
if ($effect -notin @('read','write')) { throw 'Request must declare effect: read or write, based on API documentation.' }
if ($method -in @('PUT','PATCH','DELETE') -and $effect -ne 'write') { throw 'This method requires effect: write.' }
if ($effect -eq 'write' -and !$ConfirmedWrite) { throw 'Confirm this environment, operation, and target with the user; then pass -ConfirmedWrite.' }
$handler = New-Object Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $false
$client = New-Object Net.Http.HttpClient $handler
$client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
$message = New-Object Net.Http.HttpRequestMessage (New-Object Net.Http.HttpMethod $method), $uri
$authText = ''
try {
    switch ($c.Settings.rest.auth) {
        'basic' {
            if (!$credential.username -or !$credential.password) { throw 'Missing REST username/password.' }
            $authText = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($credential.username + ':' + $credential.password))
            $message.Headers.Authorization = New-Object Net.Http.Headers.AuthenticationHeaderValue 'Basic', $authText
        }
        'bearer' {
            if (!$credential.token) { throw 'Missing REST token.' }
            $authText = $credential.token
            $message.Headers.Authorization = New-Object Net.Http.Headers.AuthenticationHeaderValue 'Bearer', $authText
        }
        'headers' {
            if (@($credential.headers.PSObject.Properties).Count -eq 0) { throw 'Configure REST authentication headers.' }
            foreach ($h in $credential.headers.PSObject.Properties) {
                if ($h.Name -match '^(Host|Content-Length|Transfer-Encoding|Connection)$') { throw 'Unsupported authentication header.' }
                $message.Headers.Add($h.Name, [string]$h.Value)
            }
        }
        'none' {}
        default { throw 'Unsupported REST authentication mode.' }
    }
    if ($request.PSObject.Properties['headers']) {
        foreach ($h in $request.headers.PSObject.Properties) {
            if ($h.Name -notin @('Accept','If-Match','If-None-Match','Idempotency-Key','X-Correlation-ID')) { throw 'Put secret or deployment-specific headers in rest.headers credentials; unsupported request header.' }
            $message.Headers.Add($h.Name, [string]$h.Value)
        }
    }
    if ($request.PSObject.Properties['bodyFile'] -and $request.bodyFile) {
        $bodyPath = Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($RequestFile))) $request.bodyFile
        $body = Get-Content -LiteralPath $bodyPath -Raw -Encoding UTF8
        $message.Content = New-Object Net.Http.StringContent $body, ([Text.Encoding]::UTF8), ([string]$request.contentType)
    }
    $cts = New-Object Threading.CancellationTokenSource
    $cts.CancelAfter([TimeSpan]::FromSeconds($TimeoutSeconds))
    $response = $client.SendAsync($message, [Net.Http.HttpCompletionOption]::ResponseHeadersRead, $cts.Token).GetAwaiter().GetResult()
    try {
        $stream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $reader = New-Object IO.StreamReader $stream, ([Text.Encoding]::UTF8)
        $clock = [Diagnostics.Stopwatch]::StartNew()
        try {
            $buffer = New-Object char[] ($MaxResponseChars + 1)
            $n = 0
            while ($n -lt $buffer.Length) {
                $task = $reader.ReadAsync($buffer, $n, $buffer.Length - $n)
                $remaining = [Math]::Max(1, $TimeoutSeconds * 1000 - [int]$clock.ElapsedMilliseconds)
                if ($cts.IsCancellationRequested -or !$task.Wait($remaining)) { throw 'Response body timed out.' }
                $got = $task.GetAwaiter().GetResult(); if ($got -eq 0) { break }; $n += $got
            }
            $bodyText = -join $buffer[0..([Math]::Max(0,$n - 1))]
            if ($n -eq 0) { $bodyText = '' }
            $bodyText = Protect-OmsText $bodyText $credential
            if ($authText) { $bodyText = $bodyText.Replace($authText, '[REDACTED]') }
            # Redact before truncating so a secret straddling the display boundary is not printed.
            if ($n -gt $MaxResponseChars) { $bodyText = '[response exceeds preview limit; narrow the output template or increase MaxResponseChars]' }
            Write-JsonResult @{ environment = $c.Name; status = [int]$response.StatusCode; httpSuccess = $response.IsSuccessStatusCode; body = $bodyText; truncated = ($n -gt $MaxResponseChars) }
        } finally { $reader.Dispose() }
    } finally { $response.Dispose(); $cts.Dispose() }
} catch {
    # Exception messages from HTTP libraries can include URLs, credentials or payloads.
    throw 'REST request failed. Check endpoint, authentication, certificate trust, and timeout. A write may have reached OMS: verify its outcome before retrying.'
} finally { $message.Dispose(); $client.Dispose(); $handler.Dispose() }
