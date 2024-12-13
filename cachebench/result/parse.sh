#!/bin/bash

# awk를 사용하여 각 블록을 파싱하고 한 줄로 변환
awk '
BEGIN {
    FS=":"   # 필드 구분자를 ":"로 설정
    OFS=", " # 출력 필드 구분자를 ", "로 설정
}
{
    if ($0 == "--") {   # "--"를 만나면 블록의 끝이므로 출력하고 초기화
        if (NR > 1) print output
        output = ""     # 출력 초기화
    } else {
        # 각 라인의 값을 추출하여 output에 추가
        value = $2      # ":" 뒤의 값을 추출
        gsub(/^[ \t]+| GB$/, "", value) # 공백과 " GB"를 제거
        output = output ? output OFS value : value
    }
}
END {
    if (output) print output # 마지막 블록 출력
}
' $1 > output.txt

# 결과 출력
cat output.txt

