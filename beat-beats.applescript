on run
  tell application "Music"
    if not (exists current track) then error "現在再生中の曲がありません。"
    set t to current track

    set trackName to (name of t as text)
    set artistName to (artist of t as text)

    set albumName to ""
    try
      set albumName to (album of t as text)
    end try

    set artTemp to ""
    if (count of artworks of t) > 0 then
      set aw to artwork 1 of t
      set raw to data of aw
      set artTemp to (POSIX path of (path to temporary items)) & "nowplaying_artwork_raw"
      my writeBinary(raw, artTemp) -- 純AppleScriptでバイナリ書き出し
    end if
  end tell

  -- クリップボード
  set msg to "Title: " & trackName & return
  if albumName is not "" then set msg to msg & "Album: " & albumName & return
  set msg to msg & "Artist: " & artistName
  set the clipboard to msg

  if artTemp is not "" then
    set safeTitle to my sanitizeFilename(trackName)
    set safeArtist to my sanitizeFilename(artistName)
    set timeTag to do shell script "date +%Y%m%d-%H%M%S"
    set outPNG to (POSIX path of (path to desktop)) & "NowPlaying_" & timeTag & "_" & safeTitle & " - " & safeArtist & ".png"

    try
      do shell script "/usr/bin/sips -s format png " & my shQuote(artTemp) & " --out " & my shQuote(outPNG)
      display notification "カバーアート（PNG）を保存しました" with title "Now Playing" subtitle outPNG
    on error errMsg
      -- sips失敗 → ヘッダを見て元形式で保存
      set ext to my sniffExt(artTemp) -- "jpg" / "png" / "tiff" / "bin"
      set outRaw to (POSIX path of (path to desktop)) & "NowPlaying_" & timeTag & "_" & safeTitle & " - " & safeArtist & "." & ext
      do shell script "/bin/cp " & my shQuote(artTemp) & " " & my shQuote(outRaw)
      display notification "PNG変換に失敗。元形式で保存しました（." & ext & "）" with title "Now Playing" subtitle outRaw
    end try
  else
    display notification "アートワーク無し。テキストのみコピーしました" with title "Now Playing"
  end if
end run

-- ===== ユーティリティ =====

-- 純AppleScriptでバイナリ書き出し
on writeBinary(rawData, posixPath)
  set f to open for access (posix file posixPath as text) with write permission
  try
    set eof f to 0
    write rawData to f
  end try
  close access f
end writeBinary

-- ヘッダから拡張子推定（jpeg/png/tiff/その他bin）
on sniffExt(posixPath)
  try
    set hex to do shell script "/bin/dd if=" & my shQuote(posixPath) & " bs=1 count=12 2>/dev/null | /usr/bin/xxd -p"
  on error
    return "bin"
  end try
  set hex to (do shell script "printf %s " & my shQuote(hex) & " | tr '[:upper:]' '[:lower:]'")
  if hex starts with "ffd8ff" then return "jpg"
  if hex starts with "89504e470d0a1a0a" then return "png"
  if hex starts with "49492a00" or hex starts with "4d4d002a" then return "tiff"
  return "bin"
end sniffExt

on sanitizeFilename(t)
  set s to my replaceText(t, "/", "／")
  set s to my replaceText(s, ":", "：")
  set s to my replaceText(s, "*", "＊")
  set s to my replaceText(s, "?", "？")
  set s to my replaceText(s, "\"", "”")
  set s to my replaceText(s, "<", "＜")
  set s to my replaceText(s, ">", "＞")
  set s to my replaceText(s, "|", "｜")
  set s to my replaceText(s, return, " ")
  set s to my replaceText(s, linefeed, " ")
  return s
end sanitizeFilename

on shQuote(p)
  return "'" & (my replaceText(p, "'", "'\\''")) & "'"
end shQuote

on replaceText(theText, search, replacement)
  set AppleScript's text item delimiters to search
  set xs to text items of theText
  set AppleScript's text item delimiters to replacement
  set out to xs as text
  set AppleScript's text item delimiters to ""
  return out
end replaceText
