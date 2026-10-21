param([switch]$LayoutOnly)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:proc = $null
$script:successShown = $false
$script:lastLog = ""
$script:logPath = Join-Path $env:TEMP ("zxhn_gui_" + [guid]::NewGuid().ToString("N") + ".log")
$script:errPath = Join-Path $env:TEMP ("zxhn_gui_" + [guid]::NewGuid().ToString("N") + ".err")
$script:configStartedAt = $null
$script:successPending = $false
$script:visualRunwaySeconds = 20

$blue = [System.Drawing.Color]::FromArgb(11, 107, 181)
$dark = [System.Drawing.Color]::FromArgb(40, 52, 65)
$muted = [System.Drawing.Color]::FromArgb(100, 112, 125)
$light = [System.Drawing.Color]::FromArgb(245, 248, 252)
$green = [System.Drawing.Color]::FromArgb(33, 150, 83)
$hackBg = [System.Drawing.Color]::FromArgb(4, 7, 10)
$hackPanel = [System.Drawing.Color]::FromArgb(8, 15, 21)
$hackInput = [System.Drawing.Color]::FromArgb(2, 5, 7)
$neon = [System.Drawing.Color]::FromArgb(0, 255, 156)
$cyan = [System.Drawing.Color]::FromArgb(0, 229, 255)
$magenta = [System.Drawing.Color]::FromArgb(255, 46, 136)
$hackText = [System.Drawing.Color]::FromArgb(185, 210, 200)
$hackMuted = [System.Drawing.Color]::FromArgb(90, 112, 118)
$script:hackerProcs = @()
$script:hackerStormActive = $false
$script:hackerNextSpawnAt = Get-Date
$script:hackerTargetMax = 6
$script:hackerNextTargetChangeAt = Get-Date

$form = New-Object System.Windows.Forms.Form
$form.Text = "ZXHN Z503 校园网一键桥接"
$form.ClientSize = New-Object System.Drawing.Size(780, 690)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = $light
$form.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)

$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(780, 88)
$header.BackColor = $blue
$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Text = "ZXHN Z503 校园网一键桥接"
$title.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 18, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::White
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(24, 18)
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "自动切换为桥接模式 · 多台设备各自认证 · 全程本地配置"
$subtitle.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(220, 238, 255)
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(26, 54)
$header.Controls.Add($subtitle)

$stepsGroup = New-Object System.Windows.Forms.GroupBox
$stepsGroup.Text = "开始前请确认"
$stepsGroup.Location = New-Object System.Drawing.Point(24, 104)
$stepsGroup.Size = New-Object System.Drawing.Size(732, 88)
$stepsGroup.BackColor = [System.Drawing.Color]::White
$stepsGroup.ForeColor = $dark
$form.Controls.Add($stepsGroup)

$steps = New-Object System.Windows.Forms.Label
$steps.Text = "1. 路由器已通电   2. 校园网墙口接 ZXHN 的 WAN 接口   3. 电脑接 ZXHN 的 LAN 接口" + "`r`n" + "没有网口时，可先连接路由器底部标签上的默认 Wi-Fi。"
$steps.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$steps.ForeColor = $muted
$steps.AutoSize = $false
$steps.Location = New-Object System.Drawing.Point(15, 24)
$steps.Size = New-Object System.Drawing.Size(700, 52)
$stepsGroup.Controls.Add($steps)

$inputGroup = New-Object System.Windows.Forms.GroupBox
$inputGroup.Text = "路由器设置"
$inputGroup.Location = New-Object System.Drawing.Point(24, 204)
$inputGroup.Size = New-Object System.Drawing.Size(732, 210)
$inputGroup.BackColor = [System.Drawing.Color]::White
$inputGroup.ForeColor = $dark
$form.Controls.Add($inputGroup)

$labelPassword = New-Object System.Windows.Forms.Label
$labelPassword.Text = "管理密码（在路由器底部标签上）"
$labelPassword.Location = New-Object System.Drawing.Point(15, 31)
$labelPassword.Size = New-Object System.Drawing.Size(220, 24)
$labelPassword.ForeColor = $dark
$inputGroup.Controls.Add($labelPassword)

$txtPassword = New-Object System.Windows.Forms.TextBox
$txtPassword.Location = New-Object System.Drawing.Point(240, 27)
$txtPassword.Size = New-Object System.Drawing.Size(300, 28)
$txtPassword.UseSystemPasswordChar = $true
$txtPassword.BorderStyle = "FixedSingle"
$inputGroup.Controls.Add($txtPassword)

