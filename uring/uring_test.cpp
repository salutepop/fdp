#include "uring_test.h"
#include "flexfs.h"

#define QDEPTH 16
#define TEST_PID 2

// 0 : uring write
// 1 : uring_cmd write
// 2 : uring read
// 3 : uring_cmd read
enum {
  URING_READ = 0,
  URINGCMD_READ,
  URING_WRITE,
  URINGCMD_WRITE,
  TEST_TYPE_MAX
};

const uint32_t tURING_CMD = 1U << 0;
const uint32_t tURING = 0U << 0;
const uint32_t tREAD = 1U << 1;
const uint32_t tWRITE = 0U << 1;

void tBenchmark(FdpNvme &fdp, NvmeData &nvme, UringCmd &uring_cmd,
                int test_cnt) {
  off_t offset = 0;
  uint32_t blocksize = 256 * 1024;
  char buffer[blocksize];
  int err;
  int cnt = 0;
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<> dis(1, 100000000);

  // err = posix_memalign((void **)&buffer, PAGE_SIZE, blocksize);
  // DBG("Mem Align", err);

  // TODO:Write 성능 이상함
  for (uint32_t test_idx = URING_READ; test_idx < TEST_TYPE_MAX; test_idx++) {
    // for (uint32_t test_idx = URING_WRITE; test_idx < URING_WRITE + 1;
    //     test_idx++) {
    std::chrono::system_clock::time_point start =
        std::chrono::system_clock::now();
    void *buffer[QDEPTH];
    struct iovec *iovecs = (struct iovec *)calloc(QDEPTH, sizeof(struct iovec));
    for (int i = 0; i < QDEPTH; i++) {
      if (posix_memalign(&buffer[i], PAGE_SIZE, blocksize)) {
        LOG("[ERROR] MEM Align, idx", i);
      }
    }
    for (cnt = 0; cnt < test_cnt; cnt++) {
      for (int i = 0; i < QDEPTH; i++) {
        // memset(buffer[i], 0, blocksize);
        switch (test_idx) {
        case URING_READ:
          uring_cmd.prepUringRead(fdp.bfd(), offset, blocksize, buffer[i]);
          break;
        case URINGCMD_READ:
          uring_cmd.prepUringCmdRead(fdp.cfd(), nvme.nsId(), offset, blocksize,
                                     buffer[i]);
          break;
        case URING_WRITE:
          uring_cmd.prepUringWrite(fdp.bfd(), offset, blocksize, buffer[i]);
          break;
        case URINGCMD_WRITE:
          uring_cmd.prepUringCmdWrite(fdp.cfd(), nvme.nsId(), offset, blocksize,
                                      buffer[i], TEST_PID);
          break;
        default:
          LOG("[ERR] test_idx", test_idx);
          break;
        }
      }
      err = uring_cmd.submitCommand(QDEPTH);
      // LOG("REQS", err);
      for (int reqs = 0; reqs < err; reqs++) {
        uring_cmd.waitCompleted();
      }
      if (uring_cmd.isCqOverflow() != 0) {
        LOG("overflow", uring_cmd.isCqOverflow());
        // uring_cmd.submitCommand();
        uring_cmd.waitCompleted();
      }
      /*
      if (QDEPTH == 1) {
        uring_cmd.submitCommand();
        uring_cmd.waitCompleted();
        // } else if (cnt > 0 && cnt % QDEPTH == QDEPTH - 1) {
      } else if ((cnt + 1) % QDEPTH == 0) {
        err = uring_cmd.submitCommand(QDEPTH);
        //  LOG("submitCommand", err);
        for (int reqs = 0; reqs < err; reqs++) {
          uring_cmd.waitCompleted();
        }
        if (uring_cmd.isCqOverflow() != 0) {
          LOG("overflow", uring_cmd.isCqOverflow());
          // uring_cmd.submitCommand();
          uring_cmd.waitCompleted();
        }
        */

      if (blocksize == 4096) {
        offset = dis(gen) / 4; // random offset
      } else {
        offset += (blocksize / BS); // sequential ofset
      }

    } /* end loop, test_cnt */

    err = uring_cmd.submitCommand();
    for (int reqs = 0; reqs < err; reqs++) {
      err = uring_cmd.waitCompleted();
      if (err > 0)
        break;
    }
    std::chrono::duration<double> sec =
        std::chrono::system_clock::now() - start;
    if (err < 0) {
      LOG("Benchmark ERROR, err", err);
    } else {
      std::stringstream info;
      info << "QD-" << QDEPTH << ", ";
      info << "BS-" << blocksize / 1024 << "KB" << ", ";
      info << "CNT-" << test_cnt << ", ";
      if (test_idx == URING_READ) {
        info << "URING_READ" << ",";
      } else if (test_idx == URING_WRITE) {
        info << "URING_WRITE" << ",";
      } else if (test_idx == URINGCMD_READ) {
        info << "URINGCMD_READ" << ",";
      } else if (test_idx == URINGCMD_WRITE) {
        info << "URINGCMD_WRITE" << ",";
      }
      LOG("Info", info.str());
      LOG("Final offset", offset);
      LOG("Times(sec)", sec.count());
      LOG("IOPS", (test_cnt * QDEPTH) / sec.count());
      LOG("MiB/s",
          ((QDEPTH * test_cnt * (blocksize / 1024)) / 1024) / sec.count());
      LOG("Benchmark done, err", err);
    }
  } /* end loop, test_idx */
}

