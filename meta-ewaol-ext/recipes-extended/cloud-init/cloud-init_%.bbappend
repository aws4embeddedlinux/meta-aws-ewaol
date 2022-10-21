# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
FILESEXTRAPATHS:prepend := "${THISDIR}/conf:"
FILESEXTRAPATHS:prepend := "${THISDIR}/patches:"

SRC_URI:append = "file://cloud.cfg"
SRC_URI:append = " file://read-version.patch"

do_install:append () {
	# Avoid ordering cycle in systemd that triggers removal of cloud-init.service. See https://bugs.launchpad.net/ubuntu/+source/cloud-init/+bug/1956629
	sed -i -e 's:Before=sysinit.target:#Before=sysinit.target:' ${D}${systemd_system_unitdir}/cloud-init.service 
	
	# Forcing the installation of systemd services given that recipe is not enabling it.
	install -d ${D}${sysconfdir}/systemd/system/cloud-init.target.wants/
	ln -s ${systemd_system_unitdir}/cloud-init.service ${D}${sysconfdir}/systemd/system/cloud-init.target.wants/cloud-init.service
	ln -s ${systemd_system_unitdir}/cloud-init-local.service ${D}${sysconfdir}/systemd/system/cloud-init.target.wants/cloud-init-local.service
	ln -s ${systemd_system_unitdir}/cloud-config.service ${D}${sysconfdir}/systemd/system/cloud-init.target.wants/cloud-config.service
	ln -s ${systemd_system_unitdir}/cloud-final.service ${D}${sysconfdir}/systemd/system/cloud-init.target.wants/cloud-final.service

	# Adding cloud-init configuration with reasonable settings that work for EWAOL. Some features were disabled given not all binaries are present in distro
	install -T -m 0644 ${WORKDIR}/cloud.cfg ${D}${sysconfdir}/cloud/cloud.cfg
}
