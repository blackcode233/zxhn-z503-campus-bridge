param(
    [ValidateSet("PACKET", "CRYPTO", "BRIDGE", "KERNEL", "SESSION", "TRACE", "ARP", "DNS", "TLS", "ROUTE", "GRAPH", "MATRIX")]
    [string]$Mode = "TRACE",
    [string]$Title = "ZXHN://TRACE",
    [double]$Duration = 600,
    [ValidateRange(0, 11)]
    [int]$Slot = 0
)

try {
    $Host.UI.RawUI.WindowTitle = $Title
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "Green"
} catch {
}

function Set-ConsoleWindowLayout {
    param([int]$ConsoleSlot)

    try {
        Add-Type -AssemblyName System.Windows.Forms
        if (-not ("HackerNative" -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class HackerNative {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(
        IntPtr hWnd,
        IntPtr hWndInsertAfter,
        int x,
        int y,
        int cx,
        int cy,
        uint flags);
}
"@
        }

        $handle = [HackerNative]::GetConsoleWindow()
        if ($handle -eq [IntPtr]::Zero) { return }

        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $column = $ConsoleSlot % 4
        $row = [Math]::Floor($ConsoleSlot / 4)
        $baseWidth = [int]($screen.Width / 3.45)
        $baseHeight = [int]($screen.Height / 2.65)
        $width = Get-Random -Minimum ([int]($baseWidth * 0.78)) -Maximum ([int]($baseWidth * 1.18))
        $height = Get-Random -Minimum ([int]($baseHeight * 0.80)) -Maximum ([int]($baseHeight * 1.20))
        $x = $screen.Left + [int]($column * ($screen.Width / 4)) + (Get-Random -Minimum -34 -Maximum 35)
        $y = $screen.Top + [int]($row * ($screen.Height / 3)) + (Get-Random -Minimum -28 -Maximum 29)
        $x = [Math]::Max($screen.Left + 4, [Math]::Min($x, $screen.Right - $width - 4))
        $y = [Math]::Max($screen.Top + 4, [Math]::Min($y, $screen.Bottom - $height - 4))

        # SWP_NOZORDER = 0x0004, SWP_NOACTIVATE = 0x0010
        [HackerNative]::SetWindowPos($handle, [IntPtr]::Zero, $x, $y, $width, $height, 0x0014) | Out-Null
    } catch {
    }
}

function New-RandomHex {
    param([int]$Length = 32)
    $chars = "0123456789abcdef".ToCharArray()
    return -join (1..$Length | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum 16)] })
}

function Pick-Value {
    param([object[]]$Values)
    return Get-Random -InputObject $Values
}

Clear-Host
try {
    $size = $Host.UI.RawUI.WindowSize
    if ($size.Width -lt 82) { $size.Width = 82 }
    if ($size.Height -lt 20) { $size.Height = 20 }
    $Host.UI.RawUI.WindowSize = $size
} catch {
}
Set-ConsoleWindowLayout -ConsoleSlot $Slot

$modeName = $Mode.ToUpper()
$end = (Get-Date).AddSeconds($Duration)
$counter = 0
$colors = @("Green", "Cyan", "DarkGreen", "Gray", "Magenta", "Yellow", "White")

Write-Host "ZXHN NEURAL BRIDGE // $modeName CHANNEL // NODE $('{0:x2}' -f $Slot)" -ForegroundColor Cyan
Write-Host "[ VISUAL TELEMETRY SIMULATION // GENERATED TEXT ONLY // NO SYSTEM COMMANDS ]" -ForegroundColor Yellow
Write-Host ("#" * 104) -ForegroundColor DarkGreen

