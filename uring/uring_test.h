#ifndef URING_TEST_H
#define URING_TEST_H

#include <string>
#include "fdpnvme.h"

bool read_file(const std::string &file_path, std::string &output);
bool read_character_device(const std::string &device_path, std::string &output);

#endif // URING_TEST_H

