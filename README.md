<p align="center">
   中文 | <a href="README.zh_CN.md">English<a/>
</p>

# infra-settings
deepin ci/cd 基础设施配置

# 简介

使用[k3s](https://github.com/deepin-community/k3s)管理目前deepin ci/cd所用到的物理资源，并在此基础上逐步搭建、维护和开发我们的ci/cd应用以及流程；该项目则用于管理和公示这些基础设置的配置，包括物理资源以及ci/cd相关服务的配置信息等。

# 规划

1. [k3s](https://github.com/deepin-community/k3s)资源整理、部署、配置和公示；
2. [deepin obs](https://build.deepin.com/)构建服务逐步迁移至k3s服务内，并配置公开；
3. deepin开发集成流程讨论、实施并公开配置；
4. 接入[deepinid服务]进行用户管理，讨论参与sig的角色、职责、权限的划分，实施并公开配置；
5. 捐赠带宽、存储、机器接入方案讨论、实施并公开配置；
6. cicd的维护文档服务方案讨论、实施并公开配置；
7. 基础设施服务的riscv64架构适配方案讨论、实施并公开相关配置。

# 相关的deepin系统开发sig

- [deepin-cicd sig](https://github.com/deepin-community/SIG/blob/master/sig/deepin-cicd/README.md)
- [deepin-sysdev-team sig](https://github.com/deepin-community/SIG/blob/master/sig/deepin-sysdev-team/README.md)
- [deepin-riscv64 sig](https://github.com/deepin-community/SIG/blob/master/sig/deepin-riscv64/README.md)
- [deepin-virt sig](https://github.com/deepin-community/SIG/blob/master/sig/deepin-virt/README.md)