$labelPasswordHint = New-Object System.Windows.Forms.Label
$labelPasswordHint.Text = "不是 Wi-Fi 密码"
$labelPasswordHint.Location = New-Object System.Drawing.Point(550, 31)
$labelPasswordHint.Size = New-Object System.Drawing.Size(150, 22)
$labelPasswordHint.ForeColor = $muted
$inputGroup.Controls.Add($labelPasswordHint)

$chkDefaultWifi = New-Object System.Windows.Forms.CheckBox
$chkDefaultWifi.Text = "保留路由器标签上的默认 Wi-Fi（推荐）"
$chkDefaultWifi.Location = New-Object System.Drawing.Point(240, 64)
$chkDefaultWifi.Size = New-Object System.Drawing.Size(300, 24)
$chkDefaultWifi.Checked = $true
$inputGroup.Controls.Add($chkDefaultWifi)

$labelSsid2g = New-Object System.Windows.Forms.Label
$labelSsid2g.Text = "2.4G Wi-Fi 名称"
$labelSsid2g.Location = New-Object System.Drawing.Point(15, 101)
$labelSsid2g.Size = New-Object System.Drawing.Size(220, 24)
$inputGroup.Controls.Add($labelSsid2g)

$txtSsid2g = New-Object System.Windows.Forms.TextBox
$txtSsid2g.Location = New-Object System.Drawing.Point(240, 97)
$txtSsid2g.Size = New-Object System.Drawing.Size(300, 28)
$txtSsid2g.BorderStyle = "FixedSingle"
$txtSsid2g.Enabled = $false
$inputGroup.Controls.Add($txtSsid2g)

$labelSsid5g = New-Object System.Windows.Forms.Label
$labelSsid5g.Text = "5G Wi-Fi 名称"
$labelSsid5g.Location = New-Object System.Drawing.Point(15, 137)
$labelSsid5g.Size = New-Object System.Drawing.Size(220, 24)
$inputGroup.Controls.Add($labelSsid5g)

$txtSsid5g = New-Object System.Windows.Forms.TextBox
$txtSsid5g.Location = New-Object System.Drawing.Point(240, 133)
$txtSsid5g.Size = New-Object System.Drawing.Size(300, 28)
$txtSsid5g.BorderStyle = "FixedSingle"
$txtSsid5g.Enabled = $false
$inputGroup.Controls.Add($txtSsid5g)

$labelWifiPass = New-Object System.Windows.Forms.Label
$labelWifiPass.Text = "新 Wi-Fi 密码"
$labelWifiPass.Location = New-Object System.Drawing.Point(15, 173)
$labelWifiPass.Size = New-Object System.Drawing.Size(220, 24)
$inputGroup.Controls.Add($labelWifiPass)

$txtWifiPass = New-Object System.Windows.Forms.TextBox
$txtWifiPass.Location = New-Object System.Drawing.Point(240, 169)
$txtWifiPass.Size = New-Object System.Drawing.Size(300, 28)
$txtWifiPass.UseSystemPasswordChar = $true
$txtWifiPass.BorderStyle = "FixedSingle"
$txtWifiPass.Enabled = $false
$inputGroup.Controls.Add($txtWifiPass)

$labelWifiHint = New-Object System.Windows.Forms.Label
$labelWifiHint.Text = "取消勾选后可自定义（≥8 位）"
$labelWifiHint.Location = New-Object System.Drawing.Point(550, 166)
$labelWifiHint.Size = New-Object System.Drawing.Size(175, 36)
$labelWifiHint.ForeColor = $muted
$inputGroup.Controls.Add($labelWifiHint)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "开始配置"
$btnStart.Location = New-Object System.Drawing.Point(24, 430)
$btnStart.Size = New-Object System.Drawing.Size(180, 40)
$btnStart.BackColor = $blue
$btnStart.ForeColor = [System.Drawing.Color]::White
$btnStart.FlatStyle = "Flat"
$btnStart.FlatAppearance.BorderSize = 0
$btnStart.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
$btnStart.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnStart)

$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "退出"
$btnExit.Location = New-Object System.Drawing.Point(216, 430)
$btnExit.Size = New-Object System.Drawing.Size(100, 40)
$btnExit.BackColor = [System.Drawing.Color]::FromArgb(225, 231, 238)
$btnExit.ForeColor = $dark
$btnExit.FlatStyle = "Flat"
$btnExit.FlatAppearance.BorderSize = 0
$btnExit.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnExit)

