# GPL 非依存の確認と修正記録

この文書は、作業ブランチ `base-2.18.1-apache` について、次の 3 点を記録したもの。

1. GPL でライセンスされたコードを含んでいないことの確認結果
2. 上流（SexLab P+）の GPL 化以降のコードを取り込まずに行った修正の項目と内容


---

## 1. 結論

- このブランチの**土台**（SexLab P+ 2.18.1）は **Apache-2.0**。使っている **CommonLib** は、SkyShim と共通のもの（CommonLibSSE-NG の GPL 化の直前のコミット `e34246283`、**MIT**）。どちらも GPL 化より前の版に固定してある（6.7）。
- 上流が GPL 化した**後**のコードは、取り込んでいない。
- このブランチで加えた修正（5 項目）は、2.18.1 のコードを読んで原因を調べ、**独自に実装した**もの。
- ブランチ本体、CommonLib、追加した修正の中に、GPL の条文や SPDX の GPL 表記は見つからなかった（4 章）。
- GPL-3.0 のリポジトリから持ってきたファイル `lib/ImGui/SKSEMenuFramework.h` は**削除した**。代わりに、Dear ImGui（MIT）を DLL に直接組み込む UI ホストを独自に実装した（6.6）。これで、外部の GPL の DLL（SKSEMenuFramework.dll）への依存も、ビルド時と実行時の両方でなくなった。


---

## 2. 土台にした版

| 項目 | 値 |
|---|---|
| リポジトリ | `https://github.com/SLP-Community/SexLabpp` |
| 作業ブランチ | `base-2.18.1-apache` |
| 土台のコミット | `c340be27f1e1c8667bbac9f2b4c8afc45aaa9c6a`（2026-08-05、「vers incr 2.18.1」） |
| 土台のライセンス | Apache License 2.0（ルートの `LICENSE`） |
| CommonLib（`lib/CommonLibSSE-NG`、リポジトリに同梱） | SkyShim の `third_party/CommonLibSSE-NG-MIT` の写し（SkyShim のコミット `ccc53bd` 時点）。元は CommonLibSSE-NG の `e34246283a75fdd7009108476f0c646038f71f3c`（2026-08-20） |
| CommonLib のライセンス | MIT（`lib/CommonLibSSE-NG/LICENSE`。元のコミットのルートには `LICENSE` だけがあり、`COPYING` はない） |
| CommonLib への追加 | SkyShim による追加 2 件と、このリポジトリによる追加 3 件（6.7）。どれも自作、または MIT 版の CommonLib から持ってきたもの |

### 2.1 GPL に変わった時期（この版を選んだ理由）

| 部品 | GPL ではない最後の版 | GPL に変わったコミット |
|---|---|---|
| SexLab P+ 本体 | `c340be27`（2.18.1） | `0667d089`（2026-09-29、「feat: Update skyrim support/Commonlib, switch to GPL-3」）。親コミットが `c340be27` |
| CommonLibSSE-NG | `e34246283`（2026-08-20） | `cf24ab81c`（2026-08-20、「Relicense to GPL-3.0-or-later」） |

- SexLab P+ の GPL 化コミット `0667d089` の**直前**が `c340be27` なので、2.18.1 は GPL ではない最後の版にあたる。
- 使っている CommonLib の元 `e34246283` は、CommonLib の GPL 化コミット `cf24ab81c` の**直前**（`cf24ab81c` から見て 1 つ前の親）。GitHub の比較で確認した。
- 2.18.1 が元々使っていた CommonLib `e60c123`（v4.39.2、MIT）は、6.7 で SkyShim と共通のものに置き換えた。

---

## 3. 依存ライブラリ

xmake が取得するライブラリ。ライセンスは各プロジェクトが一般に公開しているもので、版ごとの確認まではしていない。

| ライブラリ | ライセンス | 備考 |
|---|---|---|
| yaml-cpp / magic_enum / glaze / simpleini / glm | MIT | SexLab P+ 本体が使う |
| spdlog / rsm-binary-io | MIT | CommonLib が使う |
| eigen | MPL-2.0 | ファイル単位のコピーレフト。改変しなければ、利用側のコードには影響しない |
| Dear ImGui v1.91.9b（DX11 バックエンド） | MIT | 6.6 で追加。xmake の公式パッケージ（`ocornut/imgui` のタグ `v1.91.9b`）からビルドして DLL に組み込む |

### 3.1 同梱する素材

| 素材 | 入手元 | ライセンス | 備考 |
|---|---|---|---|
| `dist/SKSE/SexLab/Fonts/fa-solid-900.ttf` | Font Awesome Free（`FortAwesome/Font-Awesome` の `6.x` ブランチ、コミット `840c215f8`、2025-08-21） | フォントは SIL OFL 1.1 | 6.6 で追加。UI のアイコン用。ライセンス文を `FontAwesome-LICENSE.txt` として同じフォルダに置いた |

---

## 4. GPL 表記の検査

次の範囲で、GPL の条文と SPDX の GPL 表記を検索した。

2026-10-07 に、作業ツリー全体（6.7 で CommonLib を置き換えた後）で検索した。

| 対象 | 検索した内容 | 結果 |
|---|---|---|
| 本体（`lib/`、`build/`、`.xmake/`、`.md` を除く） | `GNU General Public` / `GNU Lesser Public` / `GPL-2` / `GPL-3` / `SPDX-License-Identifier` | 0 件 |
| CommonLib（`lib/CommonLibSSE-NG`） | `GNU General Public` / `SPDX-License-Identifier: GPL` | 0 件 |

同じ検査をやり直すには、リポジトリのルートで次を実行する（Git Bash）。

