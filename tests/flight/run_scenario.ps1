# Run one flight-test scenario in X-Plane through the Web API and record it.
# docs/overhaul/TESTING.md describes the kit.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\flight\run_scenario.ps1 `
#       -Scenario tests\flight\scenarios\s00_baseline_start.json -Acf custom
#
# -Acf custom|stock picks 747-400_custom.acf or 747-400.acf (or give a path
# relative to the X-Plane root). -NoFlight runs the steps on the flight that
# is already loaded. -Reload reloads the aircraft (without art) after the
# flight starts: X-Plane keeps the loaded aircraft, plugins and their state
# when a new flight uses the same aircraft, so use -Reload for a clean start.
# Output goes to tests\flight\runs\<time>_<scenario>_<acf>\.
#
# Scenario file (JSON): { "name", "description", "flight": {init without
# "aircraft"}, ["reload": true], "steps": [ ... ] }. "reload" asks for -Reload
# (the scenario needs the aircraft's systems fresh). Step types ("do"):
#   record_start | record_stop | mark            the FlyWithLua recorder
#   cmd     {name, [duration]}                   run a command
#   set     {dref, value}                        write a dataref
#   switch  {dref, value, cmd, [cmd_down]}       press cmd (or cmd_down when the
#                                                value must go down) until dref
#                                                equals value (up to 6 presses)
#   wait    {dref, op, value, timeout}           wait for a condition
#   check   {dref, op, value, [cite], [level]}   record pass/fail (level fail|warn)
#   sleep   {seconds}
#   snapshot {drefs: [...]}                      log values
#   cas                                          log the EICAS message lines
#   view    {name} | {the, psi, [fov]}           turn the pilot's head: a preset
#                                                (forward, panel, overhead, eicas, bleed)
#                                                or pitch/heading, with a field of view
#                                                for a close look (bleed: the P5 bleed
#                                                panel at 25 deg); the user's comes back
#                                                with the next view and at the end
#   shot    {name}                               screenshot
# Every step may carry "note" (shown in the report) and "cite" (source page).
param(
    [Parameter(Mandatory = $true)][string]$Scenario,
    [string]$Acf = 'custom',
    [switch]$NoFlight,
    [switch]$Reload,
    [string]$RunsDir
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'xp.ps1')

$spec = Get-Content -Raw -Encoding UTF8 $Scenario | ConvertFrom-Json
$acfPath = switch ($Acf) {
    'custom' { 'Aircraft/747-400-master/747-400_custom.acf' }
    'stock'  { 'Aircraft/747-400-master/747-400.acf' }
    default  { $Acf }
}
$acfTag = [IO.Path]::GetFileNameWithoutExtension($acfPath)
if (-not $RunsDir) { $RunsDir = Join-Path $PSScriptRoot 'runs' }
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$out = Join-Path $RunsDir "${stamp}_$($spec.name)_$acfTag"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$recDir = Join-Path $script:XPRoot 'Output\B747_flighttest'
New-Item -ItemType Directory -Force -Path $recDir | Out-Null
$logPath = Join-Path $script:XPRoot 'Log.txt'