$status = New-Object System.Windows.Forms.Label
$status.Text = "等待开始"
$status.Location = New-Object System.Drawing.Point(24, 482)
$status.Size = New-Object System.Drawing.Size(732, 24)
$status.ForeColor = $dark
$form.Controls.Add($status)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(24, 510)
$progress.Size = New-Object System.Drawing.Size(732, 14)
$progress.Style = "Blocks"
$progress.Value = 0
$form.Controls.Add($progress)

$chkLog = New-Object System.Windows.Forms.CheckBox
$chkLog.Text = "显示日志"
$chkLog.Location = New-Object System.Drawing.Point(24, 536)
$chkLog.Size = New-Object System.Drawing.Size(120, 24)
$chkLog.ForeColor = $muted
$form.Controls.Add($chkLog)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(24, 562)
$logBox.Size = New-Object System.Drawing.Size(732, 56)
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.ScrollBars = "Vertical"
$logBox.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 251)
$logBox.BorderStyle = "FixedSingle"
$logBox.Visible = $false
$form.Controls.Add($logBox)

$warning = New-Object System.Windows.Forms.Label
$warning.Text = "配置过程不需要外网；最后上网需要 WAN 接校园网墙口。" + "`r`n" + "桥接模式下每台设备用自己的校园网账号；一个账号只能一台设备在线。"
$warning.Location = New-Object System.Drawing.Point(24, 620)
$warning.Size = New-Object System.Drawing.Size(732, 42)
$warning.ForeColor = [System.Drawing.Color]::FromArgb(150, 85, 20)
$form.Controls.Add($warning)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500

$script:hackerTimer = New-Object System.Windows.Forms.Timer
$script:hackerTimer.Interval = 420

function Set-WifiFields {
    $enabled = -not $chkDefaultWifi.Checked
    $txtSsid2g.Enabled = $enabled
    $txtSsid5g.Enabled = $enabled
    $txtWifiPass.Enabled = $enabled
    if ($enabled) {
        $txtSsid2g.Focus() | Out-Null
    }
}

function Test-Router {
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $task = $client.ConnectAsync("192.168.10.1", 80)
        if (-not $task.Wait(2000)) {
            $client.Close()
            return $false
        }
        $ok = $client.Connected
        $client.Close()
        return $ok
    } catch {
        return $false
    }
}

function Set-Running([bool]$running) {
    $txtPassword.Enabled = -not $running
    $chkDefaultWifi.Enabled = -not $running
    $btnStart.Enabled = -not $running
    $btnExit.Enabled = $true
    if ($running) {
        $progress.Style = "Marquee"
        $progress.MarqueeAnimationSpeed = 30
    } else {
        $progress.Style = "Blocks"
        $progress.MarqueeAnimationSpeed = 0
    }
    Set-WifiFields
}

function Set-HackerTheme($root) {
    if ($root -is [System.Windows.Forms.Form]) {
        $root.BackColor = $hackBg
        $root.ForeColor = $hackText
    } elseif ($root -is [System.Windows.Forms.Panel]) {
        $root.BackColor = $hackBg
        $root.ForeColor = $hackText
    } elseif ($root -is [System.Windows.Forms.GroupBox]) {
        $root.BackColor = $hackPanel
        $root.ForeColor = $neon
    } elseif ($root -is [System.Windows.Forms.TextBox]) {
        $root.BackColor = $hackInput
        $root.ForeColor = $neon
        $root.BorderStyle = "FixedSingle"
    } elseif ($root -is [System.Windows.Forms.Button]) {
        $root.BackColor = $hackPanel
        $root.ForeColor = $neon
        $root.FlatStyle = "Flat"
        $root.FlatAppearance.BorderSize = 1
        $root.FlatAppearance.BorderColor = $neon
        $root.UseVisualStyleBackColor = $false
    } elseif ($root -is [System.Windows.Forms.CheckBox]) {
        $root.BackColor = $hackPanel
        $root.ForeColor = $hackText
    } elseif ($root -is [System.Windows.Forms.Label]) {
        $root.ForeColor = $hackText
        $root.BackColor = [System.Drawing.Color]::Transparent
    }
    if ($root.HasChildren) {
        foreach ($child in $root.Controls) { Set-HackerTheme $child }
    }
}