```sh
grep -rIl -i -E "GNU (General|Lesser) Public|GPL-?[23]|SPDX-License-Identifier" --exclude-dir=.git --exclude-dir=lib --exclude-dir=build --exclude-dir=.xmake --exclude='*.md' .
grep -rIl -i -E "GNU General Public|SPDX-License-Identifier: *GPL" lib/CommonLibSSE-NG
```

> この検査で分かるのは「ファイルに GPL の表記がないこと」まで。ライセンス表記を持たない状態で GPL のコードが紛れ込んでいる可能性までは否定できない。実際に `lib/ImGui/SKSEMenuFramework.h` はライセンス表記を持たない GPL 由来のファイルだったため、検査とは別に入手元を調べて見つけ、削除した（6.6、7.1）。

---

## 5. 修正の進め方

上流のコードを取り込まないために、次の決まりで作業した。

1. **土台**：作業ブランチは `c340be27`（Apache-2.0）から作り、CommonLib は `e60c123`（MIT）に固定した。
2. **上流の修正の扱い**：2.18.1 以降に上流で直された不具合は、**症状だけ**を手がかりにした。
   - 修正コミットのうち、そのコミット時点の `LICENSE` が Apache-2.0 のものは、何が悪かったのかを把握する目的で、メッセージと差分の一部を見た。
   - **GPL 化の後に書かれたコミット**（例：`010e8dc7`「fix: various enjoyment issues」）は、変更されたファイル名の一覧より先は見ていない。
   - 位置ずらしの修正で上流が新しく作った C++ のコード（`b7b525e0` の `src/Util/World.h`）は、内容を見ていない。
3. **原因の特定と実装**：2.18.1 のコードを自分で読んで原因を特定し、修正は独自に設計・実装した。上流のコードはコピーも移植もしていない。
4. **新しいコードが使うもの**：このブランチに元からあるコード（Apache-2.0）、CommonLibSSE-NG（MIT）、glm（MIT）だけを使った。

---

## 6. 修正項目

| # | 修正項目 | 変更したファイル |
|---|---|---|
| 1 | 家具オフセットの調整でステージがやり直しになる | `src/Thread/Thread.cpp` |
| 2 | Legacy のクライマックス設定で最終ステージのクライマックスが落ちる | `dist/Source/Scripts/sslThreadModel.psc`、`dist/Source/Scripts/sslActorAlias.psc` |
| 3 | 行為に参加していないアクターにも精液エフェクトが付く | `dist/Source/Scripts/sslThreadModel.psc` |
| 4 | `CountCumFx()` の戻り値が間違っている | `dist/Source/Scripts/sslActorLibrary.psc` |
| 5 | プレイヤーから離したアクターが壁や地形にめり込む | `src/Papyrus/sslThreadModel.cpp`、`src/Papyrus/sslThreadModel.h`、`dist/Source/Scripts/sslThreadModel.psc` |
| 6 | GPL 由来の `SKSEMenuFramework.h` をやめ、UI ホストを独自実装 | 新規 `src/Thread/Interface/UI/MenuHost.h`、`src/Thread/Interface/UI/MenuHost.cpp`。変更 `xmake.lua`、`xmake-requires.lock`、`src/main.cpp`、`src/Thread/Interface/UI/Scale.h`、`UI/Theme.h`、`UI/Window.h`、`Elements/EnjBarsOverlay.h`、`.gitattributes`。削除 `lib/ImGui/`。追加 `dist/SKSE/SexLab/Fonts/` |
| 7 | CommonLib を SkyShim と共通のもの（MIT）に置き換え | `lib/CommonLibSSE-NG` を置き換え、`.gitmodules` を削除、`xmake.lua`、SexLab のソース 13 ファイル（6.7） |
| 8 | 精液エフェクトのセットを種族と性別で選べるようにした（新機能） | 新規 `src/Registry/Define/CumFx.h/.cpp`。変更 `src/Registry/Library.h/.cpp`、`Library_SaveLoad.cpp`、`src/Papyrus/sslLibrary/sslActorLibrary.h/.cpp`、`dist/Source/Scripts/sslActorLibrary.psc`（6.8） |

### 6.1 家具オフセットの調整でステージがやり直しになる

- **症状**：シーン中に UI で家具（シーン全体）のオフセットを変えると、ステージが最初から再生し直され、ステージのタイマーも戻る。
- **原因**：`Thread::Instance::OffsetAdjustSet()` で、家具オフセットを変えたときの処理が `AdvanceScene(activeStage)` を呼んでいた。`AdvanceScene()` はタイマーを止め、全員のアニメーションを再送する。
- **修正**：家具オフセットで変わるのは基準座標だけなので、`AdvanceScene()` を呼ぶのをやめ、全アクターに `ReassertPlacement(i, true)` で位置を置き直すようにした。同じファイルの `OffsetAdjustReset()` が元から使っている方法に合わせた。
- **変更箇所**：`src/Thread/Thread.cpp`（`OffsetAdjustSet` の家具オフセットの分岐）

### 6.2 Legacy のクライマックス設定で最終ステージのクライマックスが落ちる

- **症状**：MCM のクライマックスの方式が Legacy のとき、最終ステージ（シンク）に入ってもオーガズムが起きないことがある。
- **原因**：
  - Legacy の場合、最終ステージに入ると `TriggerOrgasm()` が ModEvent `SSL_ORGASM_Thread<tid>` を送り、各アクターは `OnOrgasm` → `DoOrgasm()` を実行する。
  - このとき `Forced` が付いていないので、「シーン開始、または前回のオーガズムから 10 秒（男性は 20 秒）」の待ち時間（`_LastOrgasm`）にかかる。待ち時間の中だと、何も起きずに処理が捨てられる。
  - そのため、早く最終ステージに着いたシーンや、直前に Enjoyment で個別にオーガズムしたアクターでは、ステージによるクライマックスが落ちていた。
