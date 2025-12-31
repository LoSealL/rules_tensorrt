#include <iostream>
#include "NvInfer.h"

int main() {
  std::cout << "TensorRT version: " << NV_TENSORRT_MAJOR << "." << NV_TENSORRT_MINOR << "." << NV_TENSORRT_PATCH << std::endl;
  return 0;
}
