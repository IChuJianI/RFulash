# RFulash 第三方组件补充声明

本应用内嵌 Ruffle 0.7.1 引擎。上游 Ruffle 的 LICENSE.md 已列出其第三方组件清单与许可全文，并随本应用一并分发；本文件仅补充列出实际编译进本应用引擎、但未被上游清单单列的组件。

## 一、Ruffle 内嵌（vendored）组件

flash-lso 0.6.0 — MIT — Copyright (c) 2020 Callum Thomson
jpegxr 0.3.1 — BSD-2-Clause — Copyright (c) 2009, Microsoft
h263-rs / h263-rs-deblock / h263-rs-yuv 0.1.0 — MIT 或 Apache-2.0 — Copyright (c) 2018-2021 Michael R. Welsh 及贡献者
nihav-core / nihav-codec-support / nihav-duck 0.1.0（经 nihav-vp6 引入）— MIT — Copyright (c) 2021 Kostya Shishkov
regress 0.10.3 — MIT 或 Apache-2.0 — Copyright (c) 2020 ridiculous_fish

## 二、本项目端口新增与新版传递依赖

fontdb 0.23.0 — MIT — Copyright (c) 2020 Yevhenii Reizner
fontconfig-parser 0.5.8 — MIT — Copyright (c) 2021 Riey
roxmltree 0.20.0 — MIT 或 Apache-2.0 — Copyright (c) 2018 Yevhenii Reizner
adler2 2.0.1 — 0BSD 或 MIT 或 Apache-2.0 — Copyright (C) Jonas Schievink
chardetng 0.1.17 — Apache-2.0 或 MIT — Copyright Mozilla Foundation
codespan-reporting 0.13.1 — Apache-2.0 — Brendan Zabarauskas
event-listener 5.4.2 — Apache-2.0 或 MIT — smol-rs 贡献者
fax 0.2.7 — MIT — Copyright © 2021 The pdf-rs contributers
fdeflate 0.3.7 — MIT 或 Apache-2.0 — The image-rs Developers
float_next_after 1.0.0 — MIT — Copyright (c) 2020 Scripta Qumranica Electronica
fluent-bundle 0.16.0 / fluent-syntax 0.12.0 — Apache-2.0 或 MIT — Copyright 2017 Mozilla
fluent-langneg 0.13.1 — Apache-2.0 或 MIT — Mozilla
fluent-templates 0.15.1 — MIT 或 Apache-2.0 — Copyright (c) 2019 Manish Goregaokar
foldhash 0.2.0 — Zlib — Copyright (c) 2024 Orson Peters
guillotiere 0.7.0 — MIT 或 Apache-2.0 — Copyright 2019 Nicolas Silva
half 2.7.1 — MIT 或 Apache-2.0 — Kathryn Long
iana-time-zone 0.1.65 — MIT 或 Apache-2.0 — Copyright (c) 2020 Andrew D. Straw
id3 1.17.2 — MIT — Copyright (c) 2014-2017 James Hurst
ignore 0.4.32 — Unlicense 或 MIT — Copyright (c) 2015 Andrew Gallant
intl_pluralrules 7.0.2 — Apache-2.0 或 MIT — Kekoa Riggin、Zibi Braniecki
libm 0.2.16 — MIT — rust-lang/libm 贡献者
moxcms 0.8.1 — BSD-3-Clause 或 Apache-2.0 — Copyright (c) Radzivon Bartoshyk
naga-types 30.0.1 — MIT 或 Apache-2.0 — naga 项目贡献者（与上游 naga 条目同源）
num-bigint 0.4.8 — MIT 或 Apache-2.0 — Copyright (c) 2014 The Rust Project Developers
pxfm 0.1.30 — BSD-3-Clause 或 Apache-2.0 — Copyright (c) Radzivon Bartoshyk
realfft 3.5.0 — MIT — Henrik Enquist
self_cell 1.3.0 — Apache-2.0（双许可中选用 Apache-2.0）— Copyright (c) Lukas Bergdoll
serde_core 1.0.229 — MIT 或 Apache-2.0 — Erick Tryzelaar、David Tolnay
simd_adler32 0.3.10 — MIT — Copyright (c) 2021 Marvin Countryman
simdutf8 0.1.5 — MIT 或 Apache-2.0 — Hans Kratz
simple_asn1 0.6.4 — ISC — Copyright (c) 2017 Adam Wick
symphonia-core / -bundle-mp3 / -codec-aac / -metadata 0.5.5 — MPL-2.0 — Copyright (c) Philip Deljanov（与上游 symphonia 条目同源）
type-map 0.5.1 — MIT 或 Apache-2.0 — Copyright (c) 2022 Jacob Brown
unic-langid-impl 0.9.6 — MIT 或 Apache-2.0 — Zibi Braniecki
utf8_iter 1.0.4 — Apache-2.0 或 MIT — Copyright Mozilla Foundation
zmij 1.0.23 — MIT — David Tolnay
zune-core 0.5.3 / zune-jpeg 0.5.15 — MIT 或 Apache-2.0 或 Zlib — Copyright (c) zune-image developers

## 许可全文

上述组件的许可全文均见随应用分发的上游 LICENSE.md（含 MIT、Apache-2.0、BSD-2/3-Clause、Zlib、ISC、0BSD、Unlicense、MPL-2.0）。self_cell 为 Apache-2.0 或 GPL-2.0 双许可，本项目选用 Apache-2.0。
