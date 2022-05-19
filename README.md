# The meta-aws-ewaol repository
This repository provides the example code and instructions for building a customized [Edge Workload Abstraction and Orchestration Layer](https://ewaol.sites.arm.com/meta-ewaol/overview.html) (EWAOL) distribution in form of an [Amazon Machine Image](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) (AMI). The general architecture of the minimal suggested infrastructure can be found [here](graphics/meta-aws-ewaol.png).

## Build instructions

### Pre-requisites

1. Deploy the CloudFormation cfn/vmimport-cfn.yml template to get some basics created (roles, policies, S3 bucket for images).

1. Take note of the outputs of the stack deployment.

1. On a arm64 Ubuntu 20.04 with 100GB+ root disk instance with internet access using the instance profile created by the CloudFormation template:

    ```bash
    sudo apt-get update
    sudo apt-get install -y gawk wget git diffstat unzip texinfo gcc build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev make python3-pip jq
    ```

1. Install AWS CLI v2

    ```bash
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "/tmp/awscliv2.zip"
    unzip /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
    ```

1. Install the python packages:

    ```bash
    sudo pip3 install sphinx sphinx_rtd_theme pyyaml kas==2.5 git-remote-codecommit
    ```

### Building EWAOL

1. Clone the repo from the instance or upload the code and invoke build command. For example:

    ```bash
    git clone <GIT URL for meta-aws-ewaol>
    cd meta-aws-ewaol
    ```

1. Customize the ewaol-graviton2-ami.yaml as needed and invoke build.

    ```bash
    kas build kas/machines/ewaol-graviton2-ami.yaml
    ```

### Creating AMI from image file

from meta-aws-ewaol directory, run the bash script (use the bucket name created by the CloudFormation Stack):

```bash
bash scripts/create-ami.sh <S3_BUCKET_IMPORT_IMAGES> <AMI_DISK_SIZE_IN_GB>
```

### Launch the EC2 Image as usual using your newly created AMI

1. In the Web Console, Navigate to EC2->Images->AMIs
1. Select the desired AMI and click 'Launch instance from Image'
1. Follow the wizard as usual
1. Access the image with the previously provided ssh key with user **ewaol**

### Limitations

The image does not yet support online expansion of partitions/filesystems via cloud-init.
Follow the below workaround to expand root partition and filesystem (this can be used as user data script):

```bash
#!/bin/sh

# disabling swap
swapoff -a
sed -i '/.*swap.*/d' /etc/fstab
# trick to fix GPT
printf "fix\n" | parted ---pretend-input-tty /dev/nvme0n1 print
# remove partition 3 (swap)
parted -s /dev/nvme0n1 rm 3
# resize partition 2 to use 100% of available free space
parted -s /dev/nvme0n1 resizepart 2 100%
# resizing ext4 filesystem
resize2fs /dev/nvme0n1p2
```

## Future Enchancements

* Enable support for expanding filesystem on boot with cloud-init which depends on growpart. This needs cloud-utils which is not in openembedded recipes yet.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This code is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.
