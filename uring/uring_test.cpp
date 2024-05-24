#include "uring_test.h"
#include "flexfs.h"

#define QDEPTH 16
#define USE_CHAR true
#define IS_READ true
#define TEST_PID 0

void tBenchmark(FdpNvme &fdp, NvmeData &nvme, Uring_cmd &uring_cmd,
                int test_cnt) {
  off_t offset = 0;
  char buffer[BS];
  int err;
  int i;

  err = posix_memalign((void **)&buffer, PAGE_SIZE, BS);
  DBG("Mem Align", err);

  std::chrono::system_clock::time_point start =
      std::chrono::system_clock::now();
  if (USE_CHAR) {
    for (i = 0; i < test_cnt; i++) {
      if (IS_READ) {
        // uring_cmd.prepUringCmdRead(fdp.fd(), nvme.nsId(), offset,
        //                            sizeof(buffer), &buffer);
        uring_cmd.uringCmdRead(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
                               &buffer);
      } else {
        uring_cmd.prepUringCmdWrite(fdp.fd(), nvme.nsId(), offset,
                                    sizeof(buffer), &buffer, TEST_PID);
      }
      offset += BS;
      if (i % QDEPTH == 0) {
        uring_cmd.submitCommand();
      }
    }
    //  uring_cmd.SubmitCmdRead(fdp.fd(), nvme.nsId(), offset, 8, &buffer);

  } else {
    for (i = 0; i < test_cnt; i++) {
      if (IS_READ) {
        uring_cmd.prepUringWrite(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
                                 &buffer);

      } else {
        uring_cmd.prepUringRead(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
                                &buffer);
      }
      offset += BS;
      if (i % QDEPTH == 0) {
        uring_cmd.submitCommand();
      }
    }
  }
  // err = uring_cmd.waitCompleted();

  std::chrono::duration<double> sec = std::chrono::system_clock::now() - start;
  if (err < 0) {
    LOG("Benchmark ERROR, err", err);
  } else {
    std::stringstream info;
    info << "QD-" << QDEPTH << ", ";
    info << "BS-" << BS << ", ";
    info << "CNT-" << test_cnt << ", ";
    info << "isPassthru-" << USE_CHAR << ", ";
    info << "isRead-" << IS_READ << ", ";
    LOG("Info", info.str());
    LOG("Final offset", offset);
    LOG("Times(sec)", sec.count());
    LOG("IOPS", i / sec.count());
    LOG("MB/s", (i * BS / 1024 / 1024) / sec.count());
    LOG("Benchmark done, err", err);
  }
}
// INFO : To verify, check the NVME ftrace and fdp status
void tWriteFDP(FdpNvme &fdp, NvmeData &nvme, Uring_cmd &uring_cmd) {
  off_t offset = 0;
  char buffer[BS];
  Superblock sb = Superblock(0);
  int err = 0;

  err = posix_memalign((void **)&buffer, PAGE_SIZE, BS);
  DBG("Mem Align", err);
  memcpy(buffer, &sb, sizeof(sb));

  for (int pid = 0; pid < 8; pid++) {
    err = uring_cmd.uringCmdWrite(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
                                  &buffer, pid);
  }

  if (err != 0) {
    LOG("WriteFDP ERROR, err", err);
  } else {
    LOG("WriteFDP done, err", err);
  }
}

// TODO : Fix it
void tWriteSB(FdpNvme &fdp, NvmeData &nvme, Uring_cmd &uring_cmd) {
  off_t offset = 0;
  char buffer[BS];
  Superblock sb = Superblock(0);
  int err;

  err = posix_memalign((void **)&buffer, PAGE_SIZE, BS);
  DBG("Mem Align", err);
  memcpy(buffer, &sb, sizeof(sb));

  if (USE_CHAR) {
    err = uring_cmd.uringCmdWrite(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
                                  &buffer, TEST_PID);
  } else {
    err = uring_cmd.uringWrite(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
                               &buffer);
  }

  if (err < 0) {
    LOG("WriteSB ERROR, err", err);
  } else {
    LOG("WriteSB done, err", err);
  }
}

void tWriteSingle(FdpNvme &fdp, NvmeData &nvme, Uring_cmd &uring_cmd) {
  off_t offset = 0;
  char buffer[BS];
  for (uint32_t i = 0; i < sizeof(buffer); i++) {
    buffer[i] = (i + 20) % 125;
  }
  int err;

  err = posix_memalign((void **)&buffer, PAGE_SIZE, BS);
  DBG("Mem Align", err);
  if (USE_CHAR) {
    err = uring_cmd.uringCmdWrite(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
                                  &buffer, TEST_PID);
  } else {
    err = uring_cmd.uringWrite(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
                               &buffer);
  }

  if (err < 0) {
    LOG("Write ERROR, err", err);
  } else {
    LOG("Write done, err", err);
  }
}

void tReadSingle(FdpNvme &fdp, NvmeData &nvme, Uring_cmd &uring_cmd) {
  off_t offset = 0;
  char buffer[BS];
  int err;

  err = posix_memalign((void **)&buffer, PAGE_SIZE, BS);
  DBG("Mem Align", err);
  memset(&buffer, 0, sizeof(buffer));

  if (USE_CHAR) {
    err = uring_cmd.uringCmdRead(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
                                 &buffer);
  } else {
    err = uring_cmd.uringRead(fdp.fd(), nvme.nsId(), offset, sizeof(buffer),
                              &buffer);
  }

  if (err == 0) {
    LOG("Read done", std::string((char *)buffer, sizeof(buffer)));
  } else if (err > 0) {
    LOG("Read done", std::string((char *)buffer, err));
  } else {
    LOG("Read ERROR", err);
  }
  LOG("Return", err);
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <device_path>" << std::endl;
    return 1;
  }

  std::string device_path = argv[1];
  std::cout << device_path << std::endl;

  FdpNvme fdp = FdpNvme{device_path, USE_CHAR};
  NvmeData nvme = fdp.getNvmeData();
  Uring_cmd uring_cmd =
      Uring_cmd{QDEPTH, nvme.blockSize(), nvme.lbaShift(), io_uring_params{}};

  // tWriteSingle(fdp, nvme, uring_cmd);
  // tReadSingle(fdp, nvme, uring_cmd);
  // tWriteSB(fdp, nvme, uring_cmd); // TODO FIX
  // tReadSingle(fdp, nvme, uring_cmd);
  // tWriteFDP(fdp, nvme, uring_cmd);
  tBenchmark(fdp, nvme, uring_cmd, 1000);
}
