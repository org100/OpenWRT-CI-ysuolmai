#!/bin/bash

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_CI-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH="./package/base-files/files/etc/uci-defaults/990_set-wireless.sh"
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	#修改WIFI名称
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	#修改WIFI地区
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	#修改WIFI加密
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
if [[ $WRT_TARGET == *"IPQ"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
fi




#######################################
#DIY
#######################################
WRT_IP="192.168.1.1"
WRT_NAME="FWRT"
WRT_WIFI="FWRT"
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#修改默认WIFI名
sed -i "s/\.ssid=.*/\.ssid=$WRT_WIFI/g" $(find ./package/kernel/mac80211/ ./package/network/config/ -type f -name "mac80211.*")

#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#补齐依赖
sudo -E apt-get -y install $(curl -fsSL is.gd/depends_ubuntu_2204)

keywords_to_delete=(
    "abt_asr3000" "cmcc_a10" "xiaomi_ax1800" "glinet" "h3c_magic-nx30-pro" "jdcloud_re-cp-03" "konka_komi-a31" "netcore_n60" "zyxel_ex5700-telenor" "cmiot_ax18"
    "nokia_ea0326gmp" "qihoo_360t7" "xiaomi_ax1800" "ruijie_rg-x60-pro" "tplink" "xiaomi_mi-router-ax3000t" "xiaomi_mi-router-wr30u" "xiaomi_redmi-router-ax6000"
    "abt_asr3000" "qihoo_360v6" "redmi_ax5" "redmi_ax5-jdcloud" "cmcc_rm2-6""redmi_ax6-stock" "redmi_ax6" "xiaomi_ax3600-stock" "xiaomi_ax3600" "xiaomi_ax9000"
    "cetron_ct3003" "imou_lc-hx3001" "jcg_q30-pro" "cmcc_rm2-6" "aliyun_ap8220" "linksys_mr7350" "cudy_tr3000-v1"
    "uugamebooster" "luci-app-wol" "luci-i18n-wol-zh-cn" "CONFIG_TARGET_INITRAMFS" "ddns" "luci-app-advancedplus" "luci-theme-kucat" "luci-app-mihomo"
)

[[ $WRT_TARGET == *"WIFI-NO"* ]] && keywords_to_delete+=("re-ss-01" "re-cs-02")
[[ $WRT_TARGET != *"EMMC"* ]] && keywords_to_delete+=("samba" "autosamba""disk")
[[ $WRT_TARGET == *"EMMC"* ]] && keywords_to_delete+=("zn_m2")

for keyword in "${keywords_to_delete[@]}"; do
    sed -i "/$keyword/d" ./.config
done

# Configuration lines to append to .config
provided_config_lines=(
   "CONFIG_PACKAGE_luci-app-cpufreq=y"
    "CONFIG_PACKAGE_luci-app-ttyd=y"
    "CONFIG_PACKAGE_luci-app-homeproxy=y"
    "CONFIG_PACKAGE_luci-app-alist=y"
    "CONFIG_PACKAGE_luci-app-mosdns=y"
    "CONFIG_PACKAGE_luci-app-lucky=y"
    "CONFIG_PACKAGE_luci-app-upnp=y"
    "CONFIG_PACKAGE_luci-app-aria2=y"
    "CONFIG_PACKAGE_luci-app-wolplus=y"
    "CONFIG_PACKAGE_luci-app-samba4=y"
    "CONFIG_PACKAGE_luci-app-hd-idle=y"
)

[[ $WRT_TARGET == *"WIFI-NO"* ]] && provided_config_lines+=("CONFIG_PACKAGE_hostapd-common=n" "CONFIG_PACKAGE_wpad-openssl=n")
if [[ $WRT_TAG == *"WIFI-NO"* ]]; then
    provided_config_lines+=(
        "CONFIG_PACKAGE_hostapd-common=n"
        "CONFIG_PACKAGE_wpad-openssl=n"
    )
#else
    #provided_config_lines+=(
    #    "CONFIG_PACKAGE_kmod-usb-net=y"
    #    "CONFIG_PACKAGE_kmod-usb-net-rndis=y"
    #    "CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y"
    #    "CONFIG_PACKAGE_usbutils=y"
    #)
fi


[[ $WRT_TARGET == *"EMMC"* ]] && provided_config_lines+=(
    "CONFIG_PACKAGE_luci-app-diskman=y"
    "CONFIG_PACKAGE_luci-app-dockerman=y"
)

# Append configuration lines to .config
for line in "${provided_config_lines[@]}"; do
    echo "$line" >> .config
done


#./scripts/feeds update -a
#./scripts/feeds install -a

find ./ -name "cascade.css" -exec sed -i 's/#5e72e4/#6fa49a/g; s/#483d8b/#6fa49a/g' {} \;
find ./ -name "dark.css" -exec sed -i 's/#5e72e4/#6fa49a/g; s/#483d8b/#6fa49a/g' {} \;

find ./ -name "getifaddr.c" -exec sed -i 's/return 1;/return 0;/g' {} \;
#find ./ -type d -name 'luci-app-ddns-go' -exec sh -c '[ -f "$1/Makefile" ] && sed -i "/config\/ddns-go/d" "$1/Makefile"' _ {} \;
#find ./ -type d -name "luci-app-ddns-go" -exec sh -c 'f="{}/Makefile"; [ -f "$f" ] && echo "\ndefine Package/\$(PKG_NAME)/install\n\trm -f \$(1)/etc/config/ddns-go\n\t\$(call InstallDev,\$(1))\nendef\n" >> "$f"' \;
#find ./ -type d -name "ddns-go" -exec sh -c 'f="{}/Makefile"; [ -f "$f" ] && sed -i "/\$(INSTALL_BIN).*\/ddns-go.init.*\/etc\/init.d\/ddns-go/d" "$f"' \;
rm -rf ./feeds/packages/net/ddns-go;

# 修复拨号问题
echo "sed -i '8c maxfail 1' /etc/ppp/options" >> package/base-files/files/lib/functions/uci-defaults.sh
echo "sed -i '192i sleep 30' /lib/netifd/proto/ppp.sh" >> package/base-files/files/lib/functions/uci-defaults.sh