- **修正**：
  - `sslThreadModel.psc`：Legacy で最終ステージに入ったときは、`SendModEvent("SSL_ORGASM_Thread" + tid, "", 1.0)` を送る。`numArg` の 1.0 が「ステージによるクライマックス」という印になる。
  - `sslActorAlias.psc`：`Animating` 状態の `OnOrgasm` で、`numArg > 0` なら `_CanOrgasm`（`DisableOrgasm()` の指定）を確かめたうえで `DoOrgasm(true)` を呼び、待ち時間を飛ばす。それ以外は、これまでどおり `DoOrgasm()`。
  - 他の MOD が呼ぶ公開関数 `TriggerOrgasm()` の動きは変えていない。
- **変更箇所**：`sslThreadModel.psc`（`Animating` 状態の `PlayNextImpl`）、`sslActorAlias.psc`（`Animating` 状態の `OnOrgasm`）

### 6.3 行為に参加していないアクターにも精液エフェクトが付く

- **症状**：3 人以上のシーンで、オーガズムしたアクターと接触していないアクターにも精液エフェクトが付く。
- **原因**：
  - `ApplyCumFX()` は、オーガズムしたアクターと各アクターの組み合わせごとに接触の種類を調べる。何も見つからない組み合わせについては、シーン全体のタグ（`IsOral` / `IsVaginal` / `IsAnal`）で代わりに判断していた。
  - シーンのタグは組み合わせではなくシーン全体のことなので、傍観者にも当てはまってしまう。
  - さらに物理判定が使えないとき、`ListDetectedInteractionsInternal()` は代わりの値（pAnal だけ）を返す。この値は調べている種類に含まれないので、やはりタグの判断に回ってしまう。
- **修正**：タグで代わりに判断するのを、次の 2 つを両方満たす場合だけに絞った。
  - 物理判定が使えない（`!IsInteractionRegistered()`）
  - 相手が 1 人に決まる 2 人のシーン（`_Positions.Length == 2`）
  - 物理判定が使える場合は、「接触なし」をそのまま傍観者として扱う。
- **残る影響**：物理判定が使えない 3 人以上のシーンでは、精液エフェクトは付かない。誤って付けるより、付けない側に倒した。
- **変更箇所**：`sslThreadModel.psc`（`ApplyCumFX`）

### 6.4 `CountCumFx()` の戻り値が間違っている

- **症状**：公開 API の `sslActorLibrary.CountCumFx()` が 0 か 1 しか返さない。`FX_ALL` を渡すと常に 0。
- **原因**：
  - 精液エフェクトの層の数は、StorageUtil のキー `SexLabActiveLayer<種類>` の**値**として保存されている。
  - ところが `CountObjIntValuePrefix` は、そのプレフィックスに一致する**キーの個数**を数える。
  - `FX_ALL`（-1）のときはプレフィックスが `SexLabActiveLayer-1` になり、どのキーにも一致しない。
- **修正**：種類を指定されたときは `StorageUtil.GetIntValue` で保存されている値を返す。`FX_ALL` のときは `FX_VAGINAL`（0）から `FX_ORAL`（2）までの値を順に足して返す。
- **変更箇所**：`sslActorLibrary.psc`（`CountCumFx`）

### 6.5 プレイヤーから離したアクターが壁や地形にめり込む

- **症状**：シーンの終わりやシーンの移動のとき、プレイヤーに近すぎるアクターをずらす処理で、アクターが壁や家具の中、段差の上や下に置かれることがある。
- **原因**：Papyrus の `MoveActorsAwayFromPlayer()` が、次のように移動先を確かめずに動かしていた。
  - X/Y 方向に決まった量（35）だけ `SetPosition` でずらす。障害物も地面も確認しない。Z 座標は元のまま。
  - ずらす向きはプレイヤーの位置と関係ないので、かえってプレイヤーに近づくことがある。
  - 5 人目以降は実際には動かない。
  - `MovePlayer` が指定されたときは、プレイヤーを X 方向に 70 だけ無条件に動かす。
- **修正**：C++ の native 関数 `SeparateFromPlayer(Actor[] akPositions, bool abMovePlayer)` を新しく作り、Papyrus の `MoveActorsAwayFromPlayer()` はこれを呼ぶだけにした。関数名と引数はそのままなので、呼び出し元は変更不要。
  - 対象：プレイヤーから 50 未満にいるアクター（`MovePlayer` のときはプレイヤー自身。1 回だけ）
  - 探し方：プレイヤーから離れる向きを基準に、0°、±45°、±90°、±135°、180° の 8 方向を、距離 60 と 90 で順に試す
  - 採用する条件（両方を満たすこと。レイキャストはブランチに元からある `Raycast::hkpCastRay` を使い、シーンの参加者とプレイヤーの 3D は当たり判定から外す）：
    1. 高さ 50 で横向きにレイを飛ばし、移動先までに障害物がない
    2. 移動先の真上 +60 から真下 -60 までレイを飛ばし、地面に当たる。当たった高さを移動先の Z 座標にする
  - 条件に合う場所が見つからなければ、**動かさずにその場に残し**、ログに記録する（壁の中に入れるよりはよい）
  - 移動は `SetPosition` → `Update3DPosition`。native 関数はメインスレッドで動くように登録した（`REGISTERFUNC(..., false)`）
- **変更箇所**：`src/Papyrus/sslThreadModel.cpp`（`FindSeparationSpot` と `SeparateFromPlayer` を追加）、`src/Papyrus/sslThreadModel.h`（宣言と登録）、`dist/Source/Scripts/sslThreadModel.psc`（`MoveActorsAwayFromPlayer` を置き換え、native の宣言を追加）