function Get-HackerVisualProfiles {
    return @(
        @{ Mode = "PACKET"; Title = "ZXHN://PACKET-TRACE"; Slot = 0 },
        @{ Mode = "CRYPTO"; Title = "ZXHN://ENTROPY-CORE"; Slot = 1 },
        @{ Mode = "BRIDGE"; Title = "ZXHN://BRIDGE-MAP"; Slot = 2 },
        @{ Mode = "KERNEL"; Title = "ZXHN://KERNEL-SYNC"; Slot = 3 },
        @{ Mode = "SESSION"; Title = "ZXHN://SESSION-GRAPH"; Slot = 4 },
        @{ Mode = "TRACE"; Title = "ZXHN://HEX-VERIFY"; Slot = 5 },
        @{ Mode = "ARP"; Title = "ZXHN://ARP-NEIGHBOR"; Slot = 6 },
        @{ Mode = "DNS"; Title = "ZXHN://DNS-CASCADE"; Slot = 7 },
        @{ Mode = "TLS"; Title = "ZXHN://TLS-TRANSCRIPT"; Slot = 8 },
        @{ Mode = "ROUTE"; Title = "ZXHN://RIB-LATTICE"; Slot = 9 },
        @{ Mode = "GRAPH"; Title = "ZXHN://GRAPH-WALKER"; Slot = 10 },
        @{ Mode = "MATRIX"; Title = "ZXHN://MATRIX-SEED"; Slot = 11 }
    )
}

function Start-HackerConsoleInstance {
    param(
        [object[]]$Profiles,
        [int]$Slot
    )

    $hackerScript = Join-Path $PSScriptRoot "hacker_window.ps1"
    if (-not (Test-Path -LiteralPath $hackerScript)) { return $null }
    $profile = Get-Random -InputObject $Profiles
    $duration = [Math]::Round((Get-Random -Minimum 35 -Maximum 106) / 10, 1)
    $argString = "-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Normal -File `"$hackerScript`" -Mode $($profile.Mode) -Title `"$($profile.Title)`" -Duration $duration -Slot $Slot"
    return Start-Process -FilePath "powershell.exe" `
        -ArgumentList $argString `
        -PassThru -WindowStyle Normal
}

function Update-HackerConsoles {
    if (-not $script:hackerStormActive) { return }
    $script:hackerProcs = @($script:hackerProcs | Where-Object {
        try { $_.Process -and -not $_.Process.HasExited } catch { $false }
    })
    $now = Get-Date
    if ($now -ge $script:hackerNextTargetChangeAt) {
        $script:hackerTargetMax = Get-Random -Minimum 5 -Maximum 10
        $script:hackerNextTargetChangeAt = $now.AddSeconds((Get-Random -Minimum 6 -Maximum 13))
    }
    if ($now -lt $script:hackerNextSpawnAt) { return }

    $activeCount = @($script:hackerProcs).Count
    if ($activeCount -lt $script:hackerTargetMax) {
        $activeSlots = @($script:hackerProcs | ForEach-Object { $_.Slot })
        $availableSlots = @(0..11 | Where-Object { $_ -notin $activeSlots })
        if ($availableSlots.Count -eq 0) { $availableSlots = @(0..11) }
        $remaining = $script:hackerTargetMax - $activeCount
        $burst = [Math]::Min($remaining, (Get-Random -Minimum 1 -Maximum 4))
        $profiles = @(Get-HackerVisualProfiles)
        for ($i = 0; $i -lt $burst; $i++) {
            try {
                $slot = Get-Random -InputObject $availableSlots
                $p = Start-HackerConsoleInstance -Profiles $profiles -Slot $slot
                if ($p) {
                    $script:hackerProcs += [pscustomobject]@{ Process = $p; Slot = $slot }
                    $availableSlots = @($availableSlots | Where-Object { $_ -ne $slot })
                    if ($availableSlots.Count -eq 0) { $availableSlots = @(0..11) }
                }
            } catch {
                # Visual layer failure must never block the real configuration.
            }
        }
    }

    $delay = Get-Random -Minimum 400 -Maximum 1800
    if ((Get-Random -Minimum 1 -Maximum 5) -eq 1) {
        $delay += Get-Random -Minimum 700 -Maximum 1300
    }
    $script:hackerNextSpawnAt = $now.AddMilliseconds($delay)
}

function Start-HackerConsoles {
    $script:hackerProcs = @()
    $script:hackerStormActive = $true
    $script:hackerTargetMax = Get-Random -Minimum 5 -Maximum 9
    $script:hackerNextSpawnAt = (Get-Date).AddMilliseconds((Get-Random -Minimum 350 -Maximum 1300))
    $script:hackerNextTargetChangeAt = (Get-Date).AddSeconds((Get-Random -Minimum 5 -Maximum 10))
    if ($script:hackerTimer) {
        $script:hackerTimer.Start()
    }
    try {
        Update-HackerConsoles
    } catch {
    }
}