while ((Get-Date) -lt $end) {
    $counter++
    $stamp = (Get-Date).ToString("HH:mm:ss.fff")
    $hex = New-RandomHex 32
    $hex2 = New-RandomHex 64
    $n = Get-Random -Minimum 0 -Maximum 999999999
    $short = New-RandomHex 8
    $mac = (0..5 | ForEach-Object { "{0:x2}" -f (Get-Random -Minimum 0 -Maximum 256) }) -join ":"
    $seq = '{0:x6}' -f (Get-Random -Minimum 0 -Maximum 16777215)
    $line = ""

    switch ($modeName) {
        "PACKET" {
            switch (Get-Random -Minimum 1 -Maximum 7) {
                1 { $line = "[$stamp] [PKT] eth1 0x{0:x4} len={1} ttl={2} seq=0x{3} flow=0x{4:x8}" -f (Get-Random -Maximum 65535), (Get-Random -Minimum 40 -Maximum 1500), (Get-Random -Minimum 48 -Maximum 65), $seq, $n }
                2 { $line = "[$stamp] [PKT] RX mac=$mac src=10.112.{0}.{1} -> dst=10.112.0.1 sport={2} dport={3}" -f (Get-Random -Maximum 255), (Get-Random -Maximum 255), (Get-Random -Maximum 65535), (Get-Random -Maximum 65535) }
                3 { $line = "[$stamp] [PKT] fragment id=0x{0:x4} off=0x{1:x3} MF={2} checksum=0x{3:x4}" -f (Get-Random -Maximum 65535), (Get-Random -Maximum 8191), (Pick-Value @("0","1")), (Get-Random -Maximum 65535) }
                4 { $line = "[$stamp] [PKT] capture iface=br-lan bytes={0} queue={1} drop={2} noise={3}dB" -f (Get-Random -Minimum 64 -Maximum 9000), (Get-Random -Minimum 0 -Maximum 8), (Get-Random -Minimum 0 -Maximum 3), (Get-Random -Minimum -88 -Maximum -35) }
                5 { $line = "[$stamp] [PKT] trace hop={0} rtt={1}.{2}ms jitter={3}.{4}ms route=mesh-{5}" -f (Get-Random -Minimum 1 -Maximum 18), (Get-Random -Minimum 1 -Maximum 80), (Get-Random -Minimum 0 -Maximum 999), (Get-Random -Minimum 0 -Maximum 9), (Get-Random -Minimum 0 -Maximum 999), (Get-Random -Minimum 1 -Maximum 9) }
                default { $line = "[$stamp] [PKT] 0000  86 dd 60 00 00 00 00 18  3a ff 24 0a 42 be 36 01   |..`$....:`$...6.|" }
            }
        }
        "CRYPTO" {
            switch (Get-Random -Minimum 1 -Maximum 7) {
                1 { $line = "[$stamp] [CRY] sha256=$hex entropy=0x{0:x8} rounds={1} avalanche={2}.{3}%" -f $n, (Get-Random -Minimum 8 -Maximum 36), (Get-Random -Minimum 49 -Maximum 51), (Get-Random -Minimum 0 -Maximum 99) }
                2 { $line = "[$stamp] [CRY] key-exchange curve=X25519 state=TRANSIENT mixer=blake3-{0} session={1}" -f (Get-Random -Minimum 128 -Maximum 512), $short }
                3 { $line = "[$stamp] [CRY] hmac=0x{0} nonce={1} tag={2} verify=OK" -f $hex, $short, (New-RandomHex 16) }
                4 { $line = "[$stamp] [CRY] matrix[0x{0:x2}] ^= rotl(hash, {1}) // diffusion={2}" -f (Get-Random -Maximum 255), (Get-Random -Minimum 1 -Maximum 63), (Get-Random -Minimum 0 -Maximum 100) }
                5 { $line = "[$stamp] [CRY] argon2 lane={0} memory={1}KiB salt=0x{2} output=0x{3}" -f (Get-Random -Minimum 0 -Maximum 8), (Get-Random -Minimum 32768 -Maximum 262144), $short, $hex }
                default { $line = "[$stamp] [CRY] proof=0b{0} witness=0x{1} circuit-depth={2} gates={3}" -f (("01" * 12)), $hex, (Get-Random -Minimum 12 -Maximum 96), (Get-Random -Minimum 1200 -Maximum 99999) }
            }
        }
        "BRIDGE" {
            switch (Get-Random -Minimum 1 -Maximum 7) {
                1 { $line = "[$stamp] [BRG] br-lan vlan=0x{0:x3} port={1} mac=$mac state=FORWARD age={2}s" -f (Get-Random -Maximum 4096), (Get-Random -Minimum 1 -Maximum 5), (Get-Random -Maximum 300) }
                2 { $line = "[$stamp] [BRG] fdb sync bucket=0x{0:x4} digest={1} collisions={2} path=br-{3}" -f (Get-Random -Maximum 65535), $short, (Get-Random -Maximum 4), (Get-Random -Minimum 1 -Maximum 9) }
                3 { $line = "[$stamp] [BRG] stp root={0:x4} cost={1} hello={2}s forward-delay={3}s topology=STABLE" -f (Get-Random -Maximum 65535), (Get-Random -Minimum 1 -Maximum 20000), (Get-Random -Minimum 1 -Maximum 5), (Get-Random -Minimum 4 -Maximum 30) }
                4 { $line = "[$stamp] [BRG] port eth0 <- eth1 TCI:{0:x4} VID={1} PCP={2} DEI={3}" -f (Get-Random -Maximum 65535), (Get-Random -Maximum 4096), (Get-Random -Maximum 8), (Get-Random -Maximum 2) }
                5 { $line = "[$stamp] [BRG] graph edge {0}->{1} weight={2} dampening={3}.{4} state=SYNC" -f (Get-Random -Minimum 1 -Maximum 12), (Get-Random -Minimum 1 -Maximum 12), (Get-Random -Minimum 1 -Maximum 99), (Get-Random -Minimum 0 -Maximum 9), (Get-Random -Minimum 0 -Maximum 999) }
                default { $line = "[$stamp] [BRG] REBALANCE shard={0} flow=0x{1} watermark={2}% epoch={3}" -f (Get-Random -Minimum 0 -Maximum 15), $seq, (Get-Random -Minimum 1 -Maximum 99), (Get-Random -Minimum 1 -Maximum 9999) }
            }
        }
        "KERNEL" {
            switch (Get-Random -Minimum 1 -Maximum 7) {
                1 { $line = "[$stamp] [KRN] nf_conntrack hash=0x{0:x8} cpu={1} bridge=br-lan mod=xt_TTL gc={2}" -f $n, (Get-Random -Maximum 8), (Get-Random -Maximum 99) }
                2 { $line = "[$stamp] [KRN] softirq[{0}] net_rx {1}.{2}% net_tx {3}.{4}% backlog={5}" -f (Get-Random -Maximum 8), (Get-Random -Maximum 10), (Get-Random -Maximum 99), (Get-Random -Maximum 10), (Get-Random -Maximum 99), (Get-Random -Maximum 4096) }
                3 { $line = "[$stamp] [KRN] sched: entity type=eBPF pc=0x{0:x8} helper=map_lookup_elem cycles={1}" -f $n, (Get-Random -Minimum 30 -Maximum 6000) }
                4 { $line = "[$stamp] [KRN] memory zone=Normal free={0}MiB reclaim={1} deferred={2} slab={3}KiB" -f (Get-Random -Minimum 64 -Maximum 4096), (Get-Random -Maximum 64), (Get-Random -Maximum 255), (Get-Random -Minimum 100 -Maximum 9999) }
                5 { $line = "[$stamp] [KRN] tracepoint=net:net_dev_queue cpu={0} pid={1} dev=eth1 len={2} hash=0x{3}" -f (Get-Random -Maximum 8), (Get-Random -Minimum 100 -Maximum 65535), (Get-Random -Maximum 1500), $short }
                default { $line = "[$stamp] [KRN] === marker addr=0x{0:x8} delta={1}ns state=COMMITTED ===" -f $n, (Get-Random -Minimum 80 -Maximum 900000) }
            }
        }
        "SESSION" {
            switch (Get-Random -Minimum 1 -Maximum 7) {
                1 { $line = "[$stamp] [SES] handshake=0x{0:x8} token={1} state=SYNCHRONIZED retry={2}" -f $n, $short, (Get-Random -Maximum 3) }
                2 { $line = "[$stamp] [SES] session={0:x4} seq={1} ack={2} window={3} inflight={4}" -f (Get-Random -Maximum 65535), $seq, (New-RandomHex 6), (Get-Random -Minimum 512 -Maximum 65535), (Get-Random -Maximum 512) }
                3 { $line = "[$stamp] [SES] event=STATE_TRANSITION {0} -> {1} reason=visual-sync latency={2}ms" -f (Pick-Value @("INIT","OPEN","AUTH","READY","SYNC")), (Pick-Value @("OPEN","AUTH","READY","SYNC","STABLE")), (Get-Random -Minimum 1 -Maximum 99) }
                4 { $line = "[$stamp] [SES] actor=operator scope=read-only fingerprint={0} signature={1}" -f $short, (New-RandomHex 24) }
                5 { $line = "[$stamp] [SES] token-bucket rate={0}/s burst={1} used={2} backpressure={3}" -f (Get-Random -Minimum 50 -Maximum 2000), (Get-Random -Minimum 4 -Maximum 64), (Get-Random -Maximum 64), (Pick-Value @("OFF","LOW","MED")) }
                default { $line = "[$stamp] [SES] coalesce shard={0} waiters={1} completed={2} deadline={3}ms status=PASS" -f (Get-Random -Maximum 32), (Get-Random -Maximum 16), (Get-Random -Minimum 1 -Maximum 9999), (Get-Random -Minimum 2 -Maximum 90) }
            }
        }
        "TRACE" {
            switch (Get-Random -Minimum 1 -Maximum 7) {
                1 { $line = "[$stamp] [TRC] 0x{0:x8}  {1}  {2}  |{3}|" -f (Get-Random -Maximum 65535), (New-RandomHex 16), (New-RandomHex 16), ("." * (Get-Random -Minimum 2 -Maximum 14)) }
                2 { $line = "[$stamp] [TRC] stack frame #{0:x2} module=libbridge.so+0x{1:x6} symbol=visual_{2}" -f (Get-Random -Maximum 64), (Get-Random -Maximum 16777215), (Pick-Value @("sync","frame","walk","emit","seal")) }
                3 { $line = "[$stamp] [TRC] checksum expected=0x{0:x8} actual=0x{0:x8} width={1} lane={2} PASS" -f $n, (Get-Random -Minimum 8 -Maximum 64), (Get-Random -Maximum 8) }
                4 { $line = "[$stamp] [TRC] bytes={0} decoded={1} malformed=0 ambiguous={2} confidence=99.{3}%" -f (Get-Random -Minimum 128 -Maximum 99999), (Get-Random -Minimum 100 -Maximum 99999), (Get-Random -Maximum 4), (Get-Random -Maximum 99) }
                5 { $line = "[$stamp] [TRC] probe=0x{0} sampler=jackson-{1} window={2} rollover={3} opcode=0x{4:x4}" -f $seq, (Get-Random -Minimum 8 -Maximum 64), (Get-Random -Minimum 16 -Maximum 4096), (Get-Random -Maximum 9), (Get-Random -Maximum 65535) }
                default { $line = "[$stamp] [TRC] cmp [rbp-0x{0:x2}], 0x{1:x8}  je short zxhn_visual_{2}" -f (Get-Random -Maximum 255), $n, $short }
            }
        }
        "ARP" {
            $line = "[$stamp] [ARP] who-has 10.112.{0}.{1} tell 10.112.{2}.{3}  reply={4} iface=br-{5}" -f (Get-Random -Maximum 255), (Get-Random -Maximum 255), (Get-Random -Maximum 255), (Get-Random -Maximum 255), $mac, (Get-Random -Minimum 1 -Maximum 9)
        }
        "DNS" {
            switch (Get-Random -Minimum 1 -Maximum 5) {
                1 { $line = "[$stamp] [DNS] query id=0x{0:x4} type=A qname=visual-{1}.local flags=RD rcode=NOERROR" -f (Get-Random -Maximum 65535), $short }
                2 { $line = "[$stamp] [DNS] answer ttl={0} weight={1} host=10.112.{2}.{3} path=cache-{4}" -f (Get-Random -Minimum 5 -Maximum 86400), (Get-Random -Maximum 100), (Get-Random -Maximum 255), (Get-Random -Maximum 255), (Get-Random -Maximum 8) }
                3 { $line = "[$stamp] [DNS] resolve chain {0} -> {1} -> {2} rtt={3}.{4}ms status=OK" -f (Pick-Value @("root","edge","cache","relay")), (Pick-Value @("mesh-a","mesh-b","mesh-c","mesh-d")), (Pick-Value @("auth-1","auth-2","auth-3")), (Get-Random -Maximum 20), (Get-Random -Maximum 99) }
                4 { $line = "[$stamp] [DNS] CNAME ghost-{0}.visual.invalid -> node-{1}.mesh.invalid; cache_weight={2}" -f (Get-Random -Minimum 1 -Maximum 9999), (Get-Random -Minimum 1 -Maximum 99), (Get-Random -Maximum 255) }
                default { $line = "[$stamp] [DNS] EDNS0 payload={0} cookie={1} padding={2} DNSSEC=visual-valid" -f (Get-Random -Minimum 512 -Maximum 4096), $short, (Get-Random -Maximum 256) }
            }
        }
        "TLS" {
            switch (Get-Random -Minimum 1 -Maximum 5) {
                1 { $line = "[$stamp] [TLS] client-hello record=0x{0:x4} cipher=TLS_AES_{1}_GCM_SHA384 extension={2}" -f (Get-Random -Maximum 65535), (Pick-Value @("128","256")), (Get-Random -Minimum 8 -Maximum 64) }
                2 { $line = "[$stamp] [TLS] server-hello selected=0x{0:x4} group=X25519 key_share={1} resumed={2}" -f (Get-Random -Maximum 65535), $short, (Pick-Value @("0","1")) }
                3 { $line = "[$stamp] [TLS] transcript hash={0} finished=VERIFIED alert=NONE" -f $hex }
                4 { $line = "[$stamp] [TLS] hkdf stage=expand info=visual label={0} length={1} output=0x{2}" -f $short, (Get-Random -Minimum 16 -Maximum 128), (New-RandomHex 24) }
                default { $line = "[$stamp] [TLS] ALPN={0} SNI=visual.local session-ticket={1} early-data=DISABLED" -f (Pick-Value @("h2","http/1.1","visual/1")), $short }
            }
        }
        "ROUTE" {
            switch (Get-Random -Minimum 1 -Maximum 5) {
                1 { $line = "[$stamp] [RIB] 10.112.0.0/16 via {0}.{1}.{2}.{3} dev eth1 metric={4} scope=link" -f (Get-Random -Maximum 255), (Get-Random -Maximum 255), (Get-Random -Maximum 255), (Get-Random -Maximum 255), (Get-Random -Minimum 1 -Maximum 999) }
                2 { $line = "[$stamp] [RIB] nexthop id={0:x4} weight={1} as-path=[{2} {3}] preference=local-{4}" -f (Get-Random -Maximum 65535), (Get-Random -Minimum 1 -Maximum 32), (Get-Random -Minimum 100 -Maximum 65000), (Get-Random -Minimum 100 -Maximum 65000), (Get-Random -Maximum 9) }
                3 { $line = "[$stamp] [RIB] route-map {0} permit {1} match tag={2} set metric={3} state=candidate" -f (Pick-Value @("visual-in","visual-out","mesh-sync")), (Get-Random -Minimum 10 -Maximum 99), (Get-Random -Maximum 65000), (Get-Random -Minimum 1 -Maximum 999) }
                4 { $line = "[$stamp] [RIB] path repair {0}/{1} -> {2}/{3} dampening={4}.{5}% loop-check=PASS" -f (Get-Random -Minimum 1 -Maximum 32), (Get-Random -Minimum 1 -Maximum 32), (Get-Random -Minimum 1 -Maximum 32), (Get-Random -Minimum 1 -Maximum 32), (Get-Random -Minimum 1 -Maximum 9), (Get-Random -Maximum 99) }
                default { $line = "[$stamp] [RIB] FIB commit {0,4} routes shard={1} prefix={2:x4} generation={3}" -f (Get-Random -Minimum 100 -Maximum 9999), (Get-Random -Maximum 16), (Get-Random -Maximum 65535), (Get-Random -Maximum 99999) }
            }
        }
        "GRAPH" {
            switch (Get-Random -Minimum 1 -Maximum 6) {
                1 { $line = "[$stamp] [GPH] [A]--0x{0:x4}-->[B]--0x{1:x4}-->[C]--0x{2:x4}-->[D]  flow={3}" -f (Get-Random -Maximum 65535), (Get-Random -Maximum 65535), (Get-Random -Maximum 65535), (Get-Random -Minimum 1 -Maximum 999) }
                2 { $line = "[$stamp] [GPH] node=0x{0:x8} degree={1} centrality=0.{2} cluster={3} color=neon-{4}" -f $n, (Get-Random -Minimum 2 -Maximum 24), (Get-Random -Minimum 1000 -Maximum 9999), (Get-Random -Maximum 12), (Get-Random -Maximum 8) }
                3 { $line = "[$stamp] [GPH] cycle={0} residual={1} potential={2}.{3} augment=OK timestamp=0x{4}" -f (Get-Random -Minimum 1 -Maximum 99), (Get-Random -Minimum 1 -Maximum 999), (Get-Random -Maximum 99), (Get-Random -Maximum 99), $short }
                4 { $line = "[$stamp] [GPH] matrix +--------+ +--------+ +--------+   rank={0} pivot={1}" -f (Get-Random -Maximum 64), $short }
                5 { $line = "[$stamp] [GPH] prune branch={0:x4} keep={1} confidence={2}.{3}% entropy-window={4}" -f (Get-Random -Maximum 65535), (Get-Random -Minimum 1 -Maximum 999), (Get-Random -Minimum 90 -Maximum 100), (Get-Random -Maximum 99), (Get-Random -Minimum 4 -Maximum 64) }
                default { $line = "[$stamp] [GPH] ASCII  (A)===>(B)===>[C]~~~>{D}#{0}  {1}/{2} edges synchronized" -f $short, (Get-Random -Minimum 100 -Maximum 999), (Get-Random -Minimum 100 -Maximum 999) }
            }
        }
        default {
            switch (Get-Random -Minimum 1 -Maximum 6) {
                1 { $line = "[$stamp] [MTR] 0x{0:x8}  {1}  {2}  {3}  |{4}|" -f (Get-Random -Maximum 65535), (New-RandomHex 16), (New-RandomHex 16), (New-RandomHex 16), ("###" * (Get-Random -Minimum 2 -Maximum 7)) }
                2 { $line = "[$stamp] [MTR] 010{0} 110{1} 00{2}1 1{3}0  {4}  entropy=0x{5}" -f (Get-Random -Minimum 10 -Maximum 999), (Get-Random -Minimum 10 -Maximum 999), (Get-Random -Minimum 10 -Maximum 999), (Get-Random -Minimum 10 -Maximum 999), ("<>" * (Get-Random -Minimum 2 -Maximum 8)), $short }
                3 { $line = "[$stamp] [MTR] partition[{0:x2}] digest={1} scatter=0.{2} merge=STABLE lane={3}" -f (Get-Random -Maximum 255), $hex, (Get-Random -Minimum 1000 -Maximum 9999), (Get-Random -Maximum 8) }
                4 { $line = "[$stamp] [MTR] {0} {1} {2} {3}  | {4} |  phase={5}" -f (New-RandomHex 6), (New-RandomHex 6), (New-RandomHex 6), (New-RandomHex 6), (Pick-Value @("SEED","MIX","SWAP","SCAN","FOLD","SEAL")), (Get-Random -Minimum 1 -Maximum 99) }
                5 { $line = "[$stamp] [MTR] [+visual+]  [+entropy+]  [+bridge+]  -> 0x{0} verified" -f $short }
                default { $line = "[$stamp] [MTR] visual_engine::{0}<{1}> -> SHA3-{2} -> lattice[{3}] -> emits[0x{4}]" -f (Pick-Value @("run","scan","fold","emit")), $short, (Pick-Value @("256","384","512")), (Pick-Value @("hex","grid","wave","pulse")), $seq }
            }
        }
    }

    $color = Pick-Value $colors
    Write-Host $line -ForegroundColor $color

    if (($counter % 3) -eq 0) {
        $tokens = @(
            "  |> cycle={0} phase={1} checksum=0x{2} delta={3}us" -f (Get-Random -Minimum 1 -Maximum 99999), (Pick-Value @("SYNC","MIX","PASS","LOCK","TRACE")), $short, (Get-Random -Minimum 1 -Maximum 999),
            "  0x{0}: {1}  {2}  {3}" -f $seq, (New-RandomHex 24), (New-RandomHex 24), (Pick-Value @("OK","READY","FLOW","HOLD","SEAL")),
            "  [graph] A={0} B={1} C={2} D={3} weight=0x{4}" -f (Get-Random -Minimum 1 -Maximum 99), (Get-Random -Minimum 1 -Maximum 99), (Get-Random -Minimum 1 -Maximum 99), (Get-Random -Minimum 1 -Maximum 99), $short,
            "  emit visual_event type={0} entropy={1} lane={2} signature={3}" -f $modeName, (Get-Random -Minimum 1 -Maximum 999), (Get-Random -Maximum 8), (New-RandomHex 12)
        )
        Write-Host (Pick-Value $tokens) -ForegroundColor (Pick-Value @("Cyan", "Magenta", "DarkGray", "Green"))
    }

    if (($counter % 17) -eq 0) {
        Write-Host ("#" * (Get-Random -Minimum 18 -Maximum 84)) -ForegroundColor (Pick-Value @("Green", "Cyan", "Magenta"))
    }
    if (($counter % 23) -eq 0) {
        $json = '{"frame":"{0}","seq":{1},"entropy":"{2}","state":"SYNCHRONIZED","visual":true}' -f $short, $counter, $hex
        Write-Host "[JSON] $json" -ForegroundColor Cyan
    }
    if (($counter % 31) -eq 0) {
        Write-Host "[HEX ] $hex $hex2" -ForegroundColor DarkGray
        Write-Host "[HEX ] $hex2 $hex" -ForegroundColor DarkGray
    }
    if (($counter % 41) -eq 0) {
        Write-Host "[SYNC] control-plane heartbeat accepted latency=$((Get-Random -Minimum 1 -Maximum 12))ms state=FORWARD" -ForegroundColor Green
    }
    if (($counter % 53) -eq 0) {
        Write-Host "  if (frame.checksum == 0x$short) { bridge.emit(visualPacket); } else { trace.recover(); }" -ForegroundColor Yellow
    }
    if (($counter % 67) -eq 0) {
        Write-Host "  struct visual_node { u64 hash; u16 lane; u8 state; } node_$($counter % 16) = { 0x$short, $($counter % 16), READY };" -ForegroundColor Magenta
    }

    Start-Sleep -Milliseconds (Get-Random -Minimum 8 -Maximum 38)
}

Write-Host "[ SESSION CLOSED ] // node $('{0:x2}' -f $Slot)" -ForegroundColor DarkGreen
Start-Sleep -Milliseconds 500
