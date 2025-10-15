Param(
  [Parameter(Mandatory=$true)][string[]]$Artifact,
  [string[]]$Inputs = @(),
  [string]$Note = "",
  [string]$Type = "auto"
)
$repo = (git rev-parse --show-toplevel).Trim()
$csv  = Join-Path $repo "docs\artifacts_log.csv"
if (!(Test-Path $csv)) {
  "timestamp,commit,artifact,type,size_bytes,sha256,inputs,note" | Out-File -Encoding utf8 $csv
}
$commit = (git rev-parse --short HEAD).Trim()
$ts = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssK")
foreach ($a in $Artifact) {
  $p = Resolve-Path $a -ErrorAction SilentlyContinue
  if (!$p) { continue }
  $fi = Get-Item $p
  $sha = (Get-FileHash $fi.FullName -Algorithm SHA256).Hash
  $inputsJoined = ($Inputs -join "; ")
  "$ts,$commit,$($fi.FullName.Replace(',',';')),$Type,$($fi.Length),$sha,""`$inputsJoined`",""`$Note.Replace('"','''')`"" |
    Out-File -Append -Encoding utf8 $csv
}
Write-Host "Logged $(($Artifact | Measure-Object).Count) artifact(s) to $csv"