function Stop-HackerConsoles {
    $script:hackerStormActive = $false
    if ($script:hackerTimer) {
        $script:hackerTimer.Stop()
    }
    foreach ($item in @($script:hackerProcs)) {
        try {
            if ($item.Process -and -not $item.Process.HasExited) { $item.Process.Kill() }
        } catch {
        }
    }
    $script:hackerProcs = @()
}

function Show-Success {
    if ($script:successShown) { return }
    $script:successShown = $true
    Stop-HackerConsoles
    $timer.Stop()
    Set-Running $false
    $btnStart.Enabled = $false
    $progress.Style = "Blocks"
    $progress.Value = 100
    $status.Text = "配置成功 - 请用新 Wi-Fi 连接后认证"
    $status.ForeColor = $green
    $progress.MarqueeAnimationSpeed = 0

    $success = New-Object System.Windows.Forms.Form
    $success.Text = "配置成功"
    $success.ClientSize = New-Object System.Drawing.Size(620, 430)
    $success.StartPosition = "CenterParent"
    $success.FormBorderStyle = "FixedDialog"
    $success.MaximizeBox = $false
    $success.MinimizeBox = $false
    $success.BackColor = [System.Drawing.Color]::White
    $success.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)

    $successHeader = New-Object System.Windows.Forms.Panel
    $successHeader.Location = New-Object System.Drawing.Point(0, 0)
    $successHeader.Size = New-Object System.Drawing.Size(620, 72)
    $successHeader.BackColor = $green
    $success.Controls.Add($successHeader)

    $successTitle = New-Object System.Windows.Forms.Label
    $successTitle.Text = "配置成功"
    $successTitle.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 18, [System.Drawing.FontStyle]::Bold)
    $successTitle.ForeColor = [System.Drawing.Color]::White
    $successTitle.AutoSize = $true
    $successTitle.Location = New-Object System.Drawing.Point(24, 18)
    $successHeader.Controls.Add($successTitle)

    if ($chkDefaultWifi.Checked) {
        $wifiText = "Wi-Fi：请使用路由器底部标签上的原名称和密码"
    } else {
        $wifiText = "Wi-Fi 2.4G：$($txtSsid2g.Text)`r`nWi-Fi 5G：$($txtSsid5g.Text)`r`nWi-Fi 密码：$($txtWifiPass.Text)"
    }

    $info = New-Object System.Windows.Forms.Label
    $info.Text = $wifiText + "`r`n`r`n请连接上面的 Wi-Fi，然后打开：`r`nhttp://10.112.0.1`r`n`r`n每台设备用各自的校园网账号登录。`r`n如果打不开认证页：确认 ZXHN 的 WAN 已接校园网墙口，设备 IP 应为 10.112.x.x。"
    $info.Location = New-Object System.Drawing.Point(28, 94)
    $info.Size = New-Object System.Drawing.Size(560, 230)
    $info.ForeColor = $dark
    $success.Controls.Add($info)
    $script:lastSuccessText = $info.Text

    $copy = New-Object System.Windows.Forms.Button
    $copy.Text = "复制配置信息"
    $copy.Location = New-Object System.Drawing.Point(28, 350)
    $copy.Size = New-Object System.Drawing.Size(150, 38)
    $copy.BackColor = [System.Drawing.Color]::FromArgb(230, 242, 255)
    $copy.FlatStyle = "Flat"
    $copy.FlatAppearance.BorderSize = 0
    $success.Controls.Add($copy)

    $close = New-Object System.Windows.Forms.Button
    $close.Text = "关闭"
    $close.Location = New-Object System.Drawing.Point(500, 350)
    $close.Size = New-Object System.Drawing.Size(90, 38)
    $close.BackColor = $green
    $close.ForeColor = [System.Drawing.Color]::White
    $close.FlatStyle = "Flat"
    $close.FlatAppearance.BorderSize = 0
    $success.Controls.Add($close)

    Set-HackerTheme $success
    $success.Text = "ZXHN // BRIDGE ESTABLISHED"
    $successHeader.BackColor = [System.Drawing.Color]::FromArgb(3, 20, 13)
    $successTitle.Text = "[ BRIDGE ESTABLISHED ]"
    $successTitle.Font = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
    $successTitle.ForeColor = $neon
    $info.ForeColor = $hackText
    $copy.BackColor = $hackPanel
    $copy.ForeColor = $cyan
    $close.BackColor = $neon
    $close.ForeColor = $hackBg

    $copy.Add_Click({
        [System.Windows.Forms.Clipboard]::SetText($script:lastSuccessText)
        [System.Windows.Forms.MessageBox]::Show("配置信息已复制。", "提示")
    })
    $close.Add_Click({ $success.Close() })
    $success.ShowDialog($form) | Out-Null
}

