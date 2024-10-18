#include "uring_test.h"
#include "flexfs.h"

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

const char *enumStrings[] = {"URING_READ", "URINGCMD_READ", "URING_WRITE",
                             "URINGCMD_WRITE", "TEST_TYPE_MAX"};

const uint32_t tURING_CMD = 1U << 0;
const uint32_t tURING = 0U << 0;
const uint32_t tREAD = 1U << 1;
const uint32_t tWRITE = 0U << 1;

const uint32_t QDEPTH = 32;

static thread_local std::unique_ptr<UringCmd> uring_cmd;
static std::unique_ptr<FdpNvme> fdp;
static std::unique_ptr<NvmeData> nvme;

void tWriteThreadsRing(int tid) {
  off_t offset = 1000 * 4096;
  int err;
  uint32_t blocksize = 4096;

  if (uring_cmd == nullptr) {
    uring_cmd = std::make_unique<UringCmd>(32, nvme->blockSize(),
                                           nvme->lbaShift(), io_uring_params{});
  }
  /*
  char back_data[blocksize * 64];
  for (uint32_t i = 0; i < blocksize * 64; i++) {
    back_data[i] = 'X';
  }
  err = uring_cmd.uringCmdWrite(fdp.cfd(), nvme.nsId(), offset, blocksize * 64,
                                back_data, TEST_PID);
                                */

  // for (int i = 0; i < 1000; i++) {
  for (int i = 0; i < 32; i++) {
    // offset = ((random()) % 805300000) * 4096;
    offset = ((tid * 32) + i + 8000) * 4096;
    char data[blocksize];
    for (uint32_t j = 0; j < blocksize; j++) {
      data[i] = tid * i;
    }
    for (uint32_t test_idx = URING_READ; test_idx < TEST_TYPE_MAX; test_idx++) {
      if ((test_idx == URING_READ) || (test_idx == URINGCMD_WRITE) ||
          (test_idx == URING_WRITE)) {
        // LOG("SKIP", test_idx);
        continue;
      }

      if (test_idx == URING_READ) {
        DBG("URING_READ", i);
      } else if (test_idx == URING_WRITE) {
        DBG("URING_WRITE", i);
      } else if (test_idx == URINGCMD_READ) {
        DBG("URINGCMD_READ", i);
      } else if (test_idx == URINGCMD_WRITE) {
        DBG("URINGCMD_WRITE", i);
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
        err = uring_cmd->uringWrite(fdp->bfd(), offset, blocksize, buffer);
        break;
      case URINGCMD_WRITE:
        err = uring_cmd->uringCmdWrite(fdp->cfd(), nvme->nsId(), offset,
                                       blocksize, buffer, TEST_PID);
        //  err = uring_cmd.uringCmdRead(fdp.cfd(), nvme.nsId(), offset,
        //  blocksize,
        //                               buffer);
        //  err = uring_cmd.uringCmdRead(fdp.cfd(), nvme.nsId(), offset,
        //  blocksize,
        //                               buffer);
        // uring_cmd.uringFsync(fdp.cfd(), nvme.nsId());
        break;
      default:
        LOG("[ERR] test_idx", test_idx);
        break;
      }

      if (err < 0) {
        LOG("Write ERROR", err);
      } else {
        // LOG("Write cmd done, written bytes", err);
      }
      free(buffer);
    }
  }
}
void tWriteThread(int tid) {
  off_t offset = 1000 * 4096;
  int err;
  uint32_t blocksize = 4096;

  if (uring_cmd == nullptr) {
    uring_cmd = std::make_unique<UringCmd>(32, nvme->blockSize(),
                                           nvme->lbaShift(), io_uring_params{});
  }
  /*
  char back_data[blocksize * 64];
  for (uint32_t i = 0; i < blocksize * 64; i++) {
    back_data[i] = 'X';
  }
  err = uring_cmd.uringCmdWrite(fdp.cfd(), nvme.nsId(), offset, blocksize * 64,
                                back_data, TEST_PID);
                                */

  // for (int i = 0; i < 1000; i++) {
  for (int i = 0; i < 16; i++) {
    // offset = ((random()) % 805300000) * 4096;
    offset = ((tid * 32) + i + 4000) * 4096;
    char data[blocksize];
    for (uint32_t j = 0; j < blocksize; j++) {
      data[i] = tid * i;
    }
    for (uint32_t test_idx = URING_READ; test_idx < TEST_TYPE_MAX; test_idx++) {
      if ((test_idx == URING_READ) || (test_idx == URINGCMD_READ) ||
          (test_idx == URING_WRITE)) {
        // LOG("SKIP", test_idx);
        continue;
      }

      if (test_idx == URING_READ) {
        LOG("URING_READ", i);
      } else if (test_idx == URING_WRITE) {
        LOG("URING_WRITE", i);
      } else if (test_idx == URINGCMD_READ) {
        LOG("URINGCMD_READ", i);
      } else if (test_idx == URINGCMD_WRITE) {
        DBG("URINGCMD_WRITE", i);
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
        err = uring_cmd->uringWrite(fdp->bfd(), offset, blocksize, buffer);
        break;
      case URINGCMD_WRITE:
        err = uring_cmd->uringCmdWrite(fdp->cfd(), nvme->nsId(), offset,
                                       blocksize, buffer, TEST_PID);
        //  err = uring_cmd.uringCmdRead(fdp.cfd(), nvme.nsId(), offset,
        //  blocksize,
        //                               buffer);
        //  err = uring_cmd.uringCmdRead(fdp.cfd(), nvme.nsId(), offset,
        //  blocksize,
        //                               buffer);
        // uring_cmd.uringFsync(fdp.cfd(), nvme.nsId());
        break;
      default:
        LOG("[ERR] test_idx", test_idx);
        break;
      }

      if (err < 0) {
        DBG("Write ERROR", err);
      } else {
        // LOG("Write cmd done, written bytes", err);
      }
      free(buffer);
    }
  }
}

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
  std::uniform_int_distribution<> dis(1, 100000000);

  if (uring_cmd == nullptr) {
    uring_cmd = std::make_unique<UringCmd>(32, nvme->blockSize(),
                                           nvme->lbaShift(), io_uring_params{});
  }

  // TODO:Write 성능 이상함
  void *buffer;
  if (posix_memalign(&buffer, PAGE_SIZE, blocksize)) {
    LOG("[FAIL]", "MemAlign");
  }

  for (cnt = 0; cnt < test_cnt; cnt++) {
    switch (test_idx) {
    case URING_READ:
      uring_cmd->uringRead(fdp->bfd(), offset, blocksize, buffer);
      break;
    case URINGCMD_READ:
      uring_cmd->uringCmdRead(fdp->cfd(), nvme->nsId(), offset, blocksize,
                              buffer);
      break;
    case URING_WRITE:
      uring_cmd->uringWrite(fdp->bfd(), offset, blocksize, buffer);
      break;
    case URINGCMD_WRITE:
      uring_cmd->uringCmdWrite(fdp->cfd(), nvme->nsId(), offset, blocksize,
                               buffer, TEST_PID);
      break;
    default:
      break;
    }

    offset += blocksize; // sequential offset
    /*
    if (blocksize == BS) {
      offset = dis(gen) / BS; // random offset
    } else {
      offset += blocksize; // sequential offset
    }
    */

  } /* end loop, test_cnt */
}

