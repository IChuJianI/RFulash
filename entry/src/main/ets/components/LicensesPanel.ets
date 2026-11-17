import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { DEFAULT_ACCENT } from '../common/ThemePalette';

const SECTION_PROJECTS = 0;
const SECTION_MIT = 1;
const SECTION_APACHE = 2;
const SECTION_THIRD_PARTY = 3;

const LICENSE_CHUNK_CHARS = 1800;
const UPSTREAM_LICENSE_FILE = 'Ruffle_LICENSE.md';
const SUPPLEMENT_FILE = 'RFulash_THIRD_PARTY_NOTICES.md';
const VIEWER_UPSTREAM = 0;
const VIEWER_SUPPLEMENT = 1;

const APP_NAME = 'RFulash';
const APP_COPYRIGHT = 'Copyright (c) 2026 李晨';
const APP_REPO_URL = 'https://github.com/IChuJianI/RFulash';
const RUFFLE_NAME = 'Ruffle';
const RUFFLE_COPYRIGHT =
  'Copyright (c) 2018-2022 Ruffle LLC <ruffle@ruffle.rs> and Ruffle contributors ' +
  '(https://github.com/ruffle-rs/ruffle/graphs/contributors)';
const RUFFLE_URL = 'https://github.com/ruffle-rs/ruffle';

const RUFFLE_VERSION = '0.7.1';
const MIT_LICENSE_TEXT = 'MIT License\n\nCopyright (c) 2018-2022 Ruffle LLC <ruffle@ruffle.rs> and Ruffle contributors\n                        (https://github.com/ruffle-rs/ruffle/graphs/contributors)\n\nPermission is hereby granted, free of charge, to any\nperson obtaining a copy of this software and associated\ndocumentation files (the "Software"), to deal in the\nSoftware without restriction, including without\nlimitation the rights to use, copy, modify, merge,\npublish, distribute, sublicense, and/or sell copies of\nthe Software, and to permit persons to whom the Software\nis furnished to do so, subject to the following\nconditions:\n\nThe above copyright notice and this permission notice\nshall be included in all copies or substantial portions\nof the Software.\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF\nANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED\nTO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A\nPARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT\nSHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY\nCLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION\nOF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR\nIN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER\nDEALINGS IN THE SOFTWARE.';