function Show-Failure([string]$message) {
    if ($script:successShown) { return }
    Stop-HackerConsoles
    $timer.Stop()
    Set-Running $false
    $progress.Style = "Blocks"
    $progress.Value = 0
    $status.Text = "配置失败"
    $status.ForeColor = [System.Drawing.Color]::FromArgb(190, 40, 40)

    $fail = New-Object System.Windows.Forms.Form
    $fail.Text = "ZXHN // CONFIGURATION FAILURE"
    $fail.ClientSize = New-Object System.Drawing.Size(720, 480)
    $fail.StartPosition = "CenterParent"
    $fail.FormBorderStyle = "FixedDialog"
    $fail.MaximizeBox = $false
    $fail.MinimizeBox = $false
    $fail.BackColor = $hackBg
    $fail.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)

    $failHeader = New-Object System.Windows.Forms.Panel
    $failHeader.Location = New-Object System.Drawing.Point(0, 0)
    $failHeader.Size = New-Object System.Drawing.Size(720, 64)
    $failHeader.BackColor = [System.Drawing.Color]::FromArgb(26, 5, 8)
    $fail.Controls.Add($failHeader)

    $failTitle = New-Object System.Windows.Forms.Label
    $failTitle.Text = "[ CONFIGURATION FAILURE ]"
    $failTitle.Font = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
    $failTitle.ForeColor = $magenta
    $failTitle.AutoSize = $true
    $failTitle.Location = New-Object System.Drawing.Point(22, 18)
    $failHeader.Controls.Add($failTitle)

    $failBox = New-Object System.Windows.Forms.TextBox
    $failBox.Location = New-Object System.Drawing.Point(20, 82)
    $failBox.Size = New-Object System.Drawing.Size(680, 320)
    $failBox.Multiline = $true
    $failBox.ReadOnly = $true
    $failBox.ScrollBars = "Vertical"
    $failBox.BorderStyle = "FixedSingle"
    $failBox.BackColor = $hackInput
    $failBox.ForeColor = $hackText
    $failBox.Text = $message
    $fail.Controls.Add($failBox)

    $failOk = New-Object System.Windows.Forms.Button
    $failOk.Text = "ACKNOWLEDGE"
    $failOk.Location = New-Object System.Drawing.Point(580, 420)
    $failOk.Size = New-Object System.Drawing.Size(120, 36)
    $failOk.BackColor = $hackPanel
    $failOk.ForeColor = $neon
    $failOk.FlatStyle = "Flat"
    $failOk.FlatAppearance.BorderSize = 1
    $failOk.FlatAppearance.BorderColor = $neon
    $fail.Controls.Add($failOk)

    Set-HackerTheme $fail
    $fail.BackColor = $hackBg
    $failHeader.BackColor = [System.Drawing.Color]::FromArgb(26, 5, 8)
    $failTitle.ForeColor = $magenta
    $failBox.BackColor = $hackInput
    $failBox.ForeColor = $hackText
    $failOk.BackColor = $hackPanel
    $failOk.ForeColor = $neon
    $failOk.Add_Click({ $fail.Close() })
    $fail.ShowDialog($form) | Out-Null
}

function Request-Success {
    if ($script:successShown) { return }
    $elapsed = 0
    if ($script:configStartedAt) {
        $elapsed = ((Get-Date) - $script:configStartedAt).TotalSeconds
    }
    if ($script:successPending -or $elapsed -ge $script:visualRunwaySeconds) {
        Show-Success
        return
    }
    $script:successPending = $true
    $remaining = [Math]::Ceiling($script:visualRunwaySeconds - $elapsed)
    $status.Text = "配置已提交 // 视觉序列继续运行 ${remaining}s"
    $status.ForeColor = $cyan
}

