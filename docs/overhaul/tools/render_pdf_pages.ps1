# Render pages of a reference PDF to PNG with the Windows PDF renderer
# (Windows.Data.Pdf), so diagram pages can be read as images. Nothing needs
# installing: Windows PowerShell 5.1 reaches the WinRT API directly.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File render_pdf_pages.ps1 -Id LH24 -Pages 5,7-9
#
# -Id is an ID from _ref/text/SOURCES.tsv. Pages are PDF page numbers (1-based).
# Output: _ref/text/img/<Id>/pNNNN.png (existing files are kept unless -Force).
param(
    [Parameter(Mandatory = $true)][string]$Id,
    [Parameter(Mandatory = $true)][string]$Pages,
    [int]$Width = 1800,
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$ref = Join-Path $root '_ref'
$sources = Import-Csv -Delimiter "`t" -Path (Join-Path $ref 'text\SOURCES.tsv')
$entry = $sources | Where-Object { $_.id -eq $Id }
if (-not $entry) { throw "Unknown id '$Id' (see _ref/text/SOURCES.tsv)" }
$pdfPath = Join-Path $ref $entry.file
$outDir = Join-Path $ref "text\img\$Id"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$list = foreach ($part in $Pages.Split(',')) {
    if ($part -match '^\s*(\d+)\s*-\s*(\d+)\s*$') { [int]$Matches[1]..[int]$Matches[2] }
    elseif ($part -match '^\s*(\d+)\s*$') { [int]$Matches[1] }
    else { throw "Bad page spec '$part'" }
}

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Storage.StorageFolder, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime]
$null = [Windows.Data.Pdf.PdfPageRenderOptions, Windows.Data.Pdf, ContentType = WindowsRuntime]
$null = [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]

$ext = [System.WindowsRuntimeSystemExtensions].GetMethods()
$asTaskOp = ($ext | Where-Object { $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
$asTaskAct = ($ext | Where-Object { $_.Name -eq 'AsTask' -and -not $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' })[0]
function Await($op, [type]$type) {
    $t = $asTaskOp.MakeGenericMethod($type).Invoke($null, @($op))
    $t.Wait(-1) | Out-Null
    $t.Result
}
function AwaitAction($act) {
    $t = $asTaskAct.Invoke($null, @($act))
    $t.Wait(-1) | Out-Null
}

$file = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($pdfPath)) ([Windows.Storage.StorageFile])
$doc = Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])
$folder = Await ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync($outDir)) ([Windows.Storage.StorageFolder])

foreach ($p in $list) {
    if ($p -lt 1 -or $p -gt $doc.PageCount) { Write-Output "skip p.$p (document has $($doc.PageCount) pages)"; continue }
    $name = 'p{0:D4}.png' -f $p
    $target = Join-Path $outDir $name
    if ((Test-Path $target) -and -not $Force) { Write-Output $target; continue }
    $page = $doc.GetPage([uint32]($p - 1))
    $opts = New-Object Windows.Data.Pdf.PdfPageRenderOptions
    $opts.DestinationWidth = [uint32]$Width
    $out = Await ($folder.CreateFileAsync($name, [Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile])
    $stream = Await ($out.OpenAsync([Windows.Storage.FileAccessMode]::ReadWrite)) ([Windows.Storage.Streams.IRandomAccessStream])
    AwaitAction ($page.RenderToStreamAsync($stream, $opts))
    $stream.Dispose()
    $page.Dispose()
    Write-Output $target
}
