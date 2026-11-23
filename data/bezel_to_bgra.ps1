# bezel_to_bgra.ps1 - For MPV-SW-Capture - By TyRaS-SW
# Converts a bezel PNG into a raw BGRA bitmap for mpv's overlay-add command.
#
#   * scales the PNG to W x H (the canvas size the bezel is drawn for)
#   * flattens it over black (same as mpv showed transparent pixels before)
#   * punches a fully transparent hole where the video must show through
#   * writes raw 8-bit BGRA, premultiplied alpha, stride = W * 4
#
# Called by nso_retro.lua. Place this file in <mpv config>/data/.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File bezel_to_bgra.ps1
#       -Src bezel.png -Dest out.bgra -W 2560 -H 1440
#       -HoleX 400 -HoleY 34 -HoleW 1760 -HoleH 1374

param(
    [Parameter(Mandatory = $true)][string]$Src,
    [Parameter(Mandatory = $true)][string]$Dest,
    [Parameter(Mandatory = $true)][int]$W,
    [Parameter(Mandatory = $true)][int]$H,
    [int]$HoleX = 0,
    [int]$HoleY = 0,
    [int]$HoleW = 0,
    [int]$HoleH = 0
)

$ErrorActionPreference = 'Stop'

try {
    Add-Type -AssemblyName System.Drawing

    $img = [System.Drawing.Image]::FromFile($Src)
    $bmp = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)

    $g.Clear([System.Drawing.Color]::Black)
    $g.CompositingMode    = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    # TileFlipXY avoids a faded 1 px halo on the outer edge of the image.
    $attr = New-Object System.Drawing.Imaging.ImageAttributes
    $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)

    $destRect = New-Object System.Drawing.Rectangle(0, 0, $W, $H)
    $g.DrawImage($img, $destRect, 0, 0, $img.Width, $img.Height, [System.Drawing.GraphicsUnit]::Pixel, $attr)

    if ($HoleW -gt 0 -and $HoleH -gt 0) {
        $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $clear = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        $g.FillRectangle($clear, $HoleX, $HoleY, $HoleW, $HoleH)
        $clear.Dispose()
    }

    $g.Dispose()
    $img.Dispose()

    $rect = New-Object System.Drawing.Rectangle(0, 0, $W, $H)
    $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
                          [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)

    $bytes = New-Object 'byte[]' ($data.Stride * $H)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
    $bmp.UnlockBits($data)
    $bmp.Dispose()

    # Write to a temp file first so mpv never reads a half-written bitmap.
    $tmp = "$Dest.tmp"
    [System.IO.File]::WriteAllBytes($tmp, $bytes)
    Move-Item -LiteralPath $tmp -Destination $Dest -Force

    Write-Output 'OK'
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