function Update-Status {
    if ($script:successPending) {
        $elapsed = 0
        if ($script:configStartedAt) {
            $elapsed = ((Get-Date) - $script:configStartedAt).TotalSeconds
        }
        if ($elapsed -ge $script:visualRunwaySeconds) {
            Show-Success
        } else {
            $remaining = [Math]::Ceiling($script:visualRunwaySeconds - $elapsed)
            $status.Text = "配置已提交 // 视觉序列继续运行 ${remaining}s"
            $status.ForeColor = $cyan
        }
        return
    }
    if (Test-Path -LiteralPath $script:logPath) {
        $text = Get-Content -LiteralPath $script:logPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($null -eq $text) { $text = "" }
        if ($text -ne $script:lastLog) {
            $script:lastLog = $text
            if ($logBox.Visible) {
                $logBox.Text = $text
                $logBox.SelectionStart = $logBox.TextLength
                $logBox.ScrollToCaret()
            }
            $progressLines = @($text -split "`r?`n" | Where-Object { $_ -match "^PROGRESS:" })
            if ($progressLines.Count -gt 0) {
                $status.Text = $progressLines[-1].Substring(9).Trim()
                $status.ForeColor = $dark
            }
            if ($text -match "APPLIED:") {
                Request-Success
                return
            }
            if ($text -match "FAILED:") {
                $line = @($text -split "`r?`n" | Where-Object { $_ -match "FAILED:" })[-1]
                Show-Failure $line
                return
            }
        }
    }

    if ($script:proc -and $script:proc.HasExited) {
        Start-Sleep -Milliseconds 300
        $text = ""
        if (Test-Path -LiteralPath $script:logPath) {
            $text = Get-Content -LiteralPath $script:logPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        $err = ""
        if (Test-Path -LiteralPath $script:errPath) {
            $err = Get-Content -LiteralPath $script:errPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        }
        if ($text -match "APPLIED:") {
            Request-Success
        } else {
            $timer.Stop()
            $msg = "路由器配置没有完成。`r`n`r`n请检查：`r`n1. 电脑是否连接 ZXHN 的 LAN 口或默认 Wi-Fi；`r`n2. 管理密码是否是底部标签上的密码；`r`n3. 192.168.10.1 是否能打开。"
            $failedLine = @($text -split "`r?`n" | Where-Object { $_ -match "FAILED:" })[-1]
            if ($failedLine) { $msg += "`r`n`r`n" + $failedLine.Trim() }
            if ($err) { $msg += "`r`n`r`n技术信息：`r`n" + $err.Trim() }
            Show-Failure $msg
        }
    }
}

function Start-Config {
    $script:successShown = $false
    $script:successPending = $false
    $script:configStartedAt = $null
    $script:lastLog = ""
    Stop-HackerConsoles
    if ([string]::IsNullOrWhiteSpace($txtPassword.Text)) {
        [System.Windows.Forms.MessageBox]::Show("请输入路由器底部标签上的管理密码。", "缺少密码") | Out-Null
        $txtPassword.Focus() | Out-Null
        return
    }
    if (-not $chkDefaultWifi.Checked) {
        if ([string]::IsNullOrWhiteSpace($txtSsid2g.Text) -or
            [string]::IsNullOrWhiteSpace($txtSsid5g.Text) -or
            $txtWifiPass.Text.Length -lt 8) {
            [System.Windows.Forms.MessageBox]::Show("自定义 Wi-Fi 时，请填写 2.4G/5G 名称和至少 8 位的 Wi-Fi 密码。", "参数不完整") | Out-Null
            return
        }
    }
    if (-not (Test-Router)) {
        $status.Text = "预检查较慢，正在直接尝试打开 192.168.10.1..."
    }

    $script:logPath = Join-Path $env:TEMP ("zxhn_gui_" + [guid]::NewGuid().ToString("N") + ".log")
    $script:errPath = Join-Path $env:TEMP ("zxhn_gui_" + [guid]::NewGuid().ToString("N") + ".err")
    $script:configStartedAt = Get-Date
    Set-Content -LiteralPath $script:logPath -Value "" -Encoding UTF8
    Set-Content -LiteralPath $script:errPath -Value "" -Encoding UTF8
    Set-Running $true
    $status.Text = "正在启动配置引擎..."
    $status.ForeColor = $dark
    $btnStart.Enabled = $false
    if ($logBox.Visible) { $logBox.Text = "" }

    $tool = Join-Path $PSScriptRoot "zxhn_bridge_tool.js"
    if (-not (Test-Path -LiteralPath $tool)) {
        $tool = Join-Path (Split-Path $PSScriptRoot -Parent) "zxhn_bridge_tool.js"
    }
    $node = Join-Path $PSScriptRoot "node.exe"
    if (-not (Test-Path -LiteralPath $node)) {
        $node = (Get-Command node.exe -ErrorAction SilentlyContinue).Source
    }
    if (-not $node -or -not (Test-Path -LiteralPath $node) -or -not (Test-Path -LiteralPath $tool)) {
        Set-Running $false
        Show-Failure "工具文件不完整：找不到 node.exe 或配置脚本。请重新解压完整工具包。"
        return
    }

    $env:ZXHN_PASSWORD = $txtPassword.Text
    $env:ZXHN_SSID2G = $txtSsid2g.Text
    $env:ZXHN_SSID5G = $txtSsid5g.Text
    $env:ZXHN_WIFI_PASS = $txtWifiPass.Text
    $argString = "`"$tool`" --router 192.168.10.1 --apply"
    try {
        $script:proc = Start-Process -FilePath $node `
            -ArgumentList $argString `
            -WorkingDirectory $PSScriptRoot `
            -RedirectStandardOutput $script:logPath `
            -RedirectStandardError $script:errPath `
            -PassThru -WindowStyle Hidden
    } catch {
        Set-Running $false
        Show-Failure "无法启动配置进程：$($_.Exception.Message)"
        return
    } finally {
        Remove-Item Env:ZXHN_PASSWORD -ErrorAction SilentlyContinue
        Remove-Item Env:ZXHN_SSID2G -ErrorAction SilentlyContinue
        Remove-Item Env:ZXHN_SSID5G -ErrorAction SilentlyContinue
        Remove-Item Env:ZXHN_WIFI_PASS -ErrorAction SilentlyContinue
    }
    $timer.Start()
    Start-HackerConsoles
}

