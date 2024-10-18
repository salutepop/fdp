#include "io_test.h"

#define PAGE_SIZE 4096
// 0 : uring write
// 1 : uring_cmd write
// 2 : uring read
// 3 : uring_cmd read
enum {
  URING_READ = 0,
  URINGCMD_READ,
  URING_WRITE,
  URINGCMD_WRITE,
  PREAD,
  PWRITE,
  TEST_TYPE_MAX
};

const char *enumStrings[] = {"URING_READ",     "URINGCMD_READ", "URING_WRITE",
                             "URINGCMD_WRITE", "PREAD",         "PWRITE",
                             "TEST_TYPE_MAX"};

int fd_read, fd_write;

/* INFO: blocksize는 1MB크기 까지 평가 가능하고,
 * uringCmdWrite/Read 내부에서 256KB단위로 처리해줌 */
void tBenchmarkHelper(int tid, uint32_t test_idx, uint32_t blocksize,
                      uint64_t test_cnt) {
  off_t offset = 0;
  // uint32_t blocksize = 256 * 1024;
  uint64_t cnt = 0;
  // uint64_t maxTrfBytes = 4096 * 64;
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<> dis(1, 1000000000);

  // TODO:Write 성능 이상함
  void *buffer;
  if (posix_memalign(&buffer, PAGE_SIZE, blocksize)) {
    LOG("[FAIL]", "MemAlign");
  }

  uint64_t bytes = 0;
  for (cnt = 0; cnt < test_cnt; cnt++) {
    switch (test_idx) {
    case PREAD:
      uint32_t cnt_8k = blocksize / 8192;
      for (uint32_t i = 0; i < cnt_8k; i++) {
        offset = dis(gen) / 4096; // random offset
        // LOG("offset", offset);
        ssize_t bytesRead = pread(fd_read, buffer, 8192, offset);
        if (bytesRead == -1) {
          std::cerr << "Failed to read file: " << strerror(errno) << std::endl;
          close(fd_read);
          break;
        }
        bytes += bytesRead;
      }
      break;
    }

    // offset += blocksize; // sequential offset
    /*
    if (blocksize == BS) {
      offset = dis(gen) / BS; // random offset
    } else {
      offset += blocksize; // sequential offset
    }
    */

  } /* end loop, test_cnt */
  LOG("READ", bytes);
  free(buffer);
}

void tBenchmark(int threads, uint32_t test_idx, uint64_t blocksize,
                uint64_t testcnt) {
  std::vector<std::thread> threads_;
  std::chrono::system_clock::time_point start =
      std::chrono::system_clock::now();

  for (int i = 0; i < threads; i++) {
    threads_.push_back(
        std::thread(tBenchmarkHelper, i, test_idx, blocksize, testcnt));
  }
  for (auto &t : threads_) {
    t.join();
  }
  std::chrono::duration<double> sec = std::chrono::system_clock::now() - start;

  uint64_t totalcnt = testcnt * threads;
  std::stringstream info;
  info << "TEST_ITEM-" << enumStrings[test_idx] << ", ";
  info << "THREADS-" << threads << ", ";
  info << "BS-" << blocksize / 1024 << "KB" << ", ";
  info << "CNT-" << testcnt << "[Total:" << totalcnt << "], ";
  LOG("Info", info.str());
  LOG("Times(sec)", sec.count());
  LOG("IOPS", totalcnt / sec.count());
  LOG("MiB/s", ((totalcnt * (blocksize / 1024)) / 1024) / sec.count());
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <device_path>" << std::endl;
    return 1;
  }

  std::string device_path = argv[1];
  std::cout << device_path << std::endl;

  fd_read = open(device_path.c_str(), O_RDONLY | O_DIRECT);
  fd_write = open(device_path.c_str(), O_WRONLY);
  if ((fd_read == -1) || (fd_write == -1)) {
    std::cerr << "Failed to open file: " << strerror(errno) << std::endl;
    return 1;
  }

  uint32_t blocksize = 8192 * 32;
  uint32_t testcnt = 1000 * 1000;

  tBenchmark(1, PREAD, blocksize, testcnt);
  close(fd_read);
  close(fd_write);
}
