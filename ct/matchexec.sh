#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/slamanna212/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: slamanna212
# License: MIT | https://github.com/slamanna212/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/slamanna212/matchexec

APP="MatchExec"
var_tags="${var_tags:-discord;gaming;tournament}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/matchexec ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "matchexec" "slamanna212/matchexec"; then
    msg_info "Stopping Services"
    systemctl stop matchexec-web matchexec-discord-bot matchexec-scheduler matchexec-stats-processor
    msg_ok "Stopped Services"

    msg_info "Backing Up Data"
    cp -r /opt/matchexec/app_data /tmp/matchexec-data-bak
    msg_ok "Backed Up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "matchexec" "slamanna212/matchexec" "tarball"

    msg_info "Restoring Data"
    cp -r /tmp/matchexec-data-bak /opt/matchexec/app_data
    rm -rf /tmp/matchexec-data-bak
    msg_ok "Restored Data"

    msg_info "Installing Dependencies"
    cd /opt/matchexec
    $STD npm ci
    msg_ok "Installed Dependencies"

    msg_info "Building Application"
    cd /opt/matchexec
    $STD npm run build
    cp -r public .next/standalone/
    cp -r .next/static .next/standalone/.next/static
    $STD npm prune --omit=dev
    msg_ok "Built Application"

    msg_info "Running Migrations"
    cd /opt/matchexec
    node dist/migrator.js
    msg_ok "Ran Migrations"

    msg_info "Starting Services"
    systemctl start matchexec-web matchexec-discord-bot matchexec-scheduler matchexec-stats-processor
    msg_ok "Started Services"
    msg_ok "Updated Successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
