# X-Plane Web API (v3) client for the 747-400 flight-test kit.
# docs/overhaul/TESTING.md describes the kit.
#
# Library use (from another PowerShell script):
#   . "$PSScriptRoot\xp.ps1"
#   Get-XPDataref 'laminar/B747/engines/type'
#   Set-XPDataref 'sim/cockpit2/controls/flap_ratio' 0.5
#   Invoke-XPCommand 'laminar/B747/button_switch/elec_battery'
#
# Command line:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\flight\xp.ps1 <verb> [args]
#   verbs: caps | get <name[index]> | set <name[index]> <value> | cmd <name> [seconds]
#          flight <init.json> | shot [file.png] | find <text>
param([string]$Verb, [string]$Arg1, [string]$Arg2)

$ErrorActionPreference = 'Stop'
$script:XPBase = if ($env:XP_WEBAPI) { $env:XP_WEBAPI } else { 'http://localhost:8086/api/v3' }
# the X-Plane root: tests\flight -> aircraft folder -> Aircraft -> X-Plane 12
$script:XPRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
$script:XPDrefs = @{}
$script:XPCmds = @{}

function Invoke-XPApi([string]$Method, [string]$Path, $Body = $null, [int]$TimeoutSec = 30) {
    $uri = $script:XPBase + $Path
    if ($null -ne $Body) {
        $json = if ($Body -is [string]) { $Body } else { ConvertTo-Json $Body -Depth 30 -Compress }
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        return Invoke-RestMethod -Method $Method -Uri $uri -ContentType 'application/json' -Body $bytes -TimeoutSec $TimeoutSec
    }
    return Invoke-RestMethod -Method $Method -Uri $uri -TimeoutSec $TimeoutSec
}

function Get-XPCapabilities {
    $root = $script:XPBase -replace '/api/v\d+$', ''
    Invoke-RestMethod -Uri "$root/api/capabilities" -TimeoutSec 10
}

# "name[3]" -> @('name', 3); "name" -> @('name', -1)
function Split-XPName([string]$Name) {
    if ($Name -match '^(.*)\[(\d+)\]$') { return @($Matches[1], [int]$Matches[2]) }
    return @($Name, -1)
}

function Get-XPDatarefInfo([string]$Name) {
    if ($script:XPDrefs.ContainsKey($Name)) { return $script:XPDrefs[$Name] }
    $q = [uri]::EscapeDataString($Name)
    $r = Invoke-XPApi GET "/datarefs?filter[name]=$q&fields=id,name,value_type"
    if (-not $r.data -or $r.data.Count -eq 0) { throw "dataref not found: $Name (is a flight loaded?)" }
    $info = $r.data[0]
    $script:XPDrefs[$Name] = $info
    return $info
}

function ConvertFrom-XPData($Value) {
    # 'data' datarefs come back base64; the 747's string datarefs are NUL-padded
    $bytes = [Convert]::FromBase64String([string]$Value)
    return ([System.Text.Encoding]::UTF8.GetString($bytes)).TrimEnd([char]0)
}

function Get-XPDataref([string]$Name, [int]$Index = -1) {
    $n = Split-XPName $Name
    if ($n[1] -ge 0) { $Name = $n[0]; $Index = $n[1] }
    $info = Get-XPDatarefInfo $Name
    $path = "/datarefs/$($info.id)/value"
    if ($Index -ge 0) { $path += "?index=$Index" }
    $v = (Invoke-XPApi GET $path).data
    if ($info.value_type -eq 'data') { return ConvertFrom-XPData $v }
    return $v
}

function Set-XPDataref([string]$Name, $Value, [int]$Index = -1) {
    $n = Split-XPName $Name
    if ($n[1] -ge 0) { $Name = $n[0]; $Index = $n[1] }
    $info = Get-XPDatarefInfo $Name
    $path = "/datarefs/$($info.id)/value"
    if ($Index -ge 0) { $path += "?index=$Index" }
    if ($info.value_type -eq 'data') {
        $Value = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([string]$Value))
    } elseif ($info.value_type -match '^(int|int_array)$') {
        $Value = [int]$Value
    } elseif ($Value -is [string]) {
        $Value = [double]$Value
    }
    [void](Invoke-XPApi PATCH $path @{ data = $Value })
}

function Get-XPCommandId([string]$Name) {
    if ($script:XPCmds.ContainsKey($Name)) { return $script:XPCmds[$Name] }
    $q = [uri]::EscapeDataString($Name)
    $r = Invoke-XPApi GET "/commands?filter[name]=$q&fields=id,name"
    if (-not $r.data -or $r.data.Count -eq 0) { throw "command not found: $Name" }
    $script:XPCmds[$Name] = $r.data[0].id
    return $r.data[0].id
}