// INFO : To verify, check the NVME ftrace and fdp status
void tWriteFDP(FdpNvme &fdp, NvmeData &nvme, UringCmd &uring_cmd) {
  off_t offset = 0;
  char buffer[BS];
  Superblock sb = Superblock(0);
  int err = 0;

  err = posix_memalign((void **)&buffer, PAGE_SIZE, BS);
  DBG("Mem Align", err);
  memcpy(buffer, &sb, sizeof(sb));

  for (int pid = 0; pid < 8; pid++) {
    err = uring_cmd.uringCmdWrite(fdp.cfd(), nvme.nsId(), offset,
                                  sizeof(buffer), &buffer, pid);
  }

  if (err != 0) {
    LOG("WriteFDP ERROR, err", err);
  } else {
    LOG("WriteFDP done, err", err);
  }
}

// TODO : Fix it, Invalid data
void tWriteSB(FdpNvme &fdp, NvmeData &nvme, UringCmd &uring_cmd) {
  off_t offset = 0;
  Superblock sb = Superblock(0);
  int err;
  for (uint32_t test_idx = URING_READ; test_idx < TEST_TYPE_MAX; test_idx++) {
    if ((test_idx == URING_READ) || test_idx == URINGCMD_READ) {
      LOG("SKIP", test_idx);
      continue;
    }

    void *buffer;
    err = posix_memalign((void **)&buffer, PAGE_SIZE, sizeof(sb));
    memcpy(buffer, &sb, sizeof(sb));
    // LOG("Mem Align", err);
    switch (test_idx) {
    case URING_READ:
      break;
    case URINGCMD_READ:
      break;
    case URING_WRITE:
      err = uring_cmd.uringWrite(fdp.bfd(), offset, sizeof(sb), buffer);
      break;
    case URINGCMD_WRITE:
      err = uring_cmd.uringCmdWrite(fdp.cfd(), nvme.nsId(), offset, sizeof(sb),
                                    buffer, TEST_PID);
      break;
    default:
      LOG("[ERR] test_idx", test_idx);
      break;
    }

    if (test_idx == URING_READ) {
      LOG("TEST", "URING_READ");
    } else if (test_idx == URING_WRITE) {
      LOG("TEST", "URING_WRITE");
    } else if (test_idx == URINGCMD_READ) {
      LOG("TEST", "URINGCMD_READ");
    } else if (test_idx == URINGCMD_WRITE) {
      LOG("TEST", "URINGCMD_WRITE");
    }

    if (err < 0) {
      LOG("Write ERROR", err);
    } else {
      LOG("Write cmd done, written bytes", err);
    }
    free(buffer);
  }
}

