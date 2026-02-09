#!/bin/bash

# 1. 自动寻找 Makefile 路径
MK_PATH=$(find target/linux/rockchip/image/ -name "*.mk" | head -n 1)
[ -z "$MK_PATH" ] && MK_PATH="target/linux/rockchip/image/armv8.mk"

# 2. 创建内核设备树目录
mkdir -p target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/

# 3. 写入 Seewo SV21 深度适配设备树 (基于 Armbian 数据)
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

	vcc12v_dcin: vcc12v-dcin { compatible = "regulator-fixed"; regulator-always-on; regulator-boot-on; };
	vcc5v0_sys: vcc5v0-sys { compatible = "regulator-fixed"; regulator-always-on; regulator-boot-on; vin-supply = <&vcc12v_dcin>; };

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

&gmac1 {
	phy-mode = "rgmii";
	clock_in_out = "output";
	snps,reset-gpio = <&gpio2 RK_PD1 GPIO_ACTIVE_HIGH>;
	snps,reset-active-high;
	fixed-link = <1 1 1000 1 1>;
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

&usb_host0_ehci { status = "okay"; };
&usb_host0_xhci { status = "okay"; };
&usb_host1_ehci { status = "okay"; };
&usb_host1_xhci { status = "okay"; };
&usb2phy0_host { status = "okay"; };
&usb2phy1_host { status = "okay"; };
&sata2 { status = "okay"; };
&sdhci { bus-width = <8>; non-removable; status = "okay"; };
&hdmi { status = "okay"; };
&vop { status = "okay"; };

&pinctrl {
	keys {
		reset_key_pin: reset-key-pin {
			rockchip,pins = <0 RK_PB6 RK_FUNC_GPIO &pcfg_pull_up>;
		};
	};
};
EOF

# 4. 强制追加型号定义到 Makefile (这种写法最安全)
cat <<EOT >> \$MK_PATH

define Device/seewo_sv21
  \$(Device/rk3568)
  DEVICE_VENDOR := Seewo
  DEVICE_MODEL := SV21-RK3568B2
  DEVICE_DTS := rk3568-seewo-sv21
  DEVICE_PACKAGES := kmod-usb-net-rtl8152 luci-app-cpufreq kmod-ata-ahci-rockchip kmod-drm-rockchip kmod-usb3
endef
TARGET_DEVICES += seewo_sv21
EOT
