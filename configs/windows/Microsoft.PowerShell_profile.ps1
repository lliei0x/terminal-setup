# $PROFILE
# . "D:\Configs\.config\powershell\Microsoft.PowerShell_profile.ps1"

# --- PSReadLine 优化配置 ---
# 开启预测，并使用列表模式
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# 设置历史搜索快捷键
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# 开启菜单循环补全
Set-PSReadLineOption -ShowToolTips

# --- Set-Alias 别名设置 ---
Set-Alias -Name np -Value Notepad.exe
Set-Alias -Name ex -Value explorer.exe
Set-Alias -Name c -Value clear

function elh {eza -lh --group-directories-first --git --icons}
function ealh {eza -alhDf --group-directories-first --git --icons}
function ealhD {eza -alhD --group-directories-first --git --icons}
function ealhf {eza -alhf --group-directories-first --git --icons}
function etree {eza -ah --tree -L=2 --group-directories-first --icons}
Set-Alias -Name l -Value elh
Set-Alias -Name ls -Value elh
Set-Alias -Name ll -Value ealh
Set-Alias -Name la -Value ealh
Set-Alias -Name ld -Value ealhD
Set-Alias -Name lf -Value ealhf
Set-Alias -Name lt -Value etree

Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

$target = "C:\Users\Administrator\.local\bin"
if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $target })) {
    $env:PATH = "$target;$env:PATH"
}

# 集成 fzf; 要先 winget install junegunn.fzf 
# Install-Module PSFzf -Scope CurrentUser -Force -ErrorAction SilentlyContinue
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf

	Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' `
	                -PSReadlineChordReverseHistory 'Ctrl+r'

	$env:FZF_DEFAULT_COMMAND = "fd --type f"
	$env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
}
