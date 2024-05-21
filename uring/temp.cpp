#include "uring_test.h"
#include <iostream>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>

#define QUEUE_DEPTH 32
#define BLOCK_SIZE 128
#define OFFSET 1024

int main() {
    struct io_uring ring;

    // io_uring 초기화
    if (io_uring_queue_init(QUEUE_DEPTH, &ring, 0) < 0) {
        std::cerr << "io_uring_queue_init failed" << std::endl;
        return 1;
    }

    // 파일 열기
    const char *file_path = "/dev/nvme0n1";
    int fd = open(file_path, O_RDONLY);
    if (fd < 0) {
        std::cerr << "Failed to open file" << std::endl;
        return 1;
    }

    // 읽기 버퍼 할당
    char buffer[BLOCK_SIZE];

    // sqe (submission queue entry) 준비
    struct io_uring_sqe *sqe = io_uring_get_sqe(&ring);
    if (!sqe) {
        std::cerr << "Failed to get SQE" << std::endl;
        return 1;
    }

    // passthrough read 설정
    io_uring_prep_read(sqe, fd, buffer, BLOCK_SIZE, OFFSET);

    // 제출하고 완료 대기
    io_uring_submit(&ring);

    struct io_uring_cqe *cqe;
    int ret = io_uring_wait_cqe(&ring, &cqe);
    if (ret < 0) {
        std::cerr << "io_uring_wait_cqe failed" << std::endl;
        return 1;
    }

    // 결과 확인
    if (cqe->res < 0) {
        std::cerr << "Async read failed" << std::endl;
    } else {
        std::cout << "Read " << cqe->res << " bytes from file" << std::endl;
        std::cout.write(buffer, cqe->res);
    }

    // CQE (completion queue entry) 완료 알림
    io_uring_cqe_seen(&ring, cqe);

    // 파일 닫기
    close(fd);

    // io_uring 종료
    io_uring_queue_exit(&ring);

    return 0;
}