const APACHE_LICENSE_TEXT = `Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

1. Definitions.

"License" shall mean the terms and conditions for use, reproduction, and distribution as defined by Sections 1 through 9 of this document.

"Licensor" shall mean the copyright owner or entity authorized by the copyright owner that is granting the License.

"Legal Entity" shall mean the union of the acting entity and all other entities that control, are controlled by, or are under common control with that entity. For the purposes of this definition, "control" means (i) the power, direct or indirect, to cause the direction or management of such entity, whether by contract or otherwise, or (ii) ownership of fifty percent (50%) or more of the outstanding shares, or (iii) beneficial ownership of such entity.

"You" (or "Your") shall mean an individual or Legal Entity exercising permissions granted by this License.

"Source" form shall mean the preferred form for making modifications, including but not limited to software source code, documentation source, and configuration files.

"Object" form shall mean any form resulting from mechanical transformation or translation of a Source form, including but not limited to compiled object code, generated documentation, and conversions to other media types.

"Work" shall mean the work of authorship, whether in Source or Object form, made available under the License, as indicated by a copyright notice that is included in or attached to the work (an example is provided in the Appendix below).

"Derivative Works" shall mean any work, whether in Source or Object form, that is based on (or derived from) the Work and for which the editorial revisions, annotations, elaborations, or other modifications represent, as a whole, an original work of authorship. For the purposes of this License, Derivative Works shall not include works that remain separable from, or merely link (or bind by name) to the interfaces of, the Work and Derivative Works thereof.

"Contribution" shall mean any work of authorship, including the original version of the Work and any modifications or additions to that Work or Derivative Works thereof, that is intentionally submitted to Licensor for inclusion in the Work by the copyright owner or by an individual or Legal Entity authorized to submit on behalf of the copyright owner. For the purposes of this definition, "submitted" means any form of electronic, verbal, or written communication sent to the Licensor or its representatives, including but not limited to communication on electronic mailing lists, source code control systems, and issue tracking systems that are managed by, or on behalf of, the Licensor for the purpose of discussing and improving the Work, but excluding communication that is conspicuously marked or otherwise designated in writing by the copyright owner as "Not a Contribution."

"Contributor" shall mean Licensor and any individual or Legal Entity on behalf of whom a Contribution has been received by Licensor and subsequently incorporated within the Work.

2. Grant of Copyright License. Subject to the terms and conditions of this License, each Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable copyright license to reproduce, prepare Derivative Works of, publicly display, publicly perform, sublicense, and distribute the Work and such Derivative Works in Source or Object form.

3. Grant of Patent License. Subject to the terms and conditions of this License, each Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable (except as stated in this section) patent license to make, have made, use, offer to sell, sell, import, and otherwise transfer the Work, where such license applies only to those patent claims licensable by such Contributor that are necessarily infringed by their Contribution(s) alone or by combination of their Contribution(s) with the Work to which such Contribution(s) was submitted. If You institute patent litigation against any entity (including a cross-claim or counterclaim in a lawsuit) alleging that the Work or a Contribution incorporated within the Work constitutes direct or contributory patent infringement, then any patent licenses granted to You under this License for that Work shall terminate as of the date such litigation is filed.

4. Redistribution. You may reproduce and distribute copies of the Work or Derivative Works thereof in any medium, with or without modifications, and in Source or Object form, provided that You meet the following conditions:

(a) You must give any other recipients of the Work or Derivative Works a copy of this License; and

(b) You must cause any modified files to carry prominent notices stating that You changed the files; and

(c) You must retain, in the Source form of any Derivative Works that You distribute, all copyright, patent, trademark, and attribution notices from the Source form of the Work, excluding those notices that do not pertain to any part of the Derivative Works; and

(d) If the Work includes a "NOTICE" text file as part of its distribution, then any Derivative Works that You distribute must include a readable copy of the attribution notices contained within such NOTICE file, excluding those notices that do not pertain to any part of the Derivative Works, in at least one of the following places: within a NOTICE text file distributed as part of the Derivative Works; within the Source form or documentation, if provided along with the Derivative Works; or, within a display generated by the Derivative Works, if and wherever such third-party notices normally appear. The contents of the NOTICE file are for informational purposes only and do not modify the License. You may add Your own attribution notices within Derivative Works that You distribute, alongside or as an addendum to the NOTICE text from the Work, provided that such additional attribution notices cannot be construed as modifying the License.

You may add Your own copyright statement to Your modifications and may provide additional or different license terms and conditions for use, reproduction, or distribution of Your modifications, or for any such Derivative Works as a whole, provided Your use, reproduction, and distribution of the Work otherwise complies with the conditions stated in this License.

5. Submission of Contributions. Unless You explicitly state otherwise, any Contribution intentionally submitted for inclusion in the Work by You to the Licensor shall be under the terms and conditions of this License, without any additional terms or conditions. Notwithstanding the above, nothing herein shall supersede or modify the terms of any separate license agreement you may have executed with Licensor regarding such Contributions.

6. Trademarks. This License does not grant permission to use the trade names, trademarks, service marks, or product names of the Licensor, except as required for reasonable and customary use in describing the origin of the Work and reproducing the content of the NOTICE file.

7. Disclaimer of Warranty. Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including, without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License.

8. Limitation of Liability. In no event and under no legal theory, whether in tort (including negligence), contract, or otherwise, unless required by applicable law (such as deliberate and grossly negligent acts) or agreed to in writing, shall any Contributor be liable to You for damages, including any direct, indirect, special, incidental, or consequential damages of any character arising as a result of this License or out of the use or inability to use the Work (including but not limited to damages for loss of goodwill, work stoppage, computer failure or malfunction, or any and all other commercial damages or losses), even if such Contributor has been advised of the possibility of such damages.

9. Accepting Warranty or Additional Liability. While redistributing the Work or Derivative Works thereof, You may choose to offer, and charge a fee for, acceptance of support, warranty, indemnity, or other liability obligations and/or rights consistent with this License. However, in accepting such obligations, You may act only on Your own behalf and on Your sole responsibility, not on behalf of any other Contributor, and only if You agree to indemnify, defend, and hold each Contributor harmless for any liability incurred by, or claims asserted against, such Contributor by reason of your accepting any such warranty or additional liability.

END OF TERMS AND CONDITIONS`;

