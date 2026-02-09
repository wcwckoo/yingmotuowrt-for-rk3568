#!/bin/bash

# 1. 创建内核设备树目录
mkdir -p target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/

# 2. 写入 Seewo SV21 深度适配设备树 (基于 Armbian 实时数据 + 兼容性修正)
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

	/* 注入 Armbian 同款满血频率表 */
	cpu0_opp_table: opp-table-0 {
		compatible = "operating-points-v2";
		opp-shared;
		opp-408000000 { opp-hz = /bits/ 64 <408000000>; opp-microvolt = <825000 825000 1150000>; };
		opp-1008000000 { opp-hz = /bits/ 64 <1008000000>; opp-microvolt = <825000 825000 1150000>; };
		opp-1416000000 { opp-hz = /bits/ 64 <1416000000>; opp-microvolt = <900000 900000 1150000>; };
		opp-1800000000 { opp-hz = /bits/ 64 <1800000000>; opp-microvolt = <1100000 1100000 1150000>; };
		opp-1992000000 { opp-hz = /bits/ 64 <1992000000>; opp-microvolt = <1150000 1150000 1150000>; };
	};

	vcc12v_dcin: vcc12v-dcin { compatible = "regulator-fixed"; regulator-always-on; regulator-boot-on; };
	vcc5v0_sys: vcc5v0-sys { compatible = "regulator-fixed"; regulator-always-on; regulator-boot-on; vin-supply = <&vcc12v_dcin>; };
};

&cpu0 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };
&cpu1 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };
&cpu2 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };
&cpu3 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };

/* 网卡 1 适配：去掉 PHY 标签引用，改用地址内嵌定义，解决报错 */
&gmac1 {
	phy-mode = "rgmii";
	clock_in_out = "output";
	snps,reset-gpio = <&gpio2 RK_PD1 GPIO_ACTIVE_HIGH>;
	snps,reset-active-high;
	status = "okay";
};

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

/* 核心外设全开 */
&usb_host0_ehci { status = "okay"; };
&usb_host0_xhci { status = "okay"; };
&usb_host1_ehci { status = "okay"; };
&usb_host1_xhci { status = "okay"; };
&usb2phy0_host { status = "okay"; };
&usb2phy1_host { status = "okay"; };
&sata2 { status = "okay"; };
&sdhci { bus-width = <8>; non-removable; status = "okay"; };

/* 极简显示输出：只求 HDMI 亮，不跑 GPU 复杂驱动，保证不崩 */
&hdmi { status = "okay"; };
&vop { status = "okay"; };
EOF

# 3. 修改 Makefile
sed -i '/define Device\/rk3568/i \
define Device/seewo_sv21\
  $(Device/rk3568)\
  DEVICE_VENDOR := Seewo\
  DEVICE_MODEL := SV21 (RK3568B2-Ultimate)\
  DEVICE_DTS := rk3568-seewo-sv21\
  DEVICE_PACKAGES := kmod-usb-net-rtl8152 luci-app-cpufreq kmod-ata-ahci-rockchip kmod-usb3\
endef\
TARGET_DEVICES += seewo_sv21\
' target/linux/rockchip/image/armv8.mk
