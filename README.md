# Airscan scanners to Windows forwarder

Docker container running SANE daemon configured with airscan and modified, so that network scanners are also exposed. The goal of this is to allow usage of eSCL scanners on Windows through the use of [SANEWinDS](https://sourceforge.net/projects/sanewinds/).

## Motivation for the software

A doctor friend of mine has their medical software running on a Windows Server 2022. The software connects to scanners using TWAIN and Windows at the time of writing does not natively support Airscan/eSCL printers. The manufacturer's (in this case Canon) driver supports it, but the driver is intentionally incompatible with Windows Server. To use their printers on servers, you have to buy an expensive enterprise-grade multifunctional printer.

The system in this container is designed to circumvent this artificial limitation by using eSCL and SANE on a separately running Linux box. The scanner is then shared over network using the SANE protocol and [SANEWinDS] is used as a client on Windows.

In this situation, I deployed the container as follows:

```
git clone https://github.com/vakabus/docker-saned-airscan scanner
cd scanner
docker built -t scanner .
docker run --restart=always -d --network host --privileged --name=scanner scanner
```
