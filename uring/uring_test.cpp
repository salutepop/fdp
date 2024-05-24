#include "uring_test.h"
#include "flexfs.h"

#define QDEPTH 128
#define TEST_PID 1

const uint32_t tURING_CMD = 1U << 0;
const uint32_t tURING = 0U << 0;
const uint32_t tREAD = 1U << 1;
const uint32_t tWRITE = 0U << 1;

void tBenchmark(FdpNvme &fdp, NvmeData &nvme, Uring_cmd &uring_cmd,
                int test_cnt) {
  off_t offset = 0;
  uint32_t blocksize = 4 * 1024;
  char buffer[blocksize];
  int err;
  int cnt = 0;
  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<> dis(1, 100000000);

  err = posix_memalign((void **)&buffer, PAGE_SIZE, blocksize);
  DBG("Mem Align", err);

  for (uint32_t test_idx = 0; test_idx < 4; test_idx++) {
    std::chrono::system_clock::time_point start =
        std::chrono::system_clock::now();
    for (cnt = 0; cnt < test_cnt; cnt++) {
      switch (test_idx) {
      case tURING | tREAD:
        uring_cmd.prepUringRead(fdp.bfd(), nvme.nsId(), offset, sizeof(buffer),
                                &buffer);
        break;
      case tURING | tWRITE:
        uring_cmd.prepUringWrite(fdp.bfd(), nvme.nsId(), offset, sizeof(buffer),
                                 &buffer);
        break;
      case tURING_CMD | tREAD:
        uring_cmd.prepUringCmdRead(fdp.cfd(), nvme.nsId(), offset,
                                   sizeof(buffer), &buffer);
        break;
      case tURING_CMD | tWRITE:
        uring_cmd.prepUringCmdWrite(fdp.cfd(), nvme.nsId(), offset,
                                    sizeof(buffer), &buffer, TEST_PID);
        break;
      default:
        LOG("[ERR] test_idx", test_idx);
        break;
      }

      if (cnt > 0 && cnt % QDEPTH == QDEPTH - 1) {
        err = uring_cmd.submitCommand(QDEPTH);
        for (int reqs = 0; reqs < err; reqs++) {
          uring_cmd.waitCompleted();
        }
        DBG("overflow", uring_cmd.isCqOverflow());
        if (uring_cmd.isCqOverflow() != 0) {
          // uring_cmd.submitCommand();
          uring_cmd.waitCompleted();
        }
      }

      if (blocksize == 4096) {
        offset = dis(gen) * blocksize; // random offset
      } else {
        offset += blocksize; // sequential ofset
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
      info << "BS-" << BS / 1024 << "KB" << ", ";
      info << "CNT-" << test_cnt << ", ";
      info << ((test_idx & tURING_CMD) > 0 ? "URING_CMD" : "URING") << ", ";
      info << ((test_idx & tREAD) > 0 ? "READ" : "WRITE") << ", ";
      LOG("Info", info.str());
      LOG("Final offset", offset);
      LOG("Times(sec)", sec.count());
      LOG("IOPS", cnt / sec.count());
      LOG("MiB/s", (cnt * BS / 1024 / 1024) / sec.count());
      LOG("Benchmark done, err", err);
    }
  } /* end loop, test_idx */
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
void tWriteSB(FdpNvme &fdp, NvmeData &nvme, Uring_cmd &uring_cmd) {
  off_t offset = 0;
  char buffer[BS];
  Superblock sb = Superblock(0);
  int err;

  err = posix_memalign((void **)&buffer, PAGE_SIZE, BS);
  DBG("Mem Align", err);
  memcpy(buffer, &sb, sizeof(sb));

  for (uint32_t test_idx = 0; test_idx < 4; test_idx++) {
    switch (test_idx) {
    case tURING | tREAD:
      continue;
      break;
    case tURING | tWRITE:
      err = uring_cmd.uringWrite(fdp.bfd(), nvme.nsId(), offset, sizeof(buffer),
                                 &buffer);
      break;
    case tURING_CMD | tREAD:
      continue;
      break;
    case tURING_CMD | tWRITE:
      err = uring_cmd.uringCmdWrite(fdp.cfd(), nvme.nsId(), offset,
                                    sizeof(buffer), &buffer, TEST_PID);
      break;
    default:
      LOG("[ERR] test_idx", test_idx);
      break;
    }

    LOG(((test_idx & tURING_CMD) > 0 ? "URING_CMD" : "URING"),
        ((test_idx & tREAD) > 0 ? "READ" : "WRITE"));
    if (err < 0) {
      LOG("Write ERROR, err", err);
    } else {
      LOG("Write done, err", err);
    }
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

  for (uint32_t test_idx = 0; test_idx < 4; test_idx++) {
    switch (test_idx) {
    case tURING | tREAD:
      continue;
      break;
    case tURING | tWRITE:
      err = uring_cmd.uringWrite(fdp.bfd(), nvme.nsId(), offset, sizeof(buffer),
                                 &buffer);
      break;
    case tURING_CMD | tREAD:
      continue;
      break;
    case tURING_CMD | tWRITE:
      err = uring_cmd.uringCmdWrite(fdp.cfd(), nvme.nsId(), offset,
                                    sizeof(buffer), &buffer, TEST_PID);
      break;
    default:
      LOG("[ERR] test_idx", test_idx);
      break;
    }

    LOG(((test_idx & tURING_CMD) > 0 ? "URING_CMD" : "URING"),
        ((test_idx & tREAD) > 0 ? "READ" : "WRITE"));
    if (err < 0) {
      LOG("Write ERROR, err", err);
    } else {
      LOG("Write done, err", err);
    }
  }
}

void tReadSingle(FdpNvme &fdp, NvmeData &nvme, Uring_cmd &uring_cmd) {
  off_t offset = 0;
  char buffer[BS];
  int err;

  err = posix_memalign((void **)&buffer, PAGE_SIZE, BS);
  DBG("Mem Align", err);
  memset(&buffer, 0, sizeof(buffer));

  for (uint32_t test_idx = 0; test_idx < 4; test_idx++) {
    switch (test_idx) {
    case tURING | tREAD:
      err = uring_cmd.uringRead(fdp.bfd(), nvme.nsId(), offset, sizeof(buffer),
                                &buffer);
      break;
    case tURING | tWRITE:
      continue;
      break;
    case tURING_CMD | tREAD:
      err = uring_cmd.uringCmdRead(fdp.cfd(), nvme.nsId(), offset,
                                   sizeof(buffer), &buffer);
      break;
    case tURING_CMD | tWRITE:
      continue;
      break;
    default:
      LOG("[ERR] test_idx", test_idx);
      continue;
      break;
    }

    LOG(((test_idx & tURING_CMD) > 0 ? "URING_CMD" : "URING"),
        ((test_idx & tREAD) > 0 ? "READ" : "WRITE"));
    if (err == 0) {
      LOG("Read done", std::string((char *)buffer, sizeof(buffer)));
    } else if (err > 0) {
      LOG("Read done", std::string((char *)buffer, err));
    } else {
      LOG("Read ERROR", err);
    }
    LOG("Return", err);
  }
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <device_path>" << std::endl;
    return 1;
  }

  std::string device_path = argv[1];
  std::cout << device_path << std::endl;

  FdpNvme fdp = FdpNvme{device_path};
  NvmeData nvme = fdp.getNvmeData();
  Uring_cmd uring_cmd =
      Uring_cmd{QDEPTH, nvme.blockSize(), nvme.lbaShift(), io_uring_params{}};

  // tWriteSingle(fdp, nvme, uring_cmd);
  // tReadSingle(fdp, nvme, uring_cmd);
  // tWriteSB(fdp, nvme, uring_cmd); // TODO FIX
  // tReadSingle(fdp, nvme, uring_cmd);
  // tWriteFDP(fdp, nvme, uring_cmd);
  tBenchmark(fdp, nvme, uring_cmd, 3000000);
}
