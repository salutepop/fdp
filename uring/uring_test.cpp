#include "uring_test.h"
#include <iostream>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>

// 이 함수는 주어진 character device 경로에서 데이터를 읽어와 output에 저장합니다.
bool read_character_device(const std::string &device_path, std::string &output) {
    const size_t buffer_size = 4096;
    char buffer[buffer_size];
    int fd = open(device_path.c_str(), O_RDONLY);
    if (fd < 0) {
        std::cerr << "Failed to open device: " << strerror(errno) << std::endl;
        return false;
    }

    struct io_uring ring;
    if (io_uring_queue_init(32, &ring, 0) < 0) {
        std::cerr << "Failed to initialize io_uring" << std::endl;
        close(fd);
        return false;
    }

    struct io_uring_sqe *sqe = io_uring_get_sqe(&ring);
    if (!sqe) {
        std::cerr << "Failed to get submission queue entry" << std::endl;
        io_uring_queue_exit(&ring);
        close(fd);
        return false;
    }

    // io_uring_cmd로 I/O 명령 준비
    io_uring_prep_read(sqe, fd, buffer, buffer_size, 0);

    struct io_uring_cqe *cqe;
    if (io_uring_submit_and_wait(&ring, 1) < 0) {
        std::cerr << "Failed to submit and wait" << std::endl;
        io_uring_queue_exit(&ring);
        close(fd);
        return false;
    }

    if (io_uring_wait_cqe(&ring, &cqe) < 0) {
        std::cerr << "Failed to wait for completion queue entry" << std::endl;
        io_uring_queue_exit(&ring);
        close(fd);
        return false;
    }

    if (cqe->res < 0) {
        std::cerr << "I/O error: " << strerror(-cqe->res) << std::endl;
        io_uring_cqe_seen(&ring, cqe);
        io_uring_queue_exit(&ring);
        close(fd);
        return false;
    }

    // I/O 성공 시, 결과를 버퍼에 저장
    output.assign(buffer, cqe->res);

    io_uring_cqe_seen(&ring, cqe);
    io_uring_queue_exit(&ring);
    close(fd);
    return true;
}

// 이 함수는 주어진 파일 경로에서 데이터를 읽어와 output에 저장합니다.
bool read_file(const std::string &file_path, std::string &output) {
    const size_t buffer_size = 4096;
    char buffer[buffer_size];
    int fd = open(file_path.c_str(), O_RDONLY);
    if (fd < 0) {
        std::cerr << "Failed to open file: " << strerror(errno) << std::endl;
        return false;
    }

    struct io_uring ring;
    if (io_uring_queue_init(32, &ring, 0) < 0) {
        std::cerr << "Failed to initialize io_uring" << std::endl;
        close(fd);
        return false;
    }

    struct io_uring_sqe *sqe = io_uring_get_sqe(&ring);
    if (!sqe) {
        std::cerr << "Failed to get submission queue entry" << std::endl;
        io_uring_queue_exit(&ring);
        close(fd);
        return false;
    }

    io_uring_prep_read(sqe, fd, buffer, buffer_size, 0);
    struct io_uring_cqe *cqe;
    if (io_uring_submit_and_wait(&ring, 1) < 0) {
        std::cerr << "Failed to submit and wait" << std::endl;
        io_uring_queue_exit(&ring);
        close(fd);
        return false;
    }

    if (io_uring_wait_cqe(&ring, &cqe) < 0) {
        std::cerr << "Failed to wait for completion queue entry" << std::endl;
        io_uring_queue_exit(&ring);
        close(fd);
        return false;
    }

    if (cqe->res < 0) {
        std::cerr << "I/O error: " << strerror(-cqe->res) << std::endl;
        io_uring_cqe_seen(&ring, cqe);
        io_uring_queue_exit(&ring);
        close(fd);
        return false;
    }

    // I/O 성공 시, 결과를 버퍼에 저장
    output.assign(buffer, cqe->res);

    io_uring_cqe_seen(&ring, cqe);
    io_uring_queue_exit(&ring);
    close(fd);
    return true;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <device_path>" << std::endl;
        return 1;
    }

    std::string device_path = argv[1];

    FdpNvme fdp = FdpNvme(device_path);
    std::cout << "Pass" << std::endl;


    return 0;
}