### 6.6 GPL 由来の `SKSEMenuFramework.h` をやめ、UI ホストを独自実装

- **問題**：
  - シーン中の UI（SceneHUD、家具選択、ステージ選択、オフセット調整パネル、速度表示、Enjoyment バー）は、`lib/ImGui/SKSEMenuFramework.h` を通して外部の DLL「SKSE Menu Framework」の ImGui を呼んでいた。
  - このヘッダーの入手元 `QTR-Modding/SKSE-Menu-Framework-3` のライセンスは **GPL-3.0**（ヘッダー自体にはライセンス表記がない）。
  - 実行時も、GPL の DLL（SKSEMenuFramework.dll）が入っていないと UI が動かなかった。
- **方針**：
  - Dear ImGui（MIT）を DLL に直接組み込み、描画・入力・フォント・ウィンドウ管理を自前で行う「UI ホスト」を作る。
  - UI 側のコード（`src/Thread/Interface/` 以下、約 4,500 行）はなるべく変えない。そのため、UI 側が使っている呼び出しの形（`ImGuiMCP::` / `FontAwesome::` / `SKSEMenuFramework::` の名前空間）を、本物の ImGui に対応づける薄い互換層を独自に書く。
- **元のヘッダーの扱い**：
  - 元のヘッダーの中身は参照していない。確認したのは先頭の 15 行（`GetModuleHandleW(L"SKSEMenuFramework")` で DLL を探す部分）だけ。
  - 互換層は、このブランチの UI のコード（Apache-2.0）での**呼び出し方**と、Dear ImGui（MIT）の公開 API だけを元に設計した。
- **実装内容**：
  - **互換層**（`MenuHost.h`）
    - `ImGuiMCP`：Dear ImGui の型、列挙値、関数をそのまま公開する（`using namespace ::ImGui` と `using enum`）。UI 側がポインタで受け取る `GetIO()` / `GetStyle()` だけは、ポインタを返す形で用意した。
    - `ImGuiMCP::ImDrawListManager::〜(drawList, ...)`、`ImFontManger::CalcTextSizeA(font, ...)`、`ImGuiViewportManager::GetCenter(vp)`：描画リスト、フォント、ビューポートのメンバー関数を、第 1 引数で対象を受け取る関数として包んだ。
    - `FontAwesome::Pop()`：`ImGui::PopFont()`
    - `SKSEMenuFramework`：`IsInstalled()`（自前のホストなので常に true）、`AddWindow(描画関数, 入力をふさぐか)`（`IsOpen` / `BlockUserInput` を持つ `WindowInterface` を返す）、`PushFont(名前)`
  - **描画**（`MenuHost.cpp`）
    - `kDataLoaded` で、CommonLib の `RE::BSGraphics::Renderer::GetCurrentRenderWindow()` からスワップチェーンを取り出し、その vtable の `Present`（番号 8）をフックする。
    - 最初の `Present` で、スワップチェーンのデバイスから ImGui と DX11 バックエンドを初期化する。
    - 毎フレーム、開いているウィンドウがあれば ImGui のフレームを作り、各ウィンドウの描画関数を呼び、バックバッファに描いてから元の `Present` を呼ぶ。
    - ゲームが設定していた描画先は、描画の前後で退避して元に戻す。
  - **入力**
    - `BSInputDeviceManager` のイベント（`InputEvent`）を受け取り、ImGui の入力イベントに変換する。
      - キーボード：DirectInput のスキャンコードを `ImGuiKey` に変換し、修飾キー（Ctrl / Shift / Alt）も渡す
      - 文字入力：`CharEvent`
      - マウス：移動量を積み上げて座標にする。ボタンとホイールも渡す
    - キーボードと文字入力は、ウィンドウが開いている間は常に渡す。マウスは、入力をふさぐウィンドウが開いている間だけ渡す。
    - 入力をふさぐウィンドウが開いている間は、`ControlMap::ToggleControls` でゲームの操作（移動、視点、起動、メニュー、視点切替、戦闘、スニーク、ホイールズーム、ジャンプ）を止め、ImGui のカーソルを表示する。
    - 止めるのは、その時点で有効だった操作だけにしてある（他の MOD が止めた操作を勝手に戻さないため）。
    - 操作の切り替えはメインスレッドで行う（SKSE のタスクインターフェース経由）。
  - **フォント**
    - 本文のフォント：`Data\SKSE\SexLab\Fonts\ui.ttf` があればそれを使う。なければ Windows の Segoe UI、それもなければ ImGui の内蔵フォント。
    - 同じフォルダにある他の `.ttf` / `.otf` は、ファイル名（拡張子なし）で登録し、`PushFont(名前)` で使えるようにする。
    - アイコン用に Font Awesome Free の `fa-solid-900.ttf`（SIL OFL 1.1）を `dist/SKSE/SexLab/Fonts/` に同梱した（3.1）。
    - フォントは 26px で読み込む。UI 側は `SetWindowFontScale` で縮小して使う。
- **ビルド設定**（`xmake.lua`）
  - `add_requires("imgui v1.91.9b", { system = false, configs = { dx11 = true } })` を追加し、`d3d11` / `dxgi` / `d3dcompiler` をリンクする。
  - `lib/ImGui` へのインクルードパスを削除した。
  - `system = false` は、xmake が vcpkg を探しに行って失敗するのを避けるため。
  - ImGui は 1.92 でフォントの仕組みが大きく変わったので、UI 側の書き方（`SetWindowFontScale` / `ImFont::CalcTextSizeA`）に合う 1.91 系に固定した。