$badge = New-Object System.Windows.Forms.Label
$badge.Text = "[ LOCAL / OFFLINE / SECURE ]"
$badge.Font = New-Object System.Drawing.Font("Consolas", 9)
$badge.ForeColor = $cyan
$badge.AutoSize = $true
$badge.Location = New-Object System.Drawing.Point(516, 28)
$header.Controls.Add($badge)

$neonLine = New-Object System.Windows.Forms.Panel
$neonLine.Location = New-Object System.Drawing.Point(0, 86)
$neonLine.Size = New-Object System.Drawing.Size(780, 2)
$neonLine.BackColor = $neon
$form.Controls.Add($neonLine)

Set-HackerTheme $form
$form.Text = "ZXHN // BRIDGE PROTOCOL"
$header.BackColor = $hackBg
$title.Text = "ZXHN // BRIDGE PROTOCOL"
$title.Font = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = $neon
$subtitle.Text = "[ SECURE LOCAL CONFIGURATION ENGINE // ZXHN Z503 ]"
$subtitle.Font = New-Object System.Drawing.Font("Consolas", 9)
$subtitle.ForeColor = $cyan
$badge.ForeColor = $cyan
$neonLine.BackColor = $neon
$btnStart.BackColor = $neon
$btnStart.ForeColor = $hackBg
$btnExit.BackColor = $hackPanel
$btnExit.ForeColor = $hackText
$status.ForeColor = $neon
$warning.ForeColor = $magenta
$logBox.BackColor = $hackInput
$logBox.ForeColor = $neon
$logBox.Visible = $true
$chkLog.Checked = $true
$form.Height = 760
$logBox.Text = "[BOOT] ZXHN-BRIDGE-ENGINE 7.0.0`r`n[ OK ] secure local UI online`r`n[ OK ] irregular 12-channel scheduler armed`r`n[ OK ] visual runway target = 20 seconds`r`n[ WAIT ] operator input required...`r`n"

$chkDefaultWifi.Add_CheckedChanged({ Set-WifiFields })
$btnStart.Add_Click({ Start-Config })
$btnExit.Add_Click({ $form.Close() })
$chkLog.Add_CheckedChanged({
    $logBox.Visible = $chkLog.Checked
    if ($logBox.Visible) { $form.Height = 760 }
    else { $form.Height = 720 }
})
$timer.Add_Tick({ Update-Status })
$script:hackerTimer.Add_Tick({ Update-HackerConsoles })
$form.Add_FormClosing({
    param($sender, $e)
    if ($script:proc -and -not $script:proc.HasExited) {
        $e.Cancel = $true
        [System.Windows.Forms.MessageBox]::Show("配置正在进行，请等待完成。", "请稍候") | Out-Null
    } else {
        $timer.Stop()
        Stop-HackerConsoles
        Remove-Item -LiteralPath $script:logPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:errPath -Force -ErrorAction SilentlyContinue
    }
})

if ($LayoutOnly) {
    $form.Show()
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 1500
    $bmp = New-Object System.Drawing.Bitmap($form.Width, $form.Height)
    $form.DrawToBitmap($bmp, (New-Object System.Drawing.Rectangle(0, 0, $form.Width, $form.Height)))
    $bmp.Save((Join-Path $PSScriptRoot "zxhn_gui_preview.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $form.Close()
    return
}

[System.Windows.Forms.Application]::Run($form)
