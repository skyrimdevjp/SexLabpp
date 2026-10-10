# SexLab P+（Apache 版フォーク）

Skyrim Special Edition 向けの成人向けアニメーションフレームワーク **SexLab P+** の非公式フォーク。

このフォークは **SkyShim のために作ったもの**。SkyShim で動かすことを前提に保守し、今後は SkyShim に特化していく。

上流の SexLab P+ は 2.18.1 の次のコミットで GPL-3.0 に変わった。このフォークは、**GPL に変わる直前の 2.18.1（Apache-2.0）を土台にして、GPL のコードを取り込まずに**保守と修正を続ける。

> これは非公式のフォークであり、SexLab P+ の作者（Scrab 氏ほか）や元の SexLab の作者（Ashal 氏）とは関係がない。不具合の報告を上流に送らないこと。

---

## 上流との違い

| 項目 | 内容 |
|---|---|
| 対象のローダー | SkyShim（SKSE64 でも動作するが保証しない） |
| 土台 | SexLab P+ 2.18.1（`SLP-Community/SexLabpp` のコミット `c340be27`、Apache-2.0） |
| CommonLib | **SkyShim と共通のもの**（CommonLibSSE-NG の GPL 化の直前 `e34246283`、MIT。SkyShim による 1.7.104 向けの追加を含む）。SE（1.5.97）用と AE（1.7.104）用の DLL を別々にビルドする |
| シーン UI | 外部の **SKSE Menu Framework（GPL-3.0）は不要**。Dear ImGui（MIT）を SexLabUtil.dll に組み込み、描画・入力・フォントを自前で処理する |
| 表情（MFG） | 外部の **MfgFix NG（GPL-3.0）は不要**。表情・口の開閉を滑らかに動かす処理を SexLabUtil.dll に内蔵した |
| 不具合の修正 | 家具オフセットの調整でステージがやり直しになる、Legacy のクライマックスが落ちる、関係のないアクターに精液エフェクトが付く、`CountCumFx()` の戻り値、プレイヤーから離したアクターが壁にめり込む、の 5 件を独自に修正 |
| 日本語訳 | `SexLab_JAPANESE.txt` を日本語化（上流では英語のコピー） |
| Rape Spell の内蔵 | SexLab Rape Spell（SE 版、Nexus SE mod 12302）を `SexLab.esm` とスクリプトに取り込んだ。`SexLabRapeSpell.esp` は不要で、**一緒に入れてはいけない**。詳しくは下の「Rape Spell の内蔵」 |
| 精液エフェクトの選び分け | 精液エフェクトのセットを、受ける側の種族と性別で選べるようにした（設定ファイル `Data\SKSE\SexLab\CumFx\*.yaml`）。設定ファイルが無ければ今までどおり。書き方は [精液エフェクトの設定ファイル.md](精液エフェクトの設定ファイル.md) |

各修正の症状・原因・修正内容と、GPL のコードを含まないことの確認結果は [GPL非依存の確認と修正記録.md](GPL非依存の確認と修正記録.md) にまとめてある。

### Rape Spell の内蔵

- 元：SexLab Rape Spell の SE 版の `SexLabRapeSpell.esp`（日本語化ずみのもの）と、そのスクリプト 12 個（日本語のコメント付き）。再配布と改変は作者の許可を確認ずみ。
- レコード 82 個を Spriggit の YAML（`res/SexLab.esm`）に移した。FormID は **元の ID + 0x100000**（例：クエスト `SexLabRapeSpell` は `000D62` → `100D62`）。SexLab.esm の既存の ID（最大 `0D64CA`）とは重ならない。
- 元の esp にあったバニラの `IronDagger`（Skyrim.esm `01397E`）の上書きは、名前を日本語にするだけのものなので取り込んでいない。
- スクリプトは `dist/Source/Scripts/sslrapespell*.psc`、`sslrs*.psc`。変更は 1 か所だけ：SexLab Aroused の興奮度を `slaFrameworkScr` の関数ではなく、派閥 `sla_Arousal`（SexLabAroused.esm `03FC36`）の位階から読む（ビルドが Aroused のソースに依存しないようにするため。Aroused が無ければ今までどおり 0）。
- MCM の文字列は `SexLab_*.txt` の末尾に足した（日本語は SE 版の訳、ほかの言語は LE 版の英語の原文）。`translate.py` は英語を各言語にコピーするので、実行すると日本語訳が消える。
- 元の MOD（`SexLabRapeSpell.esp` と `sslrapespell*.pex`、`sslrs*.pex`）は無効にすること。FormID が変わるので、元の MOD を使っていたセーブとの互換性は無い。

---

## 必要なもの（プレイ環境）