- **UI 側の変更**：インクルードを `SKSEMenuFramework.h` から `Thread/Interface/UI/MenuHost.h` に変えただけ（4 ファイル）。`main.cpp` の `kDataLoaded` で `MenuHost::Install()` を呼ぶ。
- **Papyrus 側の要件チェック**：
  - `sslSystemConfig.CheckSystem()` は、SKSE Menu Framework がないと「必須の MOD がない」としてフレームワークのインストールを止めていた。
  - UI は SexLabUtil.dll に内蔵したので、このチェックを外した。
  - `CheckSystemPart("SKSEMenuFramework")` は `SexLabUtil` の確認で代用する。
  - MCM の要件一覧の表示名は「Scene UI (SexLabUtil.dll)」に変えた（`sslConfigMenu.psc`）。
- **削除**：`lib/ImGui/SKSEMenuFramework.h`、`lib/ImGui/_source`、`.gitattributes` の該当行
- **既知の制限**：
  - ゲームパッドでの UI 操作には対応していない。
  - マウスの移動速度は、DirectInput の移動量をそのまま使っている。
  - `SceneHUD::Register` に残っている「SKSE Menu Framework not installed」の警告は、`IsInstalled()` が常に true なので出ることはない。

### 6.7 CommonLib を SkyShim と共通のものに置き換え

- **目的**：
  - このフォークは SkyShim のためのもの。SkyShim は Skyrim 1.7.104 で動くように、MIT 版の CommonLib に独自の追加をしている（アドレスライブラリの形式 5 の読み込み、`SkyrimVM` の配置）。
  - CommonLib を SkyShim と共通にして、1.7.104 への対応を 1 か所で扱えるようにする。
  - 元の CommonLib `e60c123`（v4.39.2）は、1.7.x のアドレスライブラリ（形式 5）を読めず、1.7.104 では起動時に止まる。
- **置き換えたもの**：
  - `lib/CommonLibSSE-NG` の中身を、SkyShim の `third_party/CommonLibSSE-NG-MIT` の写しにした。元は CommonLibSSE-NG の `e34246283`（GPL 化の直前、MIT）。
  - サブモジュールをやめて、リポジトリに同梱する形にした（`.gitmodules` を削除）。OpenVR（VR 用）は含まれない。
- **2 つの CommonLib の作りの違い**：
  - 元の CommonLib（NG）は、1 つの DLL が実行中に SE / AE / VR を見分ける。
  - SkyShim の CommonLib は、ビルドのときに SE 用か AE 用かを決める（`SKYRIM_SUPPORT_AE`）。
  - そのため、SE（1.5.97）用と AE（1.7.104）用の DLL を別々にビルドする。VR は対象から外した（SkyShim の対象外）。
- **CommonLib への追加**：

  | 追加 | 誰が | 内容 |
  |---|---|---|
  | `include/REL/ID.h` | SkyShim | アドレスライブラリの形式 5（1.7.x）の読み込み |
  | `include/RE/S/SkyrimVM.h` | SkyShim | 1.6 以降の `impl` の位置（1.7.104 の実機で確認ずみ） |
  | `include/RE/A/Actor.h` | このリポジトリ | NG と同じ名前の取り出し口 `AsMagicTarget()` / `AsActorValueOwner()` / `AsActorState()`。この版の `Actor` はこれらを直接継承しているので、`this` を返すだけ |
  | `include/RE/N/NiNode.h` | このリポジトリ | NG と同じ名前の取り出し口 `GetChildren()`（`children` を返すだけ） |
  | `include/RE/B/BSSynchronizedClipGenerator.h`（と `RE/Skyrim.h` への登録） | このリポジトリ | この版に無いので、元の CommonLib `e60c123`（MIT）から持ってきた |

  追加した箇所には「Skyshim による追加」「SexLabpp による追加」のコメントを付けた。
- **SexLab 側の書き換え**（実行中に版を見分ける書き方を、ビルド時に決める書き方に変えた）：
  - `REL::VariantID(SE, AE, VR)` / `REL::RelocationID(SE, AE)` → `RELOCATION_ID(SE, AE)`。`REL::VariantOffset(SE, AE, VR)` → `OFFSET(SE, AE)`（`PCH.h` に元からある、ビルド時に選ぶ書き方）
    - `Thread/Hooks.cpp`、`Thread/NiNode/NiUpdate.cpp`、`Thread/ThreadAnimation.cpp`、`Registry/Util/RayCast/Offsets.h`
  - `REL::Module::IsVR()` の分岐を外した（VR 用の値を削除）
    - `Thread/Hooks.cpp`、`Thread/NiNode/Legacy/LegacyNiUpdate.cpp`、`Util/Misc.h`
  - `GetActorRuntimeData().X` → `X`、`(animation graph manager)->GetRuntimeData()` → `*graphManager`、`PlayerCamera::GetSingleton()->GetRuntimeData()` → `*PlayerCamera::GetSingleton()`
    - `Papyrus/sslLibrary/sslActorLibrary.cpp`、`Papyrus/sslThreadModel.cpp`、`Registry/Util/RayCast/RayCast.cpp`、`Thread/Collision/CollisionHandler.cpp`、`Thread/ThreadAnimation.cpp`
  - `GetSlotMask().underlying()` → `std::to_underlying(GetSlotMask())`（この版は列挙型をそのまま返す）
    - `Papyrus/sslLibrary/sslActorLibrary.cpp`、`Papyrus/sslThreadModel.cpp`
  - `RE::DefaultObjectID::kKeywordVampire` → `RE::DEFAULT_OBJECT::kKeywordVampire`（`Registry/Define/Fragment.cpp`）
  - `hkStringPtr::kManaged` を直接使っていた所を `hkStringPtr::data()` に変えた（同じ処理。`Thread/ThreadAnimation.cpp`）
  - UI ホストの `ControlMap::GetControlsState()` を、`enabledControls` メンバーを読む形に変えた（`Thread/Interface/UI/MenuHost.cpp`）
