param (
    [switch]$Update = $false,
	[switch]$Status = $false,
	[string[]]$playlist = @(),
	[float]$minutes = -1
)

$browser = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
$db_json = "db.json"
$playlist_file = "playlist.txt"

if ($Update) {
	$playlist_ids = (cat $playlist_file | ConvertFrom-StringData)
	
	$playlist_combined_url = (($playlist.Length -gt 0) ? ($playlist_ids | ? { $_.Keys -in $playlist }) : $playlist_ids)
	$playlist_combined_url = $playlist_combined_url.Keys |
		select (
			@{l='Playlist'; e={$_}},
			@{l='URL'; e={"https://www.youtube.com/playlist?list=$($playlist_combined_url.$_)"}}
		)
	
	$playlist_combined_url
	
	<# TODO: catch non-existing playlist, for now no saving to db.json if has atleast 1 non-existing playlist
		WARNING: [youtube:tab] YouTube said: The playlist does not exist.
		ERROR: [youtube:tab] WL: YouTube said: The playlist does not exist.
		jq: error (at _temp.json:1): Cannot iterate over null (null)
		jq: error (at _temp2.json:0): object ({}) and null (null) cannot be multiplied
		
		redirect jq's stderr to $null (jq ... 2> $null) and/or
		use $LASTEXITCODE -eq 5 [https://jqlang.github.io/jq/manual/#halt_error,halt_error(exit_code)]
	#>
	
	#customize your cookies
	yt-dlp --cookies-from-browser chrome --flat-playlist -J $playlist_combined_url.URL > _temp.json
	
	if (!(Test-Path $db_json)) { "{}" > $db_json }
	
	(jq -sac 'map({ (.title): [.entries[] | {id, title, duration}] }) | add' _temp.json) | Out-File _temp2.json
	
	if ($LASTEXITCODE -ne 5) {
		(jq -sac '.[0] * .[1]' $db_json _temp2.json) | Out-File $db_json
	}
	
	del _temp.json,_temp2.json
	exit
}

if ($Status) {	
	$filter_playlist = ($playlist.Length -gt 0) ? "| map(select(" + "$(@($playlist | % { ".key == """"$_"""" or" }))".TrimEnd('or') + "))" : ""
	$filter_minutes = ($minutes -gt 0) ? "| map(.value |= map(select(.duration != null and .duration <= $minutes*60)))" : "| map(.value |= map(select(.duration != null)))"

	echo "`e[92m"
	jq -r "to_entries $filter_playlist $filter_minutes | map(`"\(.key) - \(.value | length)`") | .[]" $db_json
	echo ("-" * 30)
	jq -r "`"TOTAL: `" + (to_entries $filter_playlist $filter_minutes | map((.value | length)) | add | tostring)" $db_json
	echo "`e[0m"
	
	exit
}

$filter_playlist = ($playlist -ne "") ? "$(@($playlist | % { "."""$_"""[]?," }))".TrimEnd(',') : ".[][]"
$filter_minutes = ($minutes -gt 0) ? "| select(.duration != null and .duration <= $minutes*60)" : "| select(.duration != null)"

#Test-Path $db_json
$watch = jq -ac "$filter_playlist $filter_minutes" $db_json | Get-Random | ConvertFrom-Json

if ($watch.Length -gt 0) {
	echo "`e[93m$($watch.title)`e[0m `e[94m[$($watch.id)]`e[0m"
	& $browser --incognito "https://www.youtube.com/watch?v=$($watch.id)"
	
	$yn = ""
	while($yn.ToLower() -ne "y" -and $yn.ToLower() -ne "n") {
		$yn = Read-Host "`e[91mRemove`e[0m `e[93m$($watch.title)`e[0m ? (y/n)"
	}

	if($yn.ToLower() -eq "y") {
		(jq -ac "del(.[][] | select(.id==`"$($watch.id)`"))" $db_json) | Out-File $db_json
		echo "`e[38;5;1mRemoved!`e[0m"
	}
} else {
	echo "`e[91mNo video available`e[0m"
}
