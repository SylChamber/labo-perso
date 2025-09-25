#!/usr/bin/env bash
# Configure et installe le service FetchIt

FETCHIT_CONFIG_DIR=/etc/fetchit

if [ ! -d $FETCHIT_CONFIG_DIR ] ; then
    mkdir -p $FETCHIT_CONFIG_DIR
fi

if [ ! -f $FETCHIT_CONFIG_DIR/config.yaml ]; then
    cat << EOF > $FETCHIT_CONFIG_DIR/config.yaml
configReload:
  configURL: https://raw.githubusercontent.com/SylChamber/labo-perso/main/systeme/services/config.yaml
  schedule: "*/5 * * * *"
EOF
    chcon -t container_file_t -R $FETCHIT_CONFIG_DIR
    chmod 640 $FETCHIT_CONFIG_DIR/config.yaml
fi

cat << EOF > /etc/systemd/system/fetchit.service
[Unit]
Description=Fetchit container management tool
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=always
TimeoutStopSec=65
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroups=no-conmon --rm --security-opt label=disable --sdnotify=conmon --replace --label io.containers.autoupdate=registry -d --name fetchit -v fetchit-volume:/opt -v $FETCHIT_CONFIG_DIR:/opt/mount -v /run/podman/podman.sock:/run/podman/podman.sock --secret GH_PAT,type=env quay.io/fetchit/fetchit:latest
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable --now podman.socket