// INFO : To verify, check the NVME ftrace and fdp status
void tWriteFDP(int tid) {
  off_t offset = 0;
  char buffer[BS];
  Superblock sb = Superblock(0);
  int err = 0;
  if (uring_cmd == nullptr) {
    uring_cmd = std::make_unique<UringCmd>(32, nvme->blockSize(),
                                           nvme->lbaShift(), io_uring_params{});
  }

  err = posix_memalign((void **)&buffer, PAGE_SIZE, BS);
  DBG("Mem Align", err);
  memcpy(buffer, &sb, sizeof(sb));

  for (int pid = 0; pid < 8; pid++) {
    err = uring_cmd->uringCmdWrite(fdp->cfd(), nvme->nsId(), offset,
                                   sizeof(buffer), &buffer, pid);
  }

  if (err != 0) {
    LOG("WriteFDP ERROR, err", err);
  } else {
    LOG("WriteFDP done, err", err);
  }
}

// TODO : Fix it, Invalid data
void tWriteSB(int tid) {
  off_t offset = 0;
  Superblock sb = Superblock(0);
  int err;
  if (uring_cmd == nullptr) {
    uring_cmd = std::make_unique<UringCmd>(32, nvme->blockSize(),
                                           nvme->lbaShift(), io_uring_params{});
  }
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
      err = uring_cmd->uringWrite(fdp->bfd(), offset, sizeof(sb), buffer);
      break;
    case URINGCMD_WRITE:
      err = uring_cmd->uringCmdWrite(fdp->cfd(), nvme->nsId(), offset,
                                     sizeof(sb), buffer, TEST_PID);
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

void tWriteSingle(int tid) {
  off_t offset = 0;
  offset = 91562704896;
  int err;
  uint32_t blocksize = 4096 * 256;
  char data[blocksize];
  if (uring_cmd == nullptr) {
    uring_cmd = std::make_unique<UringCmd>(32, nvme->blockSize(),
                                           nvme->lbaShift(), io_uring_params{});
  }
  for (uint32_t i = 0; i < blocksize; i++) {
    data[i] = random() % 127;
    // data[i] = 68;
    //  data[i] = 26;
  }

  // for (int i = 0; i < 1000; i++) {
  for (int i = 0; i < 4; i++) {
    // offset = ((random()) % 805300000) * 4096;
    offset = ((random()) % 1000) * 4096;
    blocksize = ((random()) % 64) * 4096;

    offset = i * 4096;
    blocksize = i * 4096;
    for (uint32_t test_idx = URING_READ; test_idx < TEST_TYPE_MAX; test_idx++) {
      if ((test_idx == URING_READ) || (test_idx == URINGCMD_READ) ||
          (test_idx == URING_WRITE)) {
        // LOG("SKIP", test_idx);
        continue;
      }

      if (test_idx == URING_READ) {
        LOG("URING_READ", i);
      } else if (test_idx == URING_WRITE) {
        LOG("URING_WRITE", i);
      } else if (test_idx == URINGCMD_READ) {
        LOG("URINGCMD_READ", i);
      } else if (test_idx == URINGCMD_WRITE) {
        LOG("URINGCMD_WRITE", i);
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
        err = uring_cmd->uringWrite(fdp->bfd(), offset, blocksize, buffer);
        break;
      case URINGCMD_WRITE:
        err = uring_cmd->uringCmdWrite(fdp->cfd(), nvme->nsId(), offset,
                                       blocksize, buffer, TEST_PID);
        err = uring_cmd->uringCmdRead(fdp->cfd(), nvme->nsId(), offset,
                                      blocksize, buffer);
        err = uring_cmd->uringCmdRead(fdp->cfd(), nvme->nsId(), offset,
                                      blocksize, buffer);
        // uring_cmd->uringFsync(fdp->cfd(), nvme->nsId());
        break;
      default:
        LOG("[ERR] test_idx", test_idx);
        break;
      }

      if (err < 0) {
        LOG("Write ERROR", err);
      } else {
        // LOG("Write cmd done, written bytes", err);
      }
      free(buffer);
    }
  }
}

void tReadSingle(int tid) {
  off_t offset = 0;
  uint32_t blocksize = 512;
  int err;

  if (uring_cmd == nullptr) {
    uring_cmd = std::make_unique<UringCmd>(32, nvme->blockSize(),
                                           nvme->lbaShift(), io_uring_params{});
  }
  for (uint32_t test_idx = URING_READ; test_idx < TEST_TYPE_MAX; test_idx++) {
    if ((test_idx == URING_WRITE) || (test_idx == URINGCMD_WRITE)) {
      LOG("SKIP", test_idx);
      continue;
    }

    void *buffer;
    err = posix_memalign((void **)&buffer, PAGE_SIZE, blocksize);
    // LOG("Mem Align", err);
    switch (test_idx) {
    case URING_READ:
      err = uring_cmd->uringRead(fdp->bfd(), offset, blocksize, buffer);
      break;
    case URINGCMD_READ:
      err = uring_cmd->uringCmdRead(fdp->cfd(), nvme->nsId(), offset, blocksize,
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

void tUringCmdDataAligned(int tid) {

  int err;
  size_t size = 0;
  off_t offset = 0;
  void *buffer;

  if (uring_cmd == nullptr) {
    uring_cmd = std::make_unique<UringCmd>(32, nvme->blockSize(),
                                           nvme->lbaShift(), io_uring_params{});
  }
  /*
  // INFO: mis-aligned offset & small size
  LOG("[TEST 1]", "mis-aligned offset & small-size");
  offset = 8;
  size = 16;
  if (posix_memalign((void **)&buffer, PAGE_SIZE, size)) {
    LOG("ERR", "mem aligned fail");
  }
  err = uring_cmd.uringCmdRead(fdp.cfd(), nvme.nsId(), offset, size, buffer);
  if (err > 0) {
    LOG("Read cmd done, read bytes", err);
    LOG("Read data", std::string((char *)buffer, err));
  } else {
    LOG("Read ERROR", err);
  }
  LOG("[EXPECTED]", size);
  LOG("[RESULT]", err);

  memset(buffer, 0, size);
  err =
      uring_cmd.uringCmdWrite(fdp.cfd(), nvme.nsId(), offset, size, buffer, 0);
  if (err > 0) {
    LOG("Write cmd done, write bytes", err);
  } else {
    LOG("Write ERROR", err);
  }
  LOG("[EXPECTED]", -EINVAL);
  LOG("[RESULT]", err);
  free(buffer);

  // INFO: mis-aligned offset & over-size
  LOG("[TEST 2]", "mis-aligned offset & over-size");
  offset = 8;
  size = 5000;
  if (posix_memalign((void **)&buffer, PAGE_SIZE, size)) {
    LOG("ERR", "mem aligned fail");
  }
  err = uring_cmd.uringCmdRead(fdp.cfd(), nvme.nsId(), offset, size, buffer);
  if (err > 0) {
    LOG("Read cmd done, read bytes", err);
    LOG("Read data", std::string((char *)buffer, err));
  } else {
    LOG("Read ERROR", err);
  }
  LOG("[EXPECTED]", size);
  LOG("[RESULT]", err);

  memset(buffer, 0, size);
  err =
      uring_cmd.uringCmdWrite(fdp.cfd(), nvme.nsId(), offset, size, buffer, 0);
  if (err > 0) {
    LOG("Write cmd done, write bytes", err);
  } else {
    LOG("Write ERROR", err);
  }
  LOG("[EXPECTED]", -EINVAL);
  LOG("[RESULT]", err);
  free(buffer);

  // INFO: exceed max transfer size (64)
  LOG("[TEST 3]", "exceed max transfer size");
  offset = 8;
  size = 100 * 4096;
  if (posix_memalign((void **)&buffer, PAGE_SIZE, size)) {
    LOG("ERR", "mem aligned fail");
  }
  err = uring_cmd.uringCmdRead(fdp.cfd(), nvme.nsId(), offset, size, buffer);
  if (err > 0) {
    LOG("Read cmd done, read bytes", err);
    LOG("Read data", std::string((char *)buffer, err));
  } else {
    LOG("Read ERROR", err);
  }
  LOG("[EXPECTED]", -EINVAL);
  LOG("[RESULT]", err);

  memset(buffer, 0, size);
  err =
      uring_cmd.uringCmdWrite(fdp.cfd(), nvme.nsId(), offset, size, buffer, 0);
  if (err > 0) {
    LOG("Write cmd done, write bytes", err);
  } else {
    LOG("Write ERROR", err);
  }
  LOG("[EXPECTED]", -EINVAL);
  LOG("[RESULT]", err);
  free(buffer);
  */

  // INFO: large transfer size (4KB * 50)
  LOG("[TEST 4]", "large transfer size");
  offset = 8;
  size = 50 * 4096;
  if (posix_memalign((void **)&buffer, PAGE_SIZE, size)) {
    LOG("ERR", "mem aligned fail");
  }
  err = uring_cmd->uringCmdRead(fdp->cfd(), nvme->nsId(), offset, size, buffer);
  if (err > 0) {
    LOG("Read cmd done, read bytes", err);
    LOG("Read data", std::string((char *)buffer, err));
  } else {
    LOG("Read ERROR", err);
  }
  LOG("[EXPECTED]", size);
  LOG("[RESULT]", err);

  memset(buffer, '4', size);
  err = uring_cmd->uringCmdWrite(fdp->cfd(), nvme->nsId(), offset, size, buffer,
                                 0);
  if (err > 0) {
    LOG("Write cmd done, write bytes", err);
  } else {
    LOG("Write ERROR", err);
  }
  LOG("[EXPECTED]", size);
  LOG("[RESULT]", err);
  free(buffer);
}

void tMisAlignedWrite(int tid) {

  int err;
  size_t size = 4;
  off_t offset = 8;
  char data[size];
  if (uring_cmd == nullptr) {
    uring_cmd = std::make_unique<UringCmd>(32, nvme->blockSize(),
                                           nvme->lbaShift(), io_uring_params{});
  }

  for (uint32_t i = 0; i < size; i++) {
    // data[i] = (i + 20) % 125;
    data[i] = 68;
    //  data[i] = 26;
  }

  void *buffer;

  LOG("[WRITE]", "BACK-PATTERN, fill 'A'");
  if (posix_memalign((void **)&buffer, PAGE_SIZE, 32)) {
    LOG("ERR", "mem aligned fail");
  }
  memset(buffer, 'A', 32);
  err = uring_cmd->uringCmdWrite(fdp->cfd(), nvme->nsId(), 0, 32, buffer, 0);
  if (err > 0) {
    LOG("Write cmd done, write bytes", err);
  } else {
    LOG("Write ERROR", err);
  }
  LOG("[READ]", "BEFORE");
  err = uring_cmd->uringCmdRead(fdp->cfd(), nvme->nsId(), 0, 32, buffer);
  if (err > 0) {
    LOG("Read cmd done, read bytes", err);
    LOG("Read data", std::string((char *)buffer, err));
  } else {
    LOG("Read ERROR", err);
  }
  free(buffer);

  LOG("[WRITE]", "fill D");
  if (posix_memalign((void **)&buffer, PAGE_SIZE, size)) {
    LOG("ERR", "mem aligned fail");
  }
  err =
      uring_cmd->uringCmdWrite(fdp->cfd(), nvme->nsId(), offset, size, data, 0);
  if (err > 0) {
    LOG("Write cmd done, write bytes", err);
  } else {
    LOG("Write ERROR", err);
  }
  free(buffer);

  LOG("[READ]", "AFTER");
  if (posix_memalign((void **)&buffer, PAGE_SIZE, 32)) {
    LOG("ERR", "mem aligned fail");
  }
  err = uring_cmd->uringCmdRead(fdp->cfd(), nvme->nsId(), 0, 32, buffer);
  if (err > 0) {
    LOG("Read cmd done, read bytes", err);
    LOG("Read data", std::string((char *)buffer, err));
  } else {
    LOG("Read ERROR", err);
  }
  free(buffer);
}

void tMisAlignedRead(int tid) {

  int err;
  size_t size = 4096 * 64 * 4; // 4096 * 64 blocks * 4 = 256KB
  off_t offset;
  void *buffer;
  char data[size];

  if (uring_cmd == nullptr) {
    uring_cmd = std::make_unique<UringCmd>(32, nvme->blockSize(),
                                           nvme->lbaShift(), io_uring_params{});
  }
  for (uint32_t i = 0; i < size; i++) {
    // data[i] = (i + 20) % 125;
    data[i] = 'A';
    //  data[i] = 26;
  }

  LOG("[WRITE]", "BACK-PATTERN, 256KB, fill 'A'");
  err = uring_cmd->uringCmdWrite(fdp->cfd(), nvme->nsId(), 0, size, data, 0);
  if (err > 0) {
    LOG("Write cmd done, write bytes", err);
  } else {
    LOG("Write ERROR", err);
  }

  LOG("[READ]", "misAlign 32 Byte, read 2 blocks");
  if (posix_memalign((void **)&buffer, PAGE_SIZE, size)) {
    LOG("ERR", "mem aligned fail");
  }
  offset = 32;
  err = uring_cmd->uringCmdRead(fdp->cfd(), nvme->nsId(), offset, 4096 * 2,
                                buffer);
  LOG("[EXPECTED]", 4096 * 2);
  LOG("[RESULT]", err);
  free(buffer);

  LOG("[READ]", "Read 1000 blocks");
  if (posix_memalign((void **)&buffer, PAGE_SIZE, size)) {
    LOG("ERR", "mem aligned fail");
  }
  offset = 32;
  err = uring_cmd->uringCmdRead(fdp->cfd(), nvme->nsId(), offset, 4096 * 1000,
                                buffer);
  free(buffer);
  LOG("[EXPECTED]", -EINVAL);
  LOG("[RESULT]", err);
}

void tMultiThreads(int threads, void (*func_)(int)) {
  std::vector<std::thread> threads_;
  for (int i = 0; i < threads; i++) {
    // threads_->push_back(std::thread(tWriteThread, i, std::ref(fdp),
    //                                std::ref(nvme), std::ref(uring_cmd)));
    //  thread_local UringCmd uring_cmd_ =
    //      UringCmd{32, nvme->blockSize(), nvme->lbaShift(),
    //      io_uring_params{}};
    threads_.push_back(std::thread(func_, i));
    // threads_.push_back(std::thread(tWriteThread, i, std::ref(fdp),
    //                                std::ref(nvme), std::ref(uring_cmd)));
  }
  for (auto &t : threads_) {
    t.join();
  }
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

int ringTest() {
  struct io_uring ring;
  // struct io_uring_params params;
  // memset(&params, 0, sizeof(params));

  std::cout << "HLEtttt" << std::endl;
  // io_uring 초기화
  int ret = io_uring_queue_init(16, &ring, 0);
  LOG("INIT", ret);
  // if (io_uring_queue_init_params(1, &ring, &params) < 0) {
  //   perror("io_uring_queue_init_params");
  //   return 1;
  // }

  // 쓰기 작업 준비
  struct io_uring_sqe *sqe = io_uring_get_sqe(&ring);
  if (!sqe) {
    fprintf(stderr, "Could not get SQE.\n");
    io_uring_queue_exit(&ring);
    return 1;
  }

  /*
  char buffer[BLOCK_SIZE];
  strcpy(buffer, "Hello, io_uring!");

  // SQE 설정
  io_uring_prep_write(sqe, fd, buffer, strlen(buffer), 0);

  // SQE 제출
  if (io_uring_submit(&ring) < 0) {
    perror("io_uring_submit");
    close(fd);
    io_uring_queue_exit(&ring);
    return 1;
  }

  // 완료 대기
  struct io_uring_cqe *cqe;
  if (io_uring_wait_cqe(&ring, &cqe) < 0) {
    perror("io_uring_wait_cqe");
    close(fd);
    io_uring_queue_exit(&ring);
    return 1;
  }

  // 결과 확인
  if (cqe->res < 0) {
    fprintf(stderr, "Async write failed.\n");
  } else {
    printf("Async write succeeded.\n");
  }

  // CQE 완료 처리
  io_uring_cqe_seen(&ring, cqe);

  // 리소스 정리
  close(fd);
  */
  io_uring_queue_exit(&ring);

  return 0;
}

int main(int argc, char *argv[]) {
  if (argc != 2) {
    std::cerr << "Usage: " << argv[0] << " <device_path>" << std::endl;
    return 1;
  }

  std::string device_path = argv[1];
  std::cout << device_path << std::endl;

  //  int ret = ringTest();
  //  LOG("RET", ret);
  // FdpNvme fdp = FdpNvme{device_path, false};
  fdp = std::make_unique<FdpNvme>(device_path, true);
  nvme = std::make_unique<NvmeData>(fdp->getNvmeData());

  if (uring_cmd == nullptr) {
    uring_cmd = std::make_unique<UringCmd>(32, nvme->blockSize(),
                                           nvme->lbaShift(), io_uring_params{});
  }
  // uint64_t _len = 0x1000 * 64;
  uint64_t _offset = 0x0;
  uint64_t _len = 13079937024;
  uring_cmd->uringDiscard(fdp->bfd(), _offset, _len);
  uring_cmd->uringDiscard(fdp->bfd(), _len, _len);
  /* INFO: pread, pwrite
  fd_read = open(device_path.c_str(), O_RDONLY | O_DIRECT);
  fd_write = open(device_path.c_str(), O_WRONLY);
  if ((fd_read == -1) || (fd_write == -1)) {
    std::cerr << "Failed to open file: " << strerror(errno) << std::endl;
    return 1;
  }
  */

  // UringCmd uring_cmd =
  //  static thread_local UringCmd uring_cmd =
  //      UringCmd{QDEPTH, nvme.blockSize(), nvme.lbaShift(),
  //      io_uring_params{}};

  // tMultiThreads(8, tWriteThreadsRing);
  //  tMultiThreads(8, tWriteThreadsRing);
  /*
  uint64_t blocksize = 4096 * 1024;
  uint64_t testcnt = 1000;
  tBenchmark(4, URINGCMD_READ, blocksize, testcnt);
  tBenchmark(4, URINGCMD_WRITE, blocksize, testcnt);
  */

  // tWriteSingle(fdp, nvme, uring_cmd);
  //      tReadSingle(fdp, nvme, uring_cmd);
  //      tWriteSB(fdp, nvme, uring_cmd); // TODO FIX
  //      tReadSingle(fdp, nvme, uring_cmd);
  //        tWriteFDP(fdp, nvme, uring_cmd);
  // tBenchmark(fdp, nvme, 1, 100000, 4096 * 64);
  //    tUringCmdDataAligned(fdp, nvme, uring_cmd);
  //    tUringCmdDataAligned(fdp, nvme, uring_cmd);
  //   tMisAlignedWrite(fdp, nvme, uring_cmd);
  //   tMisAlignedRead(fdp, nvme, uring_cmd);
  return 0;
}