| 必要なもの | 備考 |
|---|---|
| Skyrim Special Edition | **1.5.97**（SE 用の DLL）。**1.7.104** は対応作業中（AE 用の DLL はビルドできるが、1.7.104 での確認はまだ）。VR は対象外 |
| **SkyShim**（推奨）または SKSE64 | 下の「ローダーについて」を参照 |
| Address Library for SKSE Plugins | SexLabUtil.dll が使う |
| PapyrusUtil SE | |
| SkyUI | MCM のため |
| RaceMenu | 上流の SexLab P+ と同じく推奨。MCM の要件一覧で導入状況を確認できる |
| Procedural Penis Animations | 推奨（上流と同じ） |
| VRIK Player Avatar | VR の場合のみ |

**SKSE Menu Framework と MfgFix NG は不要。** シーン UI と表情の処理は SexLabUtil.dll に内蔵されている。

### ローダーについて

- **SkyShim**：このフォークの対象。動作の確認と不具合の修正は SkyShim を基準に行う。
- **SKSE64**：動作することは確認している。ただし**動作は保証しない**。
  - 今後このフォークは SkyShim に特化していくため、SKSE64 で動かなくなる変更が入ることがある。
  - SKSE64 だけで起きる不具合には対応しないことがある。

- アニメーションパックは、上流の SexLab P+ 2.18.1 と同じ形式（`SKSE\SexLab\Registry\*.slr`）のものを使う。SLAL の形式のパック（`SLAnims\json\*.json`）も、DLL が起動のときに直接読む（変換は要らない）。SexLab Scene Builder（Apache-2.0）で `.slr` に変換して使うこともできる。詳しくは [ビルドと配布物の作成手順.md](ビルドと配布物の作成手順.md) の 9 章。
- 上流の SexLab P+ や元の SexLab 1.6x と一緒に入れないこと（どちらか一方だけを入れる）。
- セーブデータの互換性は確認していない。新しく始めるのが安全。

---

## ビルド

詳しい手順は [ビルドと配布物の作成手順.md](ビルドと配布物の作成手順.md) を参照。DLL だけなら次の手順でビルドできる。

```powershell
git clone <このリポジトリ>
cd SexLabpp
xmake f -y -m release -p windows -a x64 --vs=2022 --skyrim_runtime=se --build_papyrus=n --build_spriggit=n --build_assets=y   # AE 用は --skyrim_runtime=ae
xmake build SexLabUtil
xmake install -o <出力先>
```

- 必要なもの：Visual Studio 2022（C++）、xmake 3.x、Python 3
- Papyrus スクリプト（`.pex`）と `SexLab.esm` も含めた全体をビルドするには、Papyrus コンパイラ、依存 MOD の Papyrus ソース、Spriggit CLI が必要。詳しくは上の手順書を参照。

---

## ライセンス

このリポジトリには、ライセンスの異なる部分が含まれている。

| 部分 | ライセンス |
|---|---|
| ネイティブコード（`src/`）と、上流の SexLab P+ に由来する部分 | Apache License 2.0（[LICENSE](LICENSE)） |
| 元の SexLab（Ashal 作）から派生した部分（Papyrus スクリプト、素材など） | [Readme - SexLab Framework.txt](Readme%20-%20SexLab%20Framework.txt) の配布条件 |
| `lib/CommonLibSSE-NG`（SkyShim と共通。元は CommonLibSSE-NG `e34246283`） | MIT（`lib/CommonLibSSE-NG/LICENSE`） |
| Dear ImGui（ビルド時に xmake で取得して組み込む） | MIT |
| `dist/SKSE/SexLab/Fonts/fa-solid-900.ttf`（Font Awesome Free） | SIL OFL 1.1（`dist/SKSE/SexLab/Fonts/FontAwesome-LICENSE.txt`） |
| `src/Registry/Util/RayCast*` | 外部のコードを元にしている（`src/Registry/Util/RayCast/Credits.md` を参照） |

- 上流から変更したファイルと変更内容は、[GPL非依存の確認と修正記録.md](GPL非依存の確認と修正記録.md) に記録している。

---

## このリポジトリでの決まり

- 上流 SexLab P+ の `0667d089`（GPL 化）以降のコミットは、マージも cherry-pick もしない。中身を参考に書き写すこともしない。
- CommonLib は SkyShim と共通のものを使う。CommonLibSSE-NG の `cf24ab81c`（GPL 化）以降のコードは取り込まない。
- シーン UI は内蔵のホスト（`src/Thread/Interface/UI/MenuHost.*`）で動かす。外部のメニューフレームワークのヘッダーや DLL には戻さない。
- 動作の確認は SkyShim で行う。SKSE64 での動作を保つための変更は必須としない。
- 新しいライブラリや素材を入れるときは、ライセンスを確かめ、上の表と記録文書に書き足す。
- 修正を加えたら、記録文書に症状・原因・修正・変更箇所を書き足す。

---

## 謝辞

- **SexLab**：Ashal 氏
- **SexLab P+**：Scrab 氏と SLP-Community の協力者の方々（2.18.1 までの Apache-2.0 版）
- **CommonLibSSE-NG**：Ryan McKenzie 氏（CommonLibSSE）、CharmedBaryon 氏、alandtse 氏ほか
- **Dear ImGui**：Omar Cornut 氏ほか
- **Font Awesome Free**：Fonticons, Inc.
