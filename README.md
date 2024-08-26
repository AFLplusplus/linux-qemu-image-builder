# Linux kernel fuzzer template

This repository offers an easy way to set a QEMU-compatible, full-fledged and ready to fuzz Linux disk.
UEFI is automatically configured to boot the Linux disk without any use interaction.
We use UKI for faster boot.
It has been tested successfully in both KVM and TCG mode on the x86\_64 architecture.

The scripts have been kept as short and readable as possible, to make script hacking reasonably painless.

This repository has been designed with [LibAFL QEMU](https://github.com/AFLplusplus/LibAFL/tree/main/libafl_qemu) in mind, although it is completely separated.
Thus, it should be quite easy to reuse this as a basis in other projects.

Please refer to the [LibAFL QEMU Linux fuzzer example]() for an example of usecase in a fuzzing context.

For more information about the technical details, you can have a look to [the design section](#design).

## Prerequisites

At the moment, these scripts are only compatible with Linux.
**Your kernel should have the NBD kernel module (it is the case in most cases) and docker available.**

Install docker if it's not already installed.
Adapt this to your distribution if it's not debian-based.

```bash
sudo apt install -y docker.io
```

Test if the NBD kernel module is installed on your host machine.
The following command should run successfully.
Otherwise, your kernel is most likely not shipped with NBD.
Please install the NBD kernel module to proceed in case of error.

```bash
sudo modprobe nbd max_part=8
```

To run and test the generated disk, QEMU system should be available on your machine.
Adapt this to your distribution if it's not debian-based.

```bash
sudo apt install -y qemu
```

## Basic usage

For a quick test, first build the QCOW2 image.

```bash
./build.sh
```

If everything goes well, there should be 3 files in `output`:
- `linux.qcow2`: the image containing the Linux kernel and the root directory.
- `OVMF_CODE.fd`: the OVMF UEFI code section.
- `OVMF_VARS.fd`: the OVMF UEFI variable store.

From there, it should be straightforward to run Linux in QEMU:

```bash
./run.sh
```

If the login prompt appears after a few seconds, it means everything works as expected.
We configured user `root` and password `toor` as default credentials. This can be changed in `setup/setup.sh`.
Checkout [the basic modification section](#basic-modifications) for more details.

It is also possible to run a headless (without a GUI) version of this.
It is a more common way to configure qemu for fuzzing.

```bash
./run_headless.sh
```

## Basic modifications

For the simplest modifications, we expect things to happen mostly in `runtime` and `setup`: 
- `setup` content will be copied under `/setup` in the VM and `/setup/setup.sh` will be run **during disk creation**, chrooted into the disk root directory. Edit `setup/setup.sh` with anything that should be done during the creation of the disk. It is requried to fully recreate the disk (with `build.sh`) if an update should be applied.
- `runtime` content will be copied under `/runtime` in the VM and `/runtime/entrypoint.sh` will be run **each time the VM starts**. A service has been setup to handle everything automatically. Edit `runtime/entrypoint.sh` with anything that should be run at VM start. It is possible to run `update.sh` to automatically update the QEMU image without recreating the full disk. Beware, the old content of the `/runtime` directory (in the VM) will be lost forever.

## Details

Main scripts, expected to be run by most users:
- `build.sh`: Build the QEMU image.
- `parameters.sh`: Set of editable parameters and common functions used to create and run the VM.
- `run.sh`: Run the QEMU VM (with GUI).
- `run_headless.sh`: Run the QEMU VM (without GUI).
- `update.sh`: Update `/runtime` (old VM `setup` and `runtime` will be erased).

Internal scripts, for more advanced uses:
- `scripts/create_image.sh`: Create the QEMU image without wrapping the execution in a docker container (main creation script is run there). It highly relies on `sudo`, run it on your host machine at your own risk.
- `scripts/mount.sh`: Mount the QEMU disk under `mnt`. Can be run on the host machine.
- `scripts/umount.sh`: Unmount the QEMU disk under `mnt`. Can be run on the host machine. It is supposed to be resilient and can be used to cleanup things in most cases.
- `scripts/update.sh`: Update the QEMU image `setup` and `runtime` directory, without wrapping the execution in a docker container.

Other stuff:
- `templates`: various files and placeholders used during the creationg of the VM image.
- `mnt`: Mount directory, folder where the disk get mounted when calling `scripts/mount.sh`

## Design

We chose [ArchLinux](https://archlinux.org/) as the underlying kernel for multiple reasons:
- It is  lightweight. It makes it a good candidate to get high performance during fuzzing, by minimizing the amount of programs being run in background with a low memory consumption.
- It is very close to the vanilla Linux kernel. Thus, it should be easy to adapt these scripts to run with highly customized kernels.
- It is easy to setup. At least compared to most alternatives.
