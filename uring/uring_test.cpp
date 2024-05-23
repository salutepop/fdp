#include "uring_test.h"
#include "flexfs.h"

#define QDEPTH 1
#define BS 4096
#define PAGE_SIZE 4096

int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <device_path>" << std::endl;
    return 1;
  }

  std::string device_path = argv[1];
  std::cout << device_path << std::endl;

  uint32_t qdepth = QDEPTH;
  off_t offset = 0;
  bool useChar = true;

  FdpNvme fdp = FdpNvme{device_path, useChar};
  NvmeData nvme = fdp.getNvmeData();
  Uring_cmd uring_cmd =
      Uring_cmd{qdepth, nvme.blockSize(), nvme.lbaShift(), io_uring_params{}};

  char buffer[BS];
  LOG("BUFFER ADD 1", &buffer);
  // void *buffer;
  int err = posix_memalign((void **)&buffer, PAGE_SIZE, BS);
  LOG("BUFFER ADD 2", &buffer);
  // LOG("memAlign", err);
  memset(&buffer, 0, sizeof(buffer));
  LOG("BUFFER ADD 3", &buffer);
  LOG("BUFFER SIZE", sizeof(buffer));
  // for (int i = 0; i < sizeof(buffer); i++) {
  //  buffer[i] = (i + 20) % 125;
  // }
  Superblock sb = Superblock(1);
  if (useChar) {
    // uring_cmd.UringCmdWrite(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
    //                         &buffer, 0);
    uring_cmd.UringCmdRead(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
                           &buffer);
    // uring_cmd.UringCmdRead(fdp.fd(), nvme.nsId(), offset, 8, &buffer);

  } else {
    // uring_cmd.UringWrite(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
    //                      &buffer);
    uring_cmd.UringRead(fdp.fd(), nvme.nsId(), offset, sizeof(buffer), &buffer);
  }
  // memcpy(&buffer, &sb, sizeof(sb));
  //  std::chrono::system_clock::time_point start =
  //      std::chrono::system_clock::now();
  // uring_cmd.UringCmdWrite(fdp.fd(), nvme.nsId(), offset, sizeof(sb), &sb, 0);
  // std::chrono::duration<double> sec = std::chrono::system_clock::now() -
  // start; LOG("1M times(sec)", sec.count());
  //  uring_cmd.UringCmdRead(fdp.fd(), nvme.nsId(), offset, sizeof(Superblock),
  //  &sb);
  //  uring_cmd.UringCmdRead(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
  //                        &buffer);
}