class LicenseTextSource implements IDataSource {
  private items: string[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number {
    return this.items.length;
  }

  getData(index: number): string {
    return this.items[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  setItems(items: string[]): void {
    this.items = items;
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded();
    }
  }
}

function splitLicenseText(text: string): string[] {
  const chunks: string[] = [];
  const lines = text.split('\n');
  let start = 0;
  let length = 0;
  for (let i = 0; i < lines.length; i++) {
    length += lines[i].length + 1;
    if (length >= LICENSE_CHUNK_CHARS) {
      chunks.push(lines.slice(start, i + 1).join('\n'));
      start = i + 1;
      length = 0;
    }
  }
  if (start < lines.length) {
    chunks.push(lines.slice(start).join('\n'));
  }
  return chunks;
}

/** Licenses sheet content: upstream-aligned notices plus the bundled LICENSE.md. */
@Component
export struct LicensesPanel {
  @Link viewerOpen: boolean;
  onBack: () => void = (): void => {};
  @StorageLink('accentColor') private accentColor: string = DEFAULT_ACCENT;
  @State private expanded: number = -1;
  @State private viewerKind: number = VIEWER_UPSTREAM;
  private licenseSource: LicenseTextSource = new LicenseTextSource();
  private loadedKind: number = -1;

  private str(res: Resource): string {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      return context.resourceManager.getStringSync(res.id);
    } catch (error) {
      return '';
    }
  }

  private componentText(): string {
    try {
      const context = this.getUIContext().getHostContext() as common.Context;
      return context.resourceManager.getStringSync($r('app.string.ruffle_components').id, RUFFLE_VERSION);
    } catch (error) {
      return '';
    }
  }

  private copyUrl(url: string): void {
    const context = this.getUIContext();
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, url);
    pasteboard.getSystemPasteboard().setData(data)
      .then(() => {
        context.getPromptAction().showToast({ message: $r('app.string.toast_link_copied'), duration: 1200 });
      })
      .catch((error: BusinessError) => {
        console.error(`copy to clipboard failed: ${error.message}`);
      });
  }

