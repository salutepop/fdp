#include "uring_test.h"
#include "flexfs.h"
#include <cstring>
#include <fcntl.h>
#include <iostream>
#include <unistd.h>

#define QDEPTH 4
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

  FdpNvme fdp = FdpNvme{device_path};
  NvmeData nvme = fdp.getNvmeData();
  Uring_cmd uring_cmd =
      Uring_cmd{qdepth, nvme.blockSize(), nvme.lbaShift(), io_uring_params{}};

  char buffer[4096];
  memset(&buffer, 0, sizeof(buffer));
  //  for (int i = 0; i < sizeof(buffer); i++) {
  //   buffer[i] = (i + 20) % 125;
  //}
  Superblock sb = Superblock(1);
  // memcpy(&buffer, &sb, sizeof(sb));
  //  std::chrono::system_clock::time_point start =
  //      std::chrono::system_clock::now();
  // uring_cmd.UringCmdWrite(fdp.fd(), nvme.nsId(), offset, sizeof(sb), &sb, 0);
  // std::chrono::duration<double> sec = std::chrono::system_clock::now() -
  // start; LOG("1M times(sec)", sec.count());
  //  uring_cmd.UringCmdRead(fdp.fd(), nvme.nsId(), offset, sizeof(Superblock),
  //  &sb);
  uring_cmd.UringRead(fdp.fd(), nvme.nsId(), offset, sizeof(buffer), &buffer);
  //  uring_cmd.UringCmdRead(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
  //                        &buffer);
}
