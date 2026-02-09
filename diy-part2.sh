#!/bin/bash

# 1. 创建内核设备树目录
mkdir -p target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/

# 2. 写入 Seewo SV21 终极全功能设备树 (基于 Armbian 逆向数据修复版)
cat <<EOF > target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/rk3568-seewo-sv21.dts
// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
/dts-v1/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/pinctrl/rockchip.h>
#include <dt-bindings/soc/rockchip,vop2.h>
#include "rk3568.dtsi"

/ {
	model = "Seewo SV21 Ultimate Box";
	compatible = "seawo,sv21", "rockchip,rk3568";

	aliases {
		ethernet0 = &gmac1;
		mmc1 = &sdhci;
	};

	chosen {
		stdout-path = "serial2:1500000n8";
	};

	/* 满血 2.0GHz 电压表：彻底解决跑分低问题 */
	cpu0_opp_table: opp-table-0 {
		compatible = "operating-points-v2";
		opp-shared;
		opp-408000000 { opp-hz = /bits/ 64 <408000000>; opp-microvolt = <825000 825000 1150000>; };
		opp-600000000 { opp-hz = /bits/ 64 <600000000>; opp-microvolt = <825000 825000 1150000>; };
		opp-816000000 { opp-hz = /bits/ 64 <816000000>; opp-microvolt = <825000 825000 1150000>; };
		opp-1008000000 { opp-hz = /bits/ 64 <1008000000>; opp-microvolt = <825000 825000 1150000>; };
		opp-1416000000 { opp-hz = /bits/ 64 <1416000000>; opp-microvolt = <900000 900000 1150000>; };
		opp-1800000000 { opp-hz = /bits/ 64 <1800000000>; opp-microvolt = <1100000 1100000 1150000>; };
		opp-1992000000 { opp-hz = /bits/ 64 <1992000000>; opp-microvolt = <1150000 1150000 1150000>; };
	};

	vcc12v_dcin: vcc12v-dcin { compatible = "regulator-fixed"; regulator-always-on; regulator-boot-on; };
	vcc5v0_sys: vcc5v0-sys { compatible = "regulator-fixed"; regulator-always-on; regulator-boot-on; vin-supply = <&vcc12v_dcin>; };

	/* 物理 Reset 按键适配 */
	gpio-keys {
		compatible = "gpio-keys";
		pinctrl-names = "default";
		pinctrl-0 = <&reset_key_pin>;
		reset {
			label = "reset";
			gpios = <&gpio0 RK_PB6 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
			debounce-interval = <100>;
		};
	};
};

&cpu0 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };
&cpu1 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };
&cpu2 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };
&cpu3 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };

/* 原生网卡 gmac1 (eth0) 适配 */
&gmac1 {
	phy-mode = "rgmii";
	clock_in_out = "output";
	snps,reset-gpio = <&gpio2 RK_PD1 GPIO_ACTIVE_HIGH>;
	snps,reset-active-high;
	fixed-link = <1 1 1000 1 1>;
	status = "okay";
};

/* 电源管理：锁定 1.15V 上限保证安全稳定 */
&i2c0 {
	status = "okay";
	vdd_cpu: regulator@1c {
		compatible = "tcs,tcs4525";
		reg = <0x1c>;
		regulator-always-on;
		regulator-boot-on;
		regulator-min-microvolt = <800000>;
		regulator-max-microvolt = <1150000>;
		vin-supply = <&vcc5v0_sys>;
	};
};

/* USB & 外设全开启 (支持 USB 3.0 总线上的 RTL8152 网卡) */
&usb_host0_ehci { status = "okay"; };
&usb_host0_xhci { status = "okay"; };
&usb_host1_ehci { status = "okay"; };
&usb_host1_xhci { status = "okay"; };
&usb2phy0_host { status = "okay"; };
&usb2phy1_host { status = "okay"; };
&sata2 { status = "okay"; };
&sdhci { bus-width = <8>; non-removable; status = "okay"; };

/* HDMI 输出与 GPU 开启 (网页后台可见 GPU 负载) */
&hdmi { status = "okay"; };
&hdmi_in { status = "okay"; };
&hdmi_out { status = "okay"; };
&vop { status = "okay"; };
&vop_mmu { status = "okay"; };
&gpu { status = "okay"; };

&pinctrl {
	keys {
		reset_key_pin: reset-key-pin {
			rockchip,pins = <0 RK_PB6 RK_FUNC_GPIO &pcfg_pull_up>;
		};
	};
};
EOF

# 3. 修改 Makefile，注入 Seewo SV21 型号定义
sed -i '/define Device\/rk3568/i \
define Device/seewo_sv21\
  $(Device/rk3568)\
  DEVICE_VENDOR := Seewo\
  DEVICE_MODEL := SV21 (RK3568B2-Ultimate)\
  DEVICE_DTS := rk3568-seewo-sv21\
  DEVICE_PACKAGES := kmod-usb-net-rtl8152 luci-app-cpufreq kmod-ata-ahci-rockchip kmod-drm-rockchip kmod-usb3 kmod-sound-soc-rk809 kmod-usb-ohci kmod-usb2\
endef\
TARGET_DEVICES += seewo_sv21\
' target/linux/rockchip/image/armv8.mk
