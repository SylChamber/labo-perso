# Support des GPUs NVIDIA dans k3s

Le support des GPUs NVIDIA permet de déployer des applications nécessitant des GPUs NVIDIA, comme les applications d'IA comme Ollama et Open-WebUI.

## Installation du support des GPUs NVIDIA en conteneur

Installer `nvidia-container-toolkit` en suivant les instructions officielles de NVIDIA, soit d'avoir configuré un dépôt apt et d'avoir installé le paquet `nvidia-container-toolkit`.

> Les [dotfiles](https://github.com/SylChamber/dotfiles) incluent `docker`, `containerd` et `nvidia-container-toolkit`.

Tester que le GPU NVIDIA est détecté par le système:

```shell
> lshw -numeric -C display
ATTENTION : ce programme devrait être lancé en tant que super-utilisateur.
  *-display
       description: VGA compatible controller
       produit: GA106 [GeForce RTX 3060 Lite Hash Rate] [10DE:2504]
       fabricant: NVIDIA Corporation [10DE]
       identifiant matériel: 0
       information bus: pci@0000:07:00.0
       nom logique: /dev/fb0
       version: a1
       bits: 64 bits
       horloge: 33MHz
       fonctionnalités: vga_controller bus_master cap_list rom fb
       configuration : depth=32 driver=nvidia latency=0 resolution=1920,1080
       ressources : irq:81 mémoire:fb000000-fbffffff mémoire:d0000000-dfffffff mémoire:e0000000-e1ffffff portE/S:f000(taille=128) mémoire:c0000-dffff
```

Vérifier ensuite avec l'outil de NVIDIA:

```shell
> nvidia-smi
Sun Mar  2 10:25:01 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 565.77                 Driver Version: 565.77         CUDA Version: 12.7     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 3060        Off |   00000000:07:00.0  On |                  N/A |
|  0%   53C    P8             18W /  170W |     652MiB /  12288MiB |     10%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
```

Ensuite vérifier que le GPU est détecté en conteneur par `containerd` avec la CLI `ctr`:

> `containerd` doit avoir été préalablement installé, ce qui est le cas si on installe `docker`.

```shell
> sudo ctr image pull docker.io/nvidia/cuda:12.8.0-base-ubuntu24.04

> sudo ctr run --rm --gpus 0 -t docker.io/nvidia/cuda:12.8.0-base-ubuntu24.04 cuda-12-base nvidia-smi
Sun Mar  2 14:41:34 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 565.77                 Driver Version: 565.77         CUDA Version: 12.8     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 3060        Off |   00000000:07:00.0  On |                  N/A |
|  0%   50C    P8             19W /  170W |     514MiB /  12288MiB |     18%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
```

## Ajout du support des GPUs NVIDIA à k3s

Premièrement, installer le NVIDIA Device Plugin permettant d'identifier les GPUs NVIDIA disponibles sur le système.

```shell
helm repo add nvidia-device-plugin https://nvidia.github.io/k8s-device-plugin
helm install nvidia-device-plugin nvidia-device-plugin/nvidia-device-plugin \
  --namespace nvidia-device-plugin --create-namespace
```

## Références

* [Deploying Nvidia GPU Workloads with k3s: A Comprehensive Guide](https://support.tools/deploying-nvidia-gpu-workloads-with-k3s/)
* [NVIDIA Device Plugin for Kubernetes](https://github.com/NVIDIA/k8s-device-plugin)
* [Setting up Nvidia drivers for k3s](https://support.tools/post/nvidia-gpus-on-k3s/)
* [Add NVIDIA GPU support to k3s with containerd](https://dev.to/mweibel/add-nvidia-gpu-support-to-k3s-with-containerd-4j17)
* [Enabling NVIDIA GPUs on K3s for CUDA workloads](https://itnext.io/enabling-nvidia-gpus-on-k3s-for-cuda-workloads-a11b96f967b0)
* [Running CUDA workloads - k3d Docs](https://k3d.io/v5.8.3/usage/advanced/cuda/)
* [Schedule GPUs - Kubernetes Docs](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)
