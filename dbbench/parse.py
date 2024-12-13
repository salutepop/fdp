# 파일 이름을 설정합니다.
filename = "cns.log"

# append_data와 FileSize의 총합을 저장할 변수를 초기화합니다.
total_append_data = 0
total_file_size = 0

# 파일을 읽습니다.
with open(filename, "r") as file:
    for line in file:
        # 각 줄에서 append_data와 FileSize 값을 찾기 위해 문자열을 분리합니다.
        parts = line.split(", ")
        for part in parts:
            if "append_data" in part:
                # append_data의 값을 추출합니다.
                append_data_value = int(part.split()[-1])
                # 값을 합계에 더합니다.
                total_append_data += append_data_value
            elif "FileSize" in part:
                # FileSize의 값을 추출합니다.
                file_size_value = int(part.split()[-1])
                # 값을 합계에 더합니다.
                total_file_size += file_size_value

# 1024 * 1024로 나누어 메가바이트 단위로 변환합니다.
total_append_data_mb = total_append_data / (1024 * 1024)
total_file_size_mb = total_file_size / (1024 * 1024)

# 최종 합계를 메가바이트 단위로 출력합니다.
print(f"Total append_data: {total_append_data_mb:.2f} MB")
print(f"Total FileSize: {total_file_size_mb:.2f} MB")