$results = New-Object System.Collections.ArrayList
$wall = [Diagnostics.Stopwatch]::StartNew()
function Add-Result($step, [string]$status, [string]$detail, $value = $null) {
    $simT = $null
    try { $simT = [math]::Round((Get-XPDataref 'sim/time/total_running_time_sec'), 2) } catch { }
    $r = [ordered]@{
        n = $results.Count + 1; do = $step.do; status = $status; detail = $detail
        value = $value; note = $step.note; cite = $step.cite
        wall_s = [math]::Round($wall.Elapsed.TotalSeconds, 1); sim_t = $simT
    }
    [void]$results.Add($r)
    $mark = switch ($status) { 'pass' { 'PASS' } 'fail' { 'FAIL' } 'warn' { 'WARN' } default { '----' } }
    Write-Host ("[{0,6:N1}s] {1} {2} {3}" -f $wall.Elapsed.TotalSeconds, $mark, $step.do, $detail)
}
function Test-Op($actual, [string]$op, $expected) {
    switch ($op) {
        '=='      { return $actual -eq $expected }
        '!='      { return $actual -ne $expected }
        '>'       { return $actual -gt $expected }
        '>='      { return $actual -ge $expected }
        '<'       { return $actual -lt $expected }
        '<='      { return $actual -le $expected }
        'between' { return ($actual -ge $expected[0]) -and ($actual -le $expected[1]) }
        'contains' { return ([string]$actual).Contains([string]$expected) }
        default   { throw "unknown op $op" }
    }
}
# X-Plane can hang with the Web API still answering: the sim clock stops.
# Test-XPStuck says so once the clock has not moved for 30 s of wall time.
$script:clock = @{ sim = $null; wall = 0.0 }
function Test-XPStuck {
    $t = Get-XPDataref 'sim/time/total_running_time_sec'
    $now = $wall.Elapsed.TotalSeconds
    if ($null -eq $script:clock.sim -or $t -ne $script:clock.sim) {
        $script:clock.sim = $t
        $script:clock.wall = $now
        return $false
    }
    return ($now - $script:clock.wall) -gt 30
}
function Get-StuckMessage {
    $p = Get-Process -Name 'X-Plane' -ErrorAction SilentlyContinue | Select-Object -First 1
    return "X-Plane stopped: the sim clock has not moved for {0:N0} s (process responding: {1})" -f `
        ($wall.Elapsed.TotalSeconds - $script:clock.wall), $(if ($p) { $p.Responding } else { 'no process' })
}

function Get-CasLines {
    $lines = @()
    foreach ($level in 'warning', 'caution', 'advisory', 'memo') {
        for ($i = 0; $i -lt 22; $i++) {
            $name = 'laminar/B747/CAS/gen_{0}_msg_{1:D3}' -f $level, $i
            try { $t = Get-XPDataref $name } catch { break }
            if ($t -and $t.Trim()) { $lines += "${level}: $($t.Trim())" }
        }
    }
    return $lines
}

# the first Log.txt line of this run, for the excerpt at the end
$logStart = if (Test-Path $logPath) { (Get-Content $logPath).Count } else { 0 }

$freshLoad = $false
if (-not $NoFlight) {
    $init = $spec.flight | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    $init | Add-Member -NotePropertyName aircraft -NotePropertyValue @{ path = $acfPath } -Force
    Write-Host "starting flight: $acfPath"
    $loadsBefore = Get-XPAircraftLoads
    $t = Start-XPFlight $init
    $freshLoad = (Get-XPAircraftLoads) -gt $loadsBefore
    Add-Result @{ do = 'flight' } 'info' ("flight running (sim time {0} s){1}" -f [math]::Round($t, 1), $(if ($freshLoad) { ', aircraft loaded' } else { '' }))
}
if ($spec.reload -eq $true -and -not $NoFlight) { $Reload = $true }
# Reloading right after X-Plane has loaded the aircraft hung X-Plane twice
# (2026-10-23, docs/overhaul/TESTING.md §4.6); a freshly loaded aircraft
# needs no reload anyway.
if ($Reload -and $freshLoad) {
    Add-Result @{ do = 'reload' } 'info' 'no reload: the flight start loaded the aircraft'
    $Reload = $false
}
if ($Reload) {
    # let the aircraft's plugins settle before unloading them
    $since = Get-XPDataref 'sim/time/total_running_time_sec'
    Wait-XP { (Get-XPDataref 'sim/time/total_running_time_sec') -gt $since + 20 } 120 1000 | Out-Null
    # X-Plane drops the command while it is still settling after a flight
    # load, so wait for the new load in Log.txt and try again if none comes.
    $loads = Get-XPAircraftLoads
    $reloaded = $false
    for ($try = 1; $try -le 3 -and -not $reloaded; $try++) {
        Invoke-XPCommand 'sim/operation/reload_aircraft_no_art'
        $reloaded = $null -ne (Wait-XP { (Get-XPAircraftLoads) -gt $loads } 60 1000)
    }
    if (-not $reloaded) { throw 'the aircraft did not reload' }
    $script:XPDrefs = @{}
    $script:XPCmds = @{}
    $t = Wait-XPSimRunning -TimeoutSec 600
    Add-Result @{ do = 'reload' } 'info' "aircraft reloaded (sim time $([math]::Round($t,1)) s)"
}
$loaded = Get-XPDataref 'sim/aircraft/view/acf_relative_path'
Add-Result @{ do = 'aircraft' } 'info' $loaded
$fov0 = Get-XPDataref 'sim/graphics/view/field_of_view_deg'

$stopped = $false
foreach ($step in $spec.steps) {
    if ($stopped) { break }
    try {
        if (Test-XPStuck) { throw 'stuck' }
        switch ($step.do) {
            'record_start' { Invoke-XPCommand 'FlyWithLua/B747_flighttest/start'; Add-Result $step 'info' 'recorder started' }
            'record_stop'  { Invoke-XPCommand 'FlyWithLua/B747_flighttest/stop'; Start-Sleep -Seconds 2; Add-Result $step 'info' 'recorder stopped' }
            'mark'         { Invoke-XPCommand 'FlyWithLua/B747_flighttest/mark'; Add-Result $step 'info' 'mark' }
            'cmd' {
                $d = if ($step.duration) { [double]$step.duration } else { 0 }
                Invoke-XPCommand $step.name $d
                if ($d -gt 0) { Start-Sleep -Milliseconds ([int]($d * 1000) + 200) }
                Add-Result $step 'info' $step.name
            }
            'set' { Set-XPDataref $step.dref $step.value; Add-Result $step 'info' "$($step.dref) = $($step.value)" }
            'switch' {
                $v = Get-XPDataref $step.dref
                $n = 0
                while ([math]::Abs($v - [double]$step.value) -gt 0.01 -and $n -lt 6) {
                    $c = if ($v -gt $step.value -and $step.cmd_down) { $step.cmd_down } else { $step.cmd }
                    Invoke-XPCommand $c
                    Start-Sleep -Milliseconds 600
                    $v = Get-XPDataref $step.dref
                    $n++
                }
                $ok = [math]::Abs($v - [double]$step.value) -le 0.01
                Add-Result $step $(if ($ok) { 'pass' } else { 'fail' }) "$($step.dref) -> $v after $n press(es)" $v
            }
            'wait' {
                $timeout = if ($step.timeout) { [double]$step.timeout } else { 60 }
                $last = $null
                $script:stuck = $false
                $sec = Wait-XP {
                    if (Test-XPStuck) { $script:stuck = $true; return $true }
                    $script:lastValue = Get-XPDataref $step.dref; Test-Op $script:lastValue $step.op $step.value
                } $timeout 500
                if ($script:stuck) { throw 'stuck' }
                $last = $script:lastValue
                if ($null -ne $sec) { Add-Result $step 'pass' ("{0} {1} {2} after {3:N1} s" -f $step.dref, $step.op, ($step.value -join '..'), $sec) $last }
                else { Add-Result $step $(if ($step.level -eq 'warn') { 'warn' } else { 'fail' }) ("{0} {1} {2} not reached in {3} s (last {4})" -f $step.dref, $step.op, ($step.value -join '..'), $timeout, $last) $last }
            }
            'check' {
                $v = Get-XPDataref $step.dref
                $ok = Test-Op $v $step.op $step.value
                $status = if ($ok) { 'pass' } elseif ($step.level -eq 'warn') { 'warn' } else { 'fail' }
                Add-Result $step $status ("{0} = {1} (want {2} {3})" -f $step.dref, $v, $step.op, ($step.value -join '..')) $v
            }
            'sleep' { Start-Sleep -Milliseconds ([int]([double]$step.seconds * 1000)); Add-Result $step 'info' "slept $($step.seconds) s" }
            'snapshot' {
                $vals = [ordered]@{}
                foreach ($d in $step.drefs) { try { $vals[$d] = Get-XPDataref $d } catch { $vals[$d] = 'ERROR' } }
                Add-Result $step 'info' (($vals.Keys | ForEach-Object { "$_=$($vals[$_])" }) -join '; ') $vals
            }
            'cas' { $lines = Get-CasLines; Add-Result $step 'info' ("{0} line(s): {1}" -f $lines.Count, ($lines -join ' | ')) $lines }
            'view' {
                # head pitch/heading in degrees from the captain's eye point, and
                # a field of view for a close look (back to the user's after)
                $presets = @{ forward = @(0, 0); panel = @(-28, 20); overhead = @(58, 48); eicas = @(-22, 29)
                    bleed = @(19, 70, 25) }
                $v = if ($step.name) { $presets[$step.name] } else { @($step.the, $step.psi, $step.fov) }
                if (-not $v) { throw "unknown view preset $($step.name)" }
                $fov = if ($v.Count -gt 2 -and $v[2]) { $v[2] } else { $fov0 }
                Set-XPDataref 'sim/graphics/view/field_of_view_deg' $fov
                Set-XPDataref 'sim/graphics/view/pilots_head_the' $v[0]
                Set-XPDataref 'sim/graphics/view/pilots_head_psi' $v[1]
                Start-Sleep -Seconds 1
                Add-Result $step 'info' ("view pitch {0} heading {1} fov {2}" -f $v[0], $v[1], $fov)
            }
            'shot' {
                $f = Save-XPScreenshot (Join-Path $out ("shot_{0:D2}_{1}.png" -f ($results.Count + 1), $step.name))
                Add-Result $step 'info' (Split-Path -Leaf $f)
            }
            default { throw "unknown step type: $($step.do)" }
        }
    } catch {
        if ($_.Exception.Message -eq 'stuck') {
            Add-Result $step 'fail' (Get-StuckMessage)
            $stopped = $true
        } else {
            Add-Result $step 'fail' "error: $($_.Exception.Message)"
        }
    }
}
if (-not $stopped) { try { Set-XPDataref 'sim/graphics/view/field_of_view_deg' $fov0 } catch { } }

# collect the recorder output and the Log.txt lines of this run
foreach ($f in 'session.csv', 'events.csv', 'summary.txt') {
    $p = Join-Path $recDir $f
    if (Test-Path $p) { Copy-Item $p (Join-Path $out $f) -Force }
}
if (Test-Path $logPath) {
    $log = Get-Content $logPath
    $log[$logStart..($log.Count - 1)] | Out-File -Encoding utf8 (Join-Path $out 'log_full.txt')
    $log[$logStart..($log.Count - 1)] | Where-Object { $_ -match '(?i)\bE/|error|LUA|xtlua|fail|missing|cannot|unable|replaced' } |
        Out-File -Encoding utf8 (Join-Path $out 'log_errors.txt')
}

$summary = [ordered]@{
    scenario = $spec.name; description = $spec.description; acf = $acfPath; loaded = $loaded
    started = $stamp; wall_s = [math]::Round($wall.Elapsed.TotalSeconds, 1)
    pass = @($results | Where-Object { $_.status -eq 'pass' }).Count
    fail = @($results | Where-Object { $_.status -eq 'fail' }).Count
    warn = @($results | Where-Object { $_.status -eq 'warn' }).Count
    steps = $results
}
$summary | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 (Join-Path $out 'result.json')
$md = @("# $($spec.name) ($acfTag)", '', "$($spec.description)", '',
    "- 開始: $stamp、所要 $($summary.wall_s) s、PASS $($summary.pass) / FAIL $($summary.fail) / WARN $($summary.warn)", '',
    '| # | 種類 | 結果 | 内容 | メモ | 出典 | sim 時刻 |', '|---|---|---|---|---|---|---|')
foreach ($r in $results) {
    $md += "| $($r.n) | $($r.do) | $($r.status) | $(($r.detail -replace '\|', '\|')) | $($r.note) | $($r.cite) | $($r.sim_t) |"
}
$md | Out-File -Encoding utf8 (Join-Path $out 'result.md')
Write-Host "result: $out  (pass $($summary.pass), fail $($summary.fail), warn $($summary.warn))"
