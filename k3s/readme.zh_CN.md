# k3s 服务相关配置

## 简介

选用k3s服务作为整个基础设施资源的管理和编排，该服务的特点
 - 精简版的k8s，占用更少的资源的同时覆盖k8s的几乎所有的特性
 - 有比较好的架构支持，包括amd64和arm64

基于以上对于目前的deepin系统研发资源规模以及后续的需求来说，基本可以完全覆盖，当然不包括riscv64架构，但本身的适配难度较少，剩下的是主要工作是riscv64的生态适配了，不过我们也可以通过这个点完善riscv64的生态。

## 现有资源规模

现有服务器资源列表：https://docs.qq.com/sheet/DRmxGdERhT3RBbFJI?tab=BB08J2

总的来说能确定的资源有deepin系统母公司提供的服务器从数量上看不算多，因此本文开头标题为`k3s 服务配置`，但是期待后续通过我们在努力发展deepin系统研发的基础设施成为一个`k3s 集群`，陪伴deepin开源操作系统一起壮大。


## 服务涉及技术

目前笔者能整理到的围绕[k3s](https://github.com/deepin-community/k3s)的相关技术点如下：

- [k3sup](https://github.com/alexellis/k3sup): 用于部署k3s服务的工具。
- [ansible](https://github.com/ansible/ansible): 批量服务部署工具，结合k3sup使用实现
- [k3s etcd](https://docs.rancher.cn/docs/k3s/installation/ha-embedded/_index)：k3s服务使用的内嵌配管理数据库，本身[etcd](https://github.com/etcd-io/etcd)也是作为k8s服务的默认数据库，不同在与k3s为了简化配置，将etcd内置到k3s服务中。
- [kuboard面板](https://github.com/eip-work/kuboard-press): 方便进行资源管理和服务编排的界面。
- 存储技术：待补充。
- 容器技术：[containerd](https://github.com/containerd/containerd)以及[docker](https://www.docker.com/)相关。
- 网络技术：有涉及到网关或代理相关，包括[nginx](https://blog.redis.com.cn/doc/)、[traefik-ingress](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)相关，有涉及到k3s服务网络后端[CNI](https://github.com/containernetworking/cni)的[flannel](https://github.com/flannel-io/flannel)、[wireguard](https://github.com/WireGuard/wireguard-go)等相关技术。
- [kubevirt](https://github.com/kubevirt/kubevirt): 兼容k8s pod管理的虚拟机管理工具，围绕这个会涉及到[libvirt](https://github.com/libvirt/libvirt)、[qemu](https://github.com/qemu/qemu)、kvm]等虚拟化相关技术点。
- [obs](https://openbuildservice.org/): 全称open build service，为opensuse开源的系统软件包构建工具，[deepin obs](https://build.deepin.com/)服务调研并采用了该工具。
- [ServerStatus服务](https://github.com/cppla/ServerStatus): 用于统计并展示服务资源占用情况。
- 未完待续。。。