- **ビルド設定**（`xmake.lua`）：
  - CommonLib のターゲットとルールの名前を `commonlibsse-ng` から `commonlibsse` に変えた。
  - `add_requireconfs("*", { system = false })` を加え、vcpkg を探しに行かないようにした（vcpkg は不要になった）。
  - この CommonLib は `Windows.h` を読み込むので、`NOMINMAX` を定義した。
  - ゲームの版は `xmake f --skyrim_runtime=se|ae|vr` で選ぶ（既定 `se`、`vr` はまだ止める）。CommonLib の `skyrim_ae` はこれから自動で決まる。
  - ビルド用のフォルダは版ごとに `build/<版>` へ自動で切り替わり、版ごとの DLL・中間ファイルが混ざらない。DLL は `dist/` へコピーしない（`dist/` は版に共通の素材の置き場所）。
  - 既定のインストール先は `SL-Dev-<SE|AE>`、`xmake pack` のファイル名の末尾は ` - SE` / ` - AE`。
- **結果**：
  - SE（1.5.97）用のビルドは、警告 0・エラー 0 で通る。出力される DLL は、1.5.97 用の入口（`SKSEPlugin_Query` / `SKSEPlugin_Load`）を持つ。
  - AE（1.7.104）用のビルドも、追加の修正なしで警告 0・エラー 0 で通る。DLL は AE 用の入口（`SKSEPlugin_Version` / `SKSEPlugin_Load`）を持つ。
  - 1.7.104 での割り込み先・構造体の配置の確認は、まだ（8 章）。

### 6.8 精液エフェクトのセットを、アクターの種族と性別で選べるようにした（新機能）

- **目的**：精液エフェクト（CumFx）のテクスチャのセットを、受ける側のアクターの種族と性別で選び分ける。既存の API（`PickRandomFxSet(FxType)`）とテクスチャの置き方は変えない。
- **出どころ**：ユーザーが示した仕様に沿って、2.18.1 のコードを土台に自作した。上流の GPL 化後のコード（精液エフェクトの設定の機能）は見ていないし、取り込んでいない。
- **データの型**（新規 `src/Registry/Define/CumFx.h/.cpp`）：
  - `CumFx::FxConfig`（設定ファイル 1 つ）：`id`、`displayName`、`profiles`、セット全体の条件、`weight`
  - `CumFx::FxProfile`（テクスチャのフォルダ 1 つ）：`name`、種類ごとのレイヤーの数 `counts`、条件、`weight`
  - `CumFx::ActorFilter`（条件）：SexLab の種族キー、種族の EditorID（防具の元になる種族とも比べる）、性別のビットマスク。空なら「すべて」
  - `Library::FxType` は `CumFx::Type` の別名にした（`Library::FxType::Vaginal` などの書き方はそのまま使える）。`FxPair` も互換のために残した