void tWriteSingle(FdpNvme &fdp, NvmeData &nvme, UringCmd &uring_cmd) {
  off_t offset = 0;
  int err;
  uint32_t blocksize = 16;
  char data[blocksize];
  for (uint32_t i = 0; i < blocksize; i++) {
    // data[i] = (i + 20) % 125;
    data[i] = 68;
    // data[i] = 26;
  }

  for (uint32_t test_idx = URING_READ; test_idx < TEST_TYPE_MAX; test_idx++) {
    if ((test_idx == URING_READ) || test_idx == URINGCMD_READ) {
      LOG("SKIP", test_idx);
      continue;
    }

    void *buffer;
    err = posix_memalign((void **)&buffer, PAGE_SIZE, blocksize);
    memcpy(buffer, &data, blocksize);
    // LOG("Mem Align", err);
    switch (test_idx) {
    case URING_READ:
      break;
    case URINGCMD_READ:
      break;
    case URING_WRITE:
      err = uring_cmd.uringWrite(fdp.bfd(), offset, blocksize, buffer);
      break;
    case URINGCMD_WRITE:
      err = uring_cmd.uringCmdWrite(fdp.cfd(), nvme.nsId(), offset, blocksize,
                                    buffer, TEST_PID);
      break;
    default:
      LOG("[ERR] test_idx", test_idx);
      break;
    }

    if (test_idx == URING_READ) {
      LOG("TEST", "URING_READ");
    } else if (test_idx == URING_WRITE) {
      LOG("TEST", "URING_WRITE");
    } else if (test_idx == URINGCMD_READ) {
      LOG("TEST", "URINGCMD_READ");
    } else if (test_idx == URINGCMD_WRITE) {
      LOG("TEST", "URINGCMD_WRITE");
    }

    if (err < 0) {
      LOG("Write ERROR", err);
    } else {
      LOG("Write cmd done, written bytes", err);
    }
    free(buffer);
  }
}

void tReadSingle(FdpNvme &fdp, NvmeData &nvme, UringCmd &uring_cmd) {
  off_t offset = 0;
  uint32_t blocksize = 8;
  int err;

  for (uint32_t test_idx = URING_READ; test_idx < TEST_TYPE_MAX; test_idx++) {
    if ((test_idx == URING_WRITE) || test_idx == URINGCMD_WRITE) {
      LOG("SKIP", test_idx);
      continue;
    }

    void *buffer;
    err = posix_memalign((void **)&buffer, PAGE_SIZE, blocksize);
    // LOG("Mem Align", err);
    switch (test_idx) {
    case URING_READ:
      err = uring_cmd.uringRead(fdp.bfd(), offset, blocksize, buffer);
      break;
    case URINGCMD_READ:
      err = uring_cmd.uringCmdRead(fdp.cfd(), nvme.nsId(), offset, blocksize,
                                   buffer);
      break;
    case URING_WRITE:
      break;
    case URINGCMD_WRITE:
      break;
    default:
      LOG("[ERR] test_idx", test_idx);
      break;
    }

    if (test_idx == URING_READ) {
      LOG("TEST", "URING_READ");
    } else if (test_idx == URING_WRITE) {
      LOG("TEST", "URING_WRITE");
    } else if (test_idx == URINGCMD_READ) {
      LOG("TEST", "URINGCMD_READ");
    } else if (test_idx == URINGCMD_WRITE) {
      LOG("TEST", "URINGCMD_WRITE");
    }

    if (err == 0) {
      LOG("Read cmd done", std::string((char *)buffer, blocksize));
    } else if (err > 0) {
      LOG("Read done", std::string((char *)buffer, err));
    } else {
      LOG("Read ERROR", err);
    }
    LOG("Return", err);
    free(buffer);
  }
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <device_path>" << std::endl;
    return 1;
  }

  std::string device_path = argv[1];
  std::cout << device_path << std::endl;

  FdpNvme fdp = FdpNvme{device_path, true};
  // FdpNvme fdp = FdpNvme{device_path, false};
  NvmeData nvme = fdp.getNvmeData();
  UringCmd uring_cmd =
      UringCmd{QDEPTH, nvme.blockSize(), nvme.lbaShift(), io_uring_params{}};

  // tWriteSingle(fdp, nvme, uring_cmd);
  // tReadSingle(fdp, nvme, uring_cmd);
  tWriteSB(fdp, nvme, uring_cmd); // TODO FIX
  tReadSingle(fdp, nvme, uring_cmd);
  //   tWriteFDP(fdp, nvme, uring_cmd);
  //    tBenchmark(fdp, nvme, uring_cmd, 100);
}
