#!/usr/bin/env bash
# 원본 영상 → 센티넬 쇼츠 규격(1080x1920, 30fps, -14 LUFS) 변환 + 자막 번인
# 사용법: sentinel_short.sh <입력.mp4> <자막.srt | -> <출력.mp4>
set -euo pipefail

if [ $# -ne 3 ]; then
  echo "사용법: $0 <입력.mp4> <자막.srt | -> <출력.mp4>" >&2
  exit 1
fi

IN="$1"; SUBS="$2"; OUT="$3"
FONT="${FONT:-Noto Sans CJK KR}"
FONT_SIZE="${FONT_SIZE:-16}"

# 가로든 세로든 9:16 화면을 꽉 채우도록 확대 후 중앙 크롭
VF="scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,fps=30"

if [ "$SUBS" != "-" ]; then
  [ -f "$SUBS" ] || { echo "자막 파일 없음: $SUBS" >&2; exit 1; }
  # 하단 UI에 가리지 않도록 MarginV로 위로 올림
  STYLE="FontName=${FONT},FontSize=${FONT_SIZE},Bold=1,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=3,Shadow=0,Alignment=2,MarginV=110"
  SUBS_ESC=$(printf '%s' "$SUBS" | sed "s/\\\\/\\\\\\\\/g; s/:/\\\\:/g; s/'/\\\\'/g")
  VF="${VF},subtitles='${SUBS_ESC}':force_style='${STYLE}'"
fi

if ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$IN" | grep -q .; then
  AUDIO=(-af "loudnorm=I=-14:TP=-1.5:LRA=11" -c:a aac -b:a 192k -ar 48000)
else
  AUDIO=(-an)
fi

ffmpeg -hide_banner -y -i "$IN" -vf "$VF" \
  -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -profile:v high \
  "${AUDIO[@]}" -movflags +faststart "$OUT"

echo "완료: $OUT"