- **読み込み**（`Library::InitializeCumFx`）：
  1. テクスチャのフォルダ（`Data\Textures\SexLab\CumFx\<種類>\<セット>\`）を、これまでどおり調べる
  2. 設定ファイル（`Data\SKSE\SexLab\CumFx\*.yaml|*.yml|*.json`）を読む。`counts` を書かない種類はフォルダのテクスチャの数を使い、フォルダより多い値は切り詰める。`counts` に 0 を書いた種類には使わない
  3. どの設定ファイルにも書かれていないフォルダは、条件なし・重み 1 のセットにする（旧形式の取り込み。設定ファイルが無ければ、これまでと同じ動き）
  - 設定ファイルの書き方に誤りがあれば、ログに理由を出し、そのファイルに書いたフォルダは 3 の扱いになる
- **選び方**（`Library::PickRandomFxSet(RE::Actor*, FxType)`）：条件に合うセットを重みで 1 つ選び、その中から条件に合い、その種類のテクスチャを持つプロファイルを重みで 1 つ選ぶ。アクターが無い場合（既存の `PickRandomFxSet(FxType)`）は条件を見ない。候補が無ければ空の文字列。`GetFxCount` は `counts` を返す
- **Papyrus**：
  - `sslActorLibrary.PickRandomFxSetForActor(Actor, int)` を追加した（メインスレッドで実行。アクターの種族とファクションを読むため）
  - 既存の `PickRandomFxSet(int)` はそのまま残した
  - `BeginOverlay` は `PickRandomFxSetForActor` を使うようにした
- **設定ファイルの書き方**：`精液エフェクトの設定ファイル.md`
- **仕様との違い**：仕様の `races` は SexLab の種族キーだけだった。種族キーでは人型の種族（ノルド、カジート、アルゴニアンなど）がすべて `Human` になり、種族ごとに選び分けられない。そのため、種族の EditorID も書けるようにした（仕様の「その他メタ（必要に応じて）」の扱い）
- **変更したファイル**：新規 `src/Registry/Define/CumFx.h`、`CumFx.cpp`、`精液エフェクトの設定ファイル.md`。変更 `src/Registry/Library.h`、`Library.cpp`、`Library_SaveLoad.cpp`、`src/Papyrus/sslLibrary/sslActorLibrary.h`、`sslActorLibrary.cpp`、`dist/Source/Scripts/sslActorLibrary.psc`
- **確認**：SE / AE ともビルドは警告 0・エラー 0。ゲーム内では未確認（設定ファイルなしで今までどおり付くか、種族・性別の条件と重みが効くか）

### 6.9 表情（MFG）の処理を内蔵し、MfgFix NG（GPL-3.0）を不要にした

- **問題**：
  - `sslExpressionUtil.psc` は、表情（phoneme、modifier、expression）を外部の MOD「MfgFix NG」の `MfgConsoleFuncExt` で動かしていた（7 か所）。
  - MfgFix NG（`KrisV-777/Mfg-Fix-NG`）は、最初のコミットから **GPL-3.0**（MOD 向けの例外条項つき）。Papyrus をビルドするには、その `.psc` をインクルードする必要があった。
- **出どころ**：MfgFix NG のソースは見ていない（ユーザーから参考ソースとして示されたが、GPL のため読んでいない）。次の Apache / MIT のものだけを材料に自作した。
  - SexLab（2.18.1、Apache）の呼び出し側（`sslExpressionUtil.psc`、`sslBaseExpression.psc`、`sslBaseVoice.psc`）と、MfgFix を使う前の版の関数 `sslBaseExpression.ApplyPresetFloatsLegacy`（プリセットの値の並びと、口が開いているときは phoneme と表情を変えない、という扱い）
  - SexLab の既存の読み取りの native（`sslExpressionSlots.cpp` の `GetModifier`、`GetPhoneme`、`GetExpression`）
  - CommonLib（MIT）の `BSFaceGenAnimationData` と `BSFaceGenKeyframeMultiple::SetValue`
- **修正**：
  - 新規 `src/Thread/FaceAnimator.h/.cpp`：アクターごとに、phoneme 16 個・modifier 14 個・表情 1 つの目標の値を持ち、フレームフック（メインスレッド）で目標に向けて少しずつ動かす。速さ 1.0 で、0 から 1 への変化に 0.2 秒かかる。表情は `expressionKeyFrame` に書き、`exprOverride` を立てる。リセットで表情を 0 にした後は、上書きを外す。3D が無くなったアクターは追跡をやめる。ロードのとき（`RevertCallback`）は全部を捨てる
  - `sslExpressionUtil` に native を 5 つ追加（`SetPhonemeImpl`、`SetModifierImpl`、`SetExpressionImpl`、`ApplyPresetImpl`、`ResetFaceImpl`。`src/Papyrus/sslObject/sslExpressionSlots.h/.cpp` に登録）。`SmoothSetModifier` などの既存の関数は、名前と引数を変えずに、呼び先をこれに変えた
  - `sslSystemConfig.CheckSystemPart("MfgFixNG")` は、SexLabUtil.dll があれば真を返すようにした（`sslBaseVoice` の口の動かし方の分岐が、今までどおり MFG を使う側になる）。MCM の要件一覧の表示名を「Facial Animation (SexLabUtil.dll)」にした
  - `xmake.lua` の Papyrus のインクルードから `MfgFix NG\Source\Scripts` を外した
- **MfgFix NG との違い**：動かし方（変化の速さの式、途中の値の補間）は自分で決めたもので、MfgFix NG とは同じではない。MfgFix NG を一緒に入れても衝突しない（native の名前は SexLab 自身のスクリプト `sslExpressionUtil` のもの）
- **変更したファイル**：新規 `src/Thread/FaceAnimator.h`、`FaceAnimator.cpp`。変更 `src/Thread/Hooks.cpp`、`src/Serialization.h`、`src/Papyrus/sslObject/sslExpressionSlots.h`、`sslExpressionSlots.cpp`、`dist/Source/Scripts/sslExpressionUtil.psc`、`sslSystemConfig.psc`、`sslConfigMenu.psc`、`xmake.lua`、`README.md`、`ビルドと配布物の作成手順.md`
- **確認**：SE / AE ともビルドは通った。Papyrus のビルドとゲーム内での確認（表情・口の開閉・口パクが動くか）はまだ

### 6.10 SexLab Rape Spell を SexLab.esm に取り込んだ（新機能）

- **目的**：別の MOD「SexLab Rape Spell」（SE 版、Nexus SE mod 12302。`SexLabRapeSpell.esp` とスクリプト 12 個）を、SexLab の配布物だけで使えるようにする（ユーザーの指示）。再配布と改変は作者の許可を確認ずみ（ユーザーの回答）。
- **出どころ**：ユーザーの MO2 の `mod_se\mods\0301(sexlab)rape spell`（esp は日本語化ずみ、`.psc` は日本語のコメントを足したもの。処理は元と同じ）。英語の MCM の文字列は `mod_le\mods\(sexlab)rapespell` の原文。GPL のコードは含まない。
- **手順**：
  1. `Spriggit.CLI serialize` で esp を YAML にし、レコード 82 個の FormKey `XXXXXX:SexLabRapeSpell.esp` を `(XXXXXX + 0x100000):SexLab.esm` に付け替えて `res/SexLab.esm` の各フォルダに置いた（ファイル名も同じ規則）。EditorID の重複は無い。
  2. バニラの `IronDagger`（`01397E:Skyrim.esm`）の上書きは、名前を日本語にしただけなので取り込まなかった。
  3. `.psc` 12 個を `dist/Source/Scripts` に置いた。`sslrapespell.psc` の `getArousal` は `slaFrameworkScr` を型に使っていて、ビルドに SexLab Aroused のソースが要るので、派閥 `sla_Arousal`（`SexLabAroused.esm` の `03FC36`）の位階を読む形に変えた。Aroused はこの位階に興奮度を書き込む。Aroused が無いときは今までどおり 0。
  4. MCM の文字列 49 行を `dist/Interface/Translations/SexLab_*.txt` の末尾に足した（`SexLab_JAPANESE.txt` は SE 版の日本語訳、ほかは英語の原文）。キーの重複は無い。翻訳のファイル名はプラグイン名に合わせる必要があるので、`SexLabRapeSpell_*.txt` のままでは読まれない。
- **注意**：元の MOD を一緒に入れると、同じ名前のスクリプトとクエストが二重に動く。元の MOD は無効にする。FormID が変わるので、元の MOD を使っていたセーブとの互換性は無い。
- **変更したファイル**：新規 `res/SexLab.esm/*/SSLRS*`、`SexLab*RapeSpell*` など 82 個、`dist/Source/Scripts/sslrapespell*.psc`、`sslrs*.psc`（12 個）、`dist/Scripts` の同名の `.pex`。変更 `dist/Interface/Translations/SexLab_*.txt`（16 個）、`dist/SexLab.esm`、`README.md`
- **確認**：Spriggit で `SexLab.esm` を組み立てられた（日本語の名前は元のバイトのまま入る）。12 個のスクリプトは SexLab P+ 2.18.1 の `.psc` に対してコンパイルが通った。ゲーム内での確認（MCM の表示、呪文の動作）はまだ

---

## 7. まだ確認が終わっていない事項

### 7.1 `lib/ImGui/SKSEMenuFramework.h`（**解決済み**）

- 入手元：`lib/ImGui/_source` の記載によると `https://github.com/QTR-Modding/SKSE-Menu-Framework-3/blob/master/resources/SKSEMenuFramework.h`（リポジトリのライセンスは **GPL-3.0**）
- 2.18.1 の時点から元々入っていたファイルで、`src/Thread/Interface/` 以下の 7 ファイルが使っていた。
- **6.6 で削除し、Dear ImGui（MIT）を組み込む独自の UI ホストに置き換えた。** ビルド時にこのヘッダーを使うことも、実行時に SKSEMenuFramework.dll を必要とすることもなくなった。
- 確認方法：`git grep -n "SKSEMenuFramework.h"` で、ソースからの参照がないこと（本文書を除く）。


---

## 8. 確認の状況

| 項目 | 状況 |
|---|---|
| C++ のビルド（SE 1.5.97 用） | 成功（`--skyrim_runtime=se`）。xmake v3.1.1、VS2022（MSVC 14.44）、release、警告 0、エラー 0（警告はエラー扱いの設定）。出力は `build/se/windows/x64/release/SexLabUtil.dll`。入口は `SKSEPlugin_Query` / `SKSEPlugin_Load`。6.7（SkyShim と共通の CommonLib）を含む |
| C++ のビルド（AE 1.7.104 用） | 成功（`--skyrim_runtime=ae`、警告 0、エラー 0、2026-10-07）。出力は `build/ae/windows/x64/release/SexLabUtil.dll`。入口は `SKSEPlugin_Version`（アドレスライブラリを使う、更新後の構造体の配置）/ `SKSEPlugin_Load`。**1.7.104 の実行ファイルでの割り込み先と構造体の配置の確認は、まだ** |
| Papyrus の構文チェック | 変えた行の範囲にはエラーなし。完全なコンパイル（`.pex` の生成）は、バニラのスクリプトソース一式、SkyUI SDK、MfgFix NG、SkyrimLovense、VRIK のソースがないため、まだできていない |
| ゲーム内での確認 | まだしていない。とくに 6.5（屋内、坂、狭い場所）、6.2（Legacy 設定で短いシーン）、6.6（UI の表示、マウスとキーボードの操作、操作をふさいだ後に元に戻るか、ENB や ReShade と一緒に使ったとき） |

ビルドの手順（DLL だけ）：

```powershell
cd E:\work\work_skyrim\SexLabpp
D:\bin\xmake-bundle-v3.1.1.win64.exe f -y -m release --vs=2022 --skyrim_runtime=se --build_papyrus=n --build_spriggit=n --build_assets=n
D:\bin\xmake-bundle-v3.1.1.win64.exe build SexLabUtil
# AE（1.7.104）用は、xmake f の --skyrim_runtime=se を --skyrim_runtime=ae にする（出力は build/ae）
```

---

## 9. 今回は手を付けていない上流の修正

| 上流の修正 | 内容 | 手を付けていない理由 |
|---|---|---|
| Enjoyment の計算まわり（`2c9bcb77`、GPL 化の後の `010e8dc7`） | Enjoyment の計算と表示の不具合 | 変更が大きく、何が悪かったのかがメッセージから分からない。上流のコードを見ずに直すには、先にゲーム内で症状を再現して特定する必要がある |
| 一般的なベッドの基準オフセット（`be2b37ac`） | `common.yaml` のオフセット値 | データの値なので、ゲーム内で測って決める必要がある |

2.18.1 の後に上流で直された不具合のうち、クラッシュに関係するもの（`3bafcd57`、`1db5cfc1`）は、2.18.1 には存在しない新しいシステム（`Interaction/NiSurface`）向けの修正だった。2.18.1 には当てはまらない。`5b86e25a`（一時停止中の処理）も、2.18.1 の NiUpdate が「ゲーム内の時刻が進まなければ処理しない」作りなので、必要ない。

---

## 10. 更新したときの決まり

このブランチを今後更新するときは、次を守る。

- 上流の `0667d089` 以降のコミットは、マージも cherry-pick もしない。
- CommonLib は SkyShim と共通のものを使う。CommonLibSSE-NG の `cf24ab81c`（GPL 化）以降のコードは取り込まない。CommonLib を直すときは SkyShim 側と同じ直し方にそろえ、追加した箇所にコメントを付ける。
- 新しく加えるライブラリやコードは、ライセンスを確かめてから入れ、この文書の 3 章か 7 章に書き足す。
- UI は自前のホスト（`MenuHost`）で動かす。外部のメニューフレームワークのヘッダーや DLL には戻さない。
- 修正を加えたら、6 章に症状・原因・修正・変更箇所を書き足す。
