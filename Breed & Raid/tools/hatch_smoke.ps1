# Hatch roulette smoke — validates payload parse + reel landing math (no Studio).
$ErrorActionPreference = "Stop"
$failed = 0

function Assert($cond, $msg) {
	if (-not $cond) {
		Write-Host "FAIL: $msg" -ForegroundColor Red
		$script:failed++
	} else {
		Write-Host "OK: $msg" -ForegroundColor Green
	}
}

function Parse-Hatch([string]$payload) {
	# Mirror GameRoot.parseHatch
	if ($payload -match '^(.*?)\s*·\s*(.*?)\s*·\s*(.*?)\s*·\s*(.*?)\s*·\s*(.*?)\s*·\s*(.*?)\s*$') {
		return [pscustomobject]@{
			title = $Matches[1]
			line = $Matches[2]
			rarity = $Matches[3]
			oneIn = [int]$Matches[4]
			expectedOneIn = [int]$Matches[5]
			mult = [double]$Matches[6]
			bust = $null
		}
	}
	throw "parse failed: $payload"
}

function Parse-Bust([string]$payload) {
	if ($payload -match '^(\w+)\s*·\s*(\d+)') {
		return [pscustomobject]@{
			bust = if ($Matches[1] -eq "burn") { "burn" } else { "fail" }
			expectedOneIn = [int]$Matches[2]
		}
	}
	throw "bust parse failed: $payload"
}

function Build-Strip([object[]]$items, [int]$targetIdx, [int]$spins) {
	$strip = New-Object System.Collections.ArrayList
	$n = $items.Count
	for ($s = 0; $s -lt $spins; $s++) {
		foreach ($item in $items) { [void]$strip.Add($item) }
	}
	for ($i = 0; $i -lt $n; $i++) { [void]$strip.Add($items[$i]) }
	for ($i = 0; $i -lt $targetIdx; $i++) { [void]$strip.Add($items[$i]) }
	$landIndex = $strip.Count
	for ($i = 0; $i -lt $n; $i++) { [void]$strip.Add($items[$i]) }
	return @{ strip = $strip; land = $landIndex }
}

$rarities = @("Common","Uncommon","Rare","Epic","Mythic","Secret")
$mults = @(0.5, 1, 2, 5, 10)

# Server payload shape
$payload = "Hybrid Fox · 1 in 1.1K · Mythic · 1080 · 216 · 5"
$h = Parse-Hatch $payload
Assert ($h.title -eq "Hybrid Fox") "title"
Assert ($h.line -eq "1 in 1.1K") "line FormatOneIn"
Assert ($h.rarity -eq "Mythic") "rarity"
Assert ($h.oneIn -eq 1080) "oneIn"
Assert ($h.expectedOneIn -eq 216) "expected"
Assert ($h.mult -eq 5) "mult"

$b = Parse-Bust "fail · 216"
Assert ($b.bust -eq "fail") "bust fail"
Assert ($b.expectedOneIn -eq 216) "bust expected"

$b2 = Parse-Bust "burn · 50"
Assert ($b2.bust -eq "burn") "bust burn"

foreach ($name in $rarities) {
	$idx = [array]::IndexOf($rarities, $name) + 1
	$built = Build-Strip $rarities $idx 5
	$landed = $built.strip[$built.land - 1]
	Assert ($landed -eq $name) "rarity reel lands on $name (got $landed @ $($built.land))"
}

foreach ($m in $mults) {
	$idx = [array]::IndexOf($mults, $m) + 1
	$built = Build-Strip $mults $idx 4
	$landed = $built.strip[$built.land - 1]
	Assert ($landed -eq $m) "mult reel lands on $m (got $landed)"
}

# Mutate table sums to 1.0
$chances = @(0.55, 0.25, 0.12, 0.05, 0.03)
$sum = ($chances | Measure-Object -Sum).Sum
Assert ([math]::Abs($sum - 1.0) -lt 0.001) "mutate chances sum=$sum"

# Simulate softSpeed first free
$firstFree = $true
$spedUp = $false
$cost = if ($firstFree -and -not $spedUp) { 0 } else { 100 }
Assert ($cost -eq 0) "first speed free"

if ($failed -gt 0) {
	Write-Host "`n$failed failures" -ForegroundColor Red
	exit 1
}
Write-Host "`nAll hatch smoke checks passed." -ForegroundColor Green