  private openLicense(kind: number): void {
    try {
      if (this.loadedKind !== kind) {
        const context = this.getUIContext().getHostContext();
        if (!context) {
          throw new Error('host context unavailable');
        }
        const file = kind === VIEWER_SUPPLEMENT ? SUPPLEMENT_FILE : UPSTREAM_LICENSE_FILE;
        const bytes = context.resourceManager.getRawFileContentSync(file);
        const decoder = util.TextDecoder.create('utf-8');
        this.licenseSource.setItems(splitLicenseText(decoder.decodeToString(bytes)));
        this.loadedKind = kind;
      }
      this.viewerKind = kind;
      this.viewerOpen = true;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`read license file failed: ${err.message}`);
      try {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.toast_license_read_failed'), duration: 1200 });
      } catch (toastError) {
        console.error(`show toast failed: ${(toastError as BusinessError).message}`);
      }
    }
  }

  @Builder
  NavBack(label: Resource, hint: Resource, action: () => void) {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      Row({ space: 2 }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(16)
          .fontColor([this.accentColor])
        Text(label)
          .fontSize(14)
          .fontColor(this.accentColor)
      }
    }
    .height(40)
    .padding({ left: 8, right: 12 })
    .backgroundColor(Color.Transparent)
    .borderRadius(8)
    .hoverEffect(HoverEffect.Highlight)
    .accessibilityText(hint)
    .onClick(() => action())
  }

  @Builder
  DocButton(label: Resource, action: () => void) {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      Row({ space: 6 }) {
        Text(label)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.accentColor)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(14)
          .fontColor([this.accentColor])
      }
    }
    .constraintSize({ minHeight: 40 })
    .padding({ left: 0, right: 0 })
    .backgroundColor(Color.Transparent)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => action())
  }

  @Builder
  SectionHeader(index: number, title: ResourceStr, subtitle: ResourceStr) {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Row({ space: 8 }) {
        Column({ space: 2 }) {
          Text(title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.player_text'))
          Text(subtitle)
            .fontSize(12)
            .fontColor($r('app.color.player_text_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(16)
          .fontColor([$r('app.color.player_text_secondary')])
          .rotate({ angle: this.expanded === index ? 180 : 0 })
          .accessibilityLevel('no')
      }
      .width('100%')
    }
    .width('100%')
    .constraintSize({ minHeight: 60 })
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(Color.Transparent)
    .borderRadius(0)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      this.expanded = this.expanded === index ? -1 : index;
    })
  }

  @Builder
  ProjectInfo(name: string, copyright: string, url: string) {
    Column({ space: 2 }) {
      Text(name)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.player_text'))
        .width('100%')
      Text(copyright)
        .fontSize(12)
        .fontColor($r('app.color.player_text_secondary'))
        .width('100%')
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Text(url)
          .fontSize(12)
          .fontColor(this.accentColor)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
      .constraintSize({ minHeight: 40 })
      .padding({ left: 0, right: 0 })
      .backgroundColor(Color.Transparent)
      .hoverEffect(HoverEffect.Highlight)
      .accessibilityText(url)
      .onClick(() => {
        this.copyUrl(url);
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  TextBlock(label: Resource, body: string) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.player_text'))
        .width('100%')
      Text(body)
        .fontSize(12)
        .lineHeight(18)
        .fontColor($r('app.color.player_text_secondary'))
        .copyOption(CopyOptions.LocalDevice)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ProjectsSection() {
    Column({ space: 10 }) {
      Text($r('app.string.licenses_this_project'))
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.player_text'))
        .width('100%')
      this.ProjectInfo(APP_NAME, APP_COPYRIGHT, APP_REPO_URL)
      Text($r('app.string.licenses_upstream_project'))
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.player_text'))
        .width('100%')
        .margin({ top: 4 })
      this.ProjectInfo(RUFFLE_NAME, RUFFLE_COPYRIGHT, RUFFLE_URL)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  MitSection() {
    Column({ space: 10 }) {
      this.TextBlock($r('app.string.licenses_components'), this.componentText())
      this.TextBlock($r('app.string.licenses_copyright'), RUFFLE_COPYRIGHT)
      this.TextBlock($r('app.string.licenses_full_text'), MIT_LICENSE_TEXT)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ApacheSection() {
    Column({ space: 10 }) {
      this.TextBlock($r('app.string.licenses_components'), this.componentText())
      this.TextBlock($r('app.string.licenses_copyright'), RUFFLE_COPYRIGHT)
      this.TextBlock($r('app.string.licenses_full_text'), APACHE_LICENSE_TEXT)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ThirdPartySection() {
    Column({ space: 10 }) {
      this.TextBlock($r('app.string.licenses_note_label'), this.str($r('app.string.licenses_note_body')))
      this.DocButton($r('app.string.licenses_view_upstream'), () => this.openLicense(VIEWER_UPSTREAM))
      this.DocButton($r('app.string.licenses_view_supplement'), () => this.openLicense(VIEWER_SUPPLEMENT))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  LicenseViewer() {
    Column() {
      Row() {
        this.NavBack($r('app.string.licenses_list_title'), $r('app.string.a11y_licenses_back'), () => {
          this.viewerOpen = false;
        })
      }
      .width('100%')
      .padding({ left: 8, right: 16, top: 8 })

      Column({ space: 2 }) {
        Text(this.viewerKind === VIEWER_SUPPLEMENT ?
          $r('app.string.licenses_supplement_title') : 'Ruffle LICENSE.md')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.player_text'))
          .width('100%')
        Text(this.viewerKind === VIEWER_SUPPLEMENT ?
          $r('app.string.licenses_supplement_sub') : $r('app.string.licenses_upstream_sub'))
          .fontSize(12)
          .fontColor($r('app.color.player_text_secondary'))
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16, right: 16, top: 4, bottom: 8 })

      List() {
        LazyForEach(this.licenseSource, (chunk: string, index: number) => {
          ListItem() {
            Text(chunk)
              .fontSize(12)
              .lineHeight(18)
              .fontColor($r('app.color.player_text_secondary'))
              .copyOption(CopyOptions.LocalDevice)
              .width('100%')
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          }
        }, (chunk: string, index: number) => `lic:${index}`)
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
      .cachedCount(4)
    }
    .width('100%')
    .height('100%')
  }

  build() {
    if (this.viewerOpen) {
      this.LicenseViewer()
    } else {
      Scroll() {
        Column({ space: 12 }) {
          this.NavBack($r('app.string.row_about'), $r('app.string.a11y_about_back'), () => this.onBack())

          Column() {
            this.SectionHeader(SECTION_PROJECTS,
              $r('app.string.licenses_section_projects'), 'RFulash · Ruffle')
            if (this.expanded === SECTION_PROJECTS) {
              Divider()
                .color($r('app.color.player_divider'))
              this.ProjectsSection()
            }

            Divider()
              .color($r('app.color.player_divider'))
            this.SectionHeader(SECTION_MIT, 'MIT License', $r('app.string.licenses_section_mit_sub'))
            if (this.expanded === SECTION_MIT) {
              Divider()
                .color($r('app.color.player_divider'))
              this.MitSection()
            }

            Divider()
              .color($r('app.color.player_divider'))
            this.SectionHeader(SECTION_APACHE, 'Apache License 2.0', $r('app.string.licenses_section_apache_sub'))
            if (this.expanded === SECTION_APACHE) {
              Divider()
                .color($r('app.color.player_divider'))
              this.ApacheSection()
            }

            Divider()
              .color($r('app.color.player_divider'))
            this.SectionHeader(SECTION_THIRD_PARTY,
              $r('app.string.licenses_section_third'), $r('app.string.licenses_section_third_sub'))
            if (this.expanded === SECTION_THIRD_PARTY) {
              Divider()
                .color($r('app.color.player_divider'))
              this.ThirdPartySection()
            }
          }
          .width('100%')
          .backgroundColor($r('app.color.player_fill'))
          .borderRadius(15)
          .clip(true)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 24 })
        .alignItems(HorizontalAlign.Center)
      }
      .scrollBar(BarState.Auto)
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
    }
  }
}
