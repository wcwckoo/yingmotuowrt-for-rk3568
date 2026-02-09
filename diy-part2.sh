#!/bin/bash

# 1. 创建内核设备树目录
mkdir -p target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/

# 2. 写入 Seewo SV21 专属设备树 (补全了缺失的 mdio 节点)
cat <<EOF > target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/rk3568-seewo-sv21.dts
// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
/dts-v1/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/leds/common.h>
#include <dt-bindings/pinctrl/rockchip.h>
#include <dt-bindings/soc/rockchip,vop2.h>
#include "rk3568.dtsi"

/ {
	model = "Seawo SV21 Model A";
	compatible = "seawo,sv21", "rockchip,rk3568";

	aliases {
		ethernet0 = &gmac0;
		ethernet1 = &gmac1;
		mmc0 = &sdmmc0;
		mmc1 = &sdhci;
	};

	chosen: chosen {
		stdout-path = "serial2:1500000n8";
	};

	cpu0_opp_table: opp-table-0 {
		compatible = "operating-points-v2";
		opp-shared;
		opp-408000000 { opp-hz = /bits/ 64 <408000000>; opp-microvolt = <825000 825000 1150000>; };
		opp-600000000 { opp-hz = /bits/ 64 <600000000>; opp-microvolt = <825000 825000 1150000>; };
		opp-816000000 { opp-hz = /bits/ 64 <816000000>; opp-microvolt = <825000 825000 1150000>; };
		opp-1008000000 { opp-hz = /bits/ 64 <1008000000>; opp-microvolt = <825000 825000 1150000>; };
		opp-1200000000 { opp-hz = /bits/ 64 <1200000000>; opp-microvolt = <825000 825000 1150000>; };
		opp-1416000000 { opp-hz = /bits/ 64 <1416000000>; opp-microvolt = <900000 900000 1150000>; };
		opp-1608000000 { opp-hz = /bits/ 64 <1608000000>; opp-microvolt = <1000000 1000000 1150000>; };
		opp-1800000000 { opp-hz = /bits/ 64 <1800000000>; opp-microvolt = <1100000 1100000 1150000>; };
		opp-1992000000 { opp-hz = /bits/ 64 <1992000000>; opp-microvolt = <1150000 1150000 1150000>; };
	};

	vcc12v_dcin: vcc12v-dcin {
		compatible = "regulator-fixed";
		regulator-always-on;
		regulator-boot-on;
	};

	vcc5v0_sys: vcc5v0-sys {
		compatible = "regulator-fixed";
		regulator-always-on;
		regulator-boot-on;
		vin-supply = <&vcc12v_dcin>;
	};
};

&cpu0 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };
&cpu1 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };
&cpu2 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };
&cpu3 { cpu-supply = <&vdd_cpu>; operating-points-v2 = <&cpu0_opp_table>; };

&gmac1 {
	assigned-clocks = <&cru SCLK_GMAC1_RX_TX>, <&cru SCLK_GMAC1>;
	assigned-clock-parents = <&cru SCLK_GMAC1_RGMII_SPEED>;
	assigned-clock-rates = <0>, <125000000>;
	clock_in_out = "output";
	phy-mode = "rgmii";
	pinctrl-names = "default";
	pinctrl-0 = <&gmac1m1_miim &gmac1m1_tx_bus2 &gmac1m1_rx_bus2 &gmac1m1_rgmii_clk &gmac1m1_rgmii_bus>;
	snps,reset-gpio = <&gpio2 RK_PD1 GPIO_ACTIVE_HIGH>;
	snps,reset-active-high;
	tx_delay = <0x2a>;
	rx_delay = <0x2a>;
	fixed-link = <1 1 1000 1 1>;
	phy-handle = <&rgmii_phy1>;
	status = "okay";
};

&mdio1 {
	rgmii_phy1: ethernet-phy@1 {
		compatible = "ethernet-phy-ieee802.3-c22";
		reg = <0x1>;
	};
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

&sdhci {
	bus-width = <8>;
	max-frequency = <200000000>;
	non-removable;
	pinctrl-names = "default";
	pinctrl-0 = <&emmc_bus8 &emmc_clk &emmc_cmd &emmc_datastrobe>;
	status = "okay";
};

&usb_host1_xhci { status = "okay"; };
&sata2 { status = "okay"; };
EOF

# 3. 修改 Makefile
sed -i '/define Device\/rk3568/i \
define Device/seewo_sv21\
  $(Device/rk3568)\
  DEVICE_VENDOR := Seewo\
  DEVICE_MODEL := SV21 (RK3568B2)\
  DEVICE_DTS := rk3568-seewo-sv21\
  DEVICE_PACKAGES := kmod-usb-net-rtl8152 luci-app-cpufreq kmod-ata-ahci-rockchip\
endef\
TARGET_DEVICES += seewo_sv21\
' target/linux/rockchip/image/armv8.mk