# Duration 0 presses and releases at once; a duration holds the command (max 10 s).
function Invoke-XPCommand([string]$Name, [double]$Duration = 0) {
    $id = Get-XPCommandId $Name
    [void](Invoke-XPApi POST "/command/$id/activate" @{ duration = $Duration })
}

# Start a flight from an init object or a JSON file path. Loading the 747 takes
# minutes, so wait long; then wait for the sim clock to run.
function Start-XPFlight($Init, [int]$TimeoutSec = 600) {
    if ($Init -is [string] -and (Test-Path $Init)) { $Init = Get-Content -Raw -Encoding UTF8 $Init }
    $script:XPDrefs = @{}
    $script:XPCmds = @{}
    try { [void](Invoke-XPApi POST '/flight' $Init $TimeoutSec) } catch {
        # the request can time out while X-Plane is still loading; the wait below decides
        Write-Warning "POST /flight: $($_.Exception.Message)"
    }
    Wait-XPSimRunning -TimeoutSec $TimeoutSec
}

function Wait-XPSimRunning([int]$TimeoutSec = 600) {
    # running = the sim clock moves. Its value alone says nothing: it does not
    # restart with a new flight, and it stops when X-Plane hangs while the Web
    # API still answers.
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    $unpaused = $false
    $last = $null
    while ((Get-Date) -lt $deadline) {
        try {
            $t = Get-XPDataref 'sim/time/total_running_time_sec'
            if (-not $unpaused -and (Get-XPDataref 'sim/time/paused') -eq 1) {
                Invoke-XPCommand 'sim/operation/pause_off'
                $unpaused = $true
            }
            if ($null -ne $last -and $t -gt $last + 1) { return $t }
            $last = $t
        } catch { $script:XPDrefs = @{}; $last = $null }
        Start-Sleep -Seconds 3
    }
    throw "the sim did not start running within $TimeoutSec s"
}

# The number of aircraft loads in Log.txt so far ("Loading airplane number 0").
function Get-XPAircraftLoads {
    $log = Join-Path $script:XPRoot 'Log.txt'
    if (-not (Test-Path $log)) { return 0 }
    return @(Select-String -Path $log -SimpleMatch 'Loading airplane number 0 with').Count
}

# Wait until the script block returns true; returns the elapsed seconds.
function Wait-XP([scriptblock]$Condition, [double]$TimeoutSec = 60, [int]$IntervalMs = 250) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        try { if (& $Condition) { return $sw.Elapsed.TotalSeconds } } catch { }
        Start-Sleep -Milliseconds $IntervalMs
    }
    return $null
}

# Take an X-Plane screenshot and copy it to $Dest. X-Plane writes it to
# Output/screenshots on a later frame, so wait for the new file.
function Save-XPScreenshot([string]$Dest, [int]$TimeoutSec = 30) {
    $dir = Join-Path $script:XPRoot 'Output\screenshots'
    $before = @{}
    if (Test-Path $dir) { Get-ChildItem $dir -Filter *.png | ForEach-Object { $before[$_.Name] = $true } }
    Invoke-XPCommand 'sim/operation/screenshot'
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
        if (-not (Test-Path $dir)) { continue }
        $new = Get-ChildItem $dir -Filter *.png | Where-Object { -not $before.ContainsKey($_.Name) } |
            Sort-Object LastWriteTime | Select-Object -Last 1
        if ($new) {
            # wait until X-Plane has finished writing it
            $size = -1
            while ($new.Length -ne $size) { $size = $new.Length; Start-Sleep -Milliseconds 500; $new.Refresh() }
            if ($Dest) {
                $destDir = Split-Path -Parent $Dest
                if ($destDir) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
                Copy-Item $new.FullName $Dest -Force
                return $Dest
            }
            return $new.FullName
        }
    }
    throw 'no screenshot appeared'
}

function Find-XPDataref([string]$Text) {
    $r = Invoke-XPApi GET '/datarefs?fields=name' $null 60
    $r.data | Where-Object { $_.name -like "*$Text*" } | ForEach-Object { $_.name }
}

if ($MyInvocation.InvocationName -ne '.' -and $Verb) {
    switch ($Verb) {
        'caps'   { Get-XPCapabilities | ConvertTo-Json -Depth 5 }
        'get'    { Get-XPDataref $Arg1 | ConvertTo-Json -Compress }
        'set'    { Set-XPDataref $Arg1 $Arg2; 'ok' }
        'cmd'    { $d = if ($Arg2) { [double]$Arg2 } else { 0 }; Invoke-XPCommand $Arg1 $d; 'ok' }
        'flight' { Start-XPFlight $Arg1 }
        'shot'   { Save-XPScreenshot $Arg1 }
        'find'   { Find-XPDataref $Arg1 }
        default  { throw "unknown verb: $Verb" }
    }
}
