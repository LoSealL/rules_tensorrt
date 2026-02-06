#include <iostream>
#include "NvInfer.h"

using nvinfer1::ILogger;

class Logger : public ILogger {
  void log(Severity severity, const char* msg) noexcept override {
    std::cout << msg << std::endl;
  }
};

int main() {
  std::cout << "TensorRT version: " << NV_TENSORRT_MAJOR << "." << NV_TENSORRT_MINOR << "." << NV_TENSORRT_PATCH << std::endl;
  Logger logger;
  auto* builder = nvinfer1::createInferBuilder(logger);
  auto* config = builder->createBuilderConfig();
  uint32_t flag = config->getFlags();
  int32_t cap = static_cast<int32_t>(config->getEngineCapability());
  std::cout << "Builder config flags: " << flag << std::endl;
  std::cout << "Builder config engine capability: " << cap << std::endl;
  delete config;
  delete builder;
  return 0;
}
