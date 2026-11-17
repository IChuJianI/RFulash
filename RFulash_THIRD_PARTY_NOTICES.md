# RFulash 第三方组件补充声明

本应用内嵌 Ruffle 0.7.1 引擎。上游 Ruffle 的 LICENSE.md 已列出其第三方组件清单与许可全文，并随本应用一并分发；本文件仅补充列出实际编译进本应用引擎、但未被上游清单单列的组件与内嵌资源。

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
async-channel 2.5.0 — Apache-2.0 或 MIT — Stjepan Glavina、smol-rs 贡献者
chardetng 0.1.17 — Apache-2.0 或 MIT — Copyright Mozilla Foundation
codespan-reporting 0.13.1 — Apache-2.0 — Brendan Zabarauskas
concurrent-queue 2.5.0 — Apache-2.0 或 MIT — Stjepan Glavina、Taiki Endo、John Nunley
event-listener 5.4.2 — Apache-2.0 或 MIT — smol-rs 贡献者
event-listener-strategy 0.5.4 — Apache-2.0 或 MIT — John Nunley
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

## 三、内嵌字体

Ruffle 引擎通过 include_bytes! 内嵌默认回退字体 core/assets/notosans.subset.ttf.gz；该文件由 Ruffle 的 update-font.sh 从 notofonts.github.io 下载 NotoSans-Regular 与 NotoSansMath-Regular，经子集化与合并生成，属以下字体的修改版本（Modified Version）：

Noto Sans / Noto Sans Math（子集合并版）— SIL Open Font License 1.1 — Copyright 2018 The Noto Project Authors (github.com/googlei18n/noto-fonts)

字体许可全文：

Copyright 2018 The Noto Project Authors (github.com/googlei18n/noto-fonts)

This Font Software is licensed under the SIL Open Font License,
Version 1.1.

This license is copied below, and is also available with a FAQ at:
http://scripts.sil.org/OFL

-----------------------------------------------------------
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
-----------------------------------------------------------

PREAMBLE
The goals of the Open Font License (OFL) are to stimulate worldwide
development of collaborative font projects, to support the font
creation efforts of academic and linguistic communities, and to
provide a free and open framework in which fonts may be shared and
improved in partnership with others.

The OFL allows the licensed fonts to be used, studied, modified and
redistributed freely as long as they are not sold by themselves. The
fonts, including any derivative works, can be bundled, embedded,
redistributed and/or sold with any software provided that any reserved
names are not used by derivative works. The fonts and derivatives,
however, cannot be released under any other type of license. The
requirement for fonts to remain under this license does not apply to
any document created using the fonts or their derivatives.

DEFINITIONS
"Font Software" refers to the set of files released by the Copyright
Holder(s) under this license and clearly marked as such. This may
include source files, build scripts and documentation.

"Reserved Font Name" refers to any names specified as such after the
copyright statement(s).

"Original Version" refers to the collection of Font Software
components as distributed by the Copyright Holder(s).

"Modified Version" refers to any derivative made by adding to,
deleting, or substituting -- in part or in whole -- any of the
components of the Original Version, by changing formats or by porting
the Font Software to a new environment.

"Author" refers to any designer, engineer, programmer, technical
writer or other person who contributed to the Font Software.

PERMISSION & CONDITIONS
Permission is hereby granted, free of charge, to any person obtaining
a copy of the Font Software, to use, study, copy, merge, embed,
modify, redistribute, and sell modified and unmodified copies of the
Font Software, subject to the following conditions:

1) Neither the Font Software nor any of its individual components, in
Original or Modified Versions, may be sold by itself.

2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy
contains the above copyright notice and this license. These can be
included either as stand-alone text files, human-readable headers or
in the appropriate machine-readable metadata fields within text or
binary files as long as those fields can be easily viewed by the user.

3) No Modified Version of the Font Software may use the Reserved Font
Name(s) unless explicit written permission is granted by the
corresponding Copyright Holder. This restriction only applies to the
primary font name as presented to the users.

4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
Software shall not be used to promote, endorse or advertise any
Modified Version, except to acknowledge the contribution(s) of the
Copyright Holder(s) and the Author(s) or with their explicit written
permission.

5) The Font Software, modified or unmodified, in part or in whole,
must be distributed entirely under this license, and must not be
distributed under any other license. The requirement for fonts to
remain under this license does not apply to any document created using
the Font Software.

TERMINATION
This license becomes null and void if any of the above conditions are
not met.

DISCLAIMER
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
OTHER DEALINGS IN THE FONT SOFTWARE.

## 品牌素材

### 华为应用市场图标

- 来源：华为应用市场官方图标，存放于 `store/icon/appgallery_icon_400.png`
- 归属：图标版权及相关商标归华为技术有限公司所有
- 说明：仅用于在 README 中标识并链接 RFulash 的华为应用市场详情页，不随应用分发。

## 许可全文

上述组件的许可全文均见随应用分发的上游 LICENSE.md（含 MIT、Apache-2.0、BSD-2/3-Clause、Zlib、ISC、0BSD、Unlicense、MPL-2.0、CC0-1.0）；内嵌字体的 SIL OFL 1.1 全文见上节。self_cell 为 Apache-2.0 或 GPL-2.0 双许可，本项目选用 Apache-2.0。
