#!/bin/bash 

v2srv_user=hass
v2srv_uid=8123

v2srv_host=$(hostname)
v2srv_ip=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

pip_pip () {
 python3.6 -m ensurepip
 pip3 install --upgrade pip
 pip3 install --upgrade virtualenv
}

add_hass () {
  pw addgroup -g 8123 -n ${v2srv_user}
  pw adduser -u 8123 -n ${v2srv_user} -d /home/${v2srv_user} -w no -s /usr/local/bin/bash -G dialer -c "homeassistant daemon"
  chmod -R g=u /home/${v2srv_user}; chown -R ${v2srv_user}:${v2srv_user} /home/${v2srv_user}
}

install_configurator () {
  v2srv=configurator
    install -d -g "${v2srv_user}" -o "${v2srv_user}" -m 775 -- /srv/${v2srv} || exit
  wget https://raw.githubusercontent.com/danielperna84/hass-configurator/master/configurator.py -O /srv/${v2srv}/configurator.py
  chmod +x /srv/${v2srv}/configurator.py
    start_v2srv
}

install_homeassistant () {
  v2srv=homeassistant
   yaml=/home/hass/homeassistant/configuration.yaml
    install -d -g "${v2srv_user}" -o "${v2srv_user}" -m 775 -- /srv/${v2srv} || exit
  screen -dmS scrn_env su - hass -c "bash /root/post_install.sh homeassistant-virt"
  screen -r scrn_env || exit
   echo ${yaml} | sed -i .bak "s/xXx.XxX.XxX.xXx/${v2srv_ip}/g" ${yaml}
    start_v2srv
}

install_appdaemon () {
  v2srv=appdaemon
    install -d -g "${v2srv_user}" -o "${v2srv_user}" -m 775 -- /srv/${v2srv} || exit
  screen -dmS scrn_env su - hass -c "bash /root/post_install.sh appdaemon-virt"
  screen -r scrn_env || exit
    start_v2srv
}

homeassistant_virt () {
  v2srv=homeassistant
    echo "Installing ${v2srv} virtualenv for: `whoami`"; echo
    sleep 2 # sleep 2 so we check we're the right person above
  virtualenv -p /usr/local/bin/python3.6 /srv/homeassistant
  source /srv/homeassistant/bin/activate
  pip3 install --upgrade homeassistant
    exit
}

appdaemon_virt () {
  v2srv=appdaemon
    echo "Installing ${v2srv} virtualenv for: `whoami`"; echo
    sleep 2 # sleep 2 so we check we're the right person above
  virtualenv -p /usr/local/bin/python3.6 /srv/appdaemon
  source /srv/appdaemon/bin/activate
  pip3 install --pre appdaemon
    exit
}

start_v2srv () {
  chmod +x /usr/local/etc/rc.d/${v2srv}
  sysrc -f /etc/rc.conf ${v2srv}_enable=yes
  service ${v2srv} start; sleep 1
  echo "Checking on ${v2srv}..."; sleep 2
  service ${v2srv} status
}

colors () {                               # Defien Some Colors for Messages
  red=$'\e[1;31m'
  grn=$'\e[1;32m'
  yel=$'\e[1;33m'
  blu=$'\e[1;34m'
  mag=$'\e[1;35m'
  cyn=$'\e[1;36m'
  end=$'\e[0m'
}                                         # Call Function: colors

end_report () {                 # read all about it!
  echo; echo; echo; echo
  colors
    echo " ${red}Status Report: ${grn}${v2srv_host}${end}"; echo
    echo "  ${blu}$(service homeassistant status)${end}"
    echo "   ${blu}$(service configurator status)${end}"
    echo "      ${blu}$(service appdaemon status)${end}"
  echo   
    echo " ${cyn}Home Assistant: ${grn}http://${v2srv_ip}${cyn}:8123${end}"
    echo "   ${cyn}Configurator: ${grn}http://${v2srv_ip}${cyn}:3218${end}"
    echo "    ${cyn}HADashboard: ${grn}http://${v2srv_ip}${cyn}:5050${end}"
  echo
  echo; echo " ${red}Finished!${end}"; exit    
}

case $@ in
  appdaemon-virt)
    appdaemon_virt
   ;;
  homeassistant-virt)
    homeassistant_virt
   ;;
  end-report)
    end_report
   ;;
esac

do_it () {         # let's nstall this shit already! 
  add_hass || exit   # problems already -- just quit
   pip_pip
    install_homeassistant; sleep 2
    install_appdaemon;     sleep 2
    install_configurator;  sleep 1
   chmod -R g=u /home/${v2srv_user}
}

do_it
end_report

