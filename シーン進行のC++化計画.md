# シーン進行の C++ 化計画（関数単位）

SexLab P+ 2.18.1 の Papyrus に残っている「シーン進行」（状態の移り変わり、準備の同期、更新ループ、快感、ステージの進行、フックとイベント）を C++ に移す計画。
**どの Papyrus の関数を、どう変えて、C++ のどの関数に移すか**を、関数ごとに書く。

> 対象：このリポジトリ（SkyShim 向けフォーク、2.18.1 が土台）。SE 1.5.97 と AE 1.7.104。
> 上流の SexLab P+ の GPL 化（`0667d089`）以降のコードは見ない・写さない。
> 行番号は、このリポジトリの `dist/Source/Scripts/*.psc` と `src/` の今の版のもの。

**表の読み方**

- 「今の処理」：その関数が今やっていること（ソースを読んだ結果）。
- 「移行後の Papyrus」：Papyrus の関数をどう変えるか。「削除」「空にする」「native に変える」「本体を C++ に移し、名前は残す」のどれかを書く。
- 「移行後の C++」：処理を受け持つ C++ の関数（新しく作るものは **太字**）。ファイルも書く。
- 「キュー」：4.2 の `PapyrusCallQueue` を通して、C++ から Papyrus の関数を順番に呼ぶこと。

**用語：「シーン枠」と「スレッド」**

この文書では、2 つの別のものを次のように呼び分ける。

| この文書の呼び方 | 正体 | 例 |
|---|---|---|
| **シーン枠** | SexLab が「スレッド（thread）」と呼んでいるもの。**1 つのシーンの情報を入れる箱**で、ESM の Quest（`SexLabThread00`〜`SexLabThread14` の 15 個）が 1 つずつ受け持つ。シーンを始めるときに空いている枠を借り、終わったら返す。枠の数が「同時に動かせるシーンの数」の上限になる。OS や CPU のスレッドとは関係がない | Papyrus の `sslThreadModel`、`sslThreadController`、`sslThreadSlots`、`GetThreadID()`、`tid`。C++ の `Thread::Instance`（1 つのシーン枠の C++ 側のデータ。`std::thread` ではない） |
| **スレッド**（メインスレッド、VM のスレッド） | プログラムの用語の、並行して動く処理の単位（OS のスレッド） | ゲーム本体のメインスレッド、Papyrus の VM が使うスレッド |

- SexLab の「スレッド」という名前は、元の SexLab の作者が「始まりから終わりまで続く一続きのシーン」の意味で付けたもの。外部 MOD が使う関数やスクリプトの名前（`sslThread*`、`SexLabThread`、`GetThreadID` など）に入っているので、コードの名前は変えない。
- すべてのシーン枠の処理は、ゲームのメインスレッドと Papyrus の VM の中で、順に少しずつ進められる。シーン枠を 1 つ使っても、OS のスレッドは増えない。そのため、CPU のコアやスレッドの数は、シーン枠の数の上限を決めない。

---

## 1. 今の流れ（ソースで確かめたもの）

### 1.1 開始からアニメ開始まで

| # | 関数（ファイル:行） | 状態 | 処理 | 待ち方 |
|---|---|---|---|---|
| 1 | `sslThreadModel.StartThread`（:842） | Making | `RunHook(STARTING)`、`CreateInstance`（native）を呼ぶ | `_instanceCreationWaitLock` が決まるまで `Utility.Wait(0.05)` で回る（:858） |
| 2 | C++ `Instance::DispatchContinueSetup`（Thread.cpp:79） | | 家具の選択（メニューを含む）が終わったら `ContinueSetup(bool)` を Papyrus に返す | 非同期 |
| 3 | `StartThread` の続き | Making | `GoToState(Making_M)` | |
| 4 | `Making_M.OnBeginState`（:888） | Making_M | `BeginPlayerDialogueWait`（native）→ `BeginActorRecovery`（native）→ `BeginAliasPreparation` | C++ が終わったら `OnPlayerDialogueComplete`（:898）／`OnNativeActorRecoveryComplete`（:905）を呼び返す |
| 5 | `BeginAliasPreparation`（:914） | Making_M | `SSL_PREPARE_Thread<tid>` を `CenterRef` から送る。シーンの配列を C++ から取り直す。`SortAliasesToPositions`。自分の分の `PrepareDone()`。`_ThreadTags` を作る | |
| 6 | `sslActorAlias.Ready.OnDoPrepare`（:459） | Ready → Paused | `WaitForPathToCenter`（歩かせて近づくのを待つ）、アニメ変数の保存、`GoToState(Paused)`、声の間隔とストラップオンを決める、`_Thread.PrepareDone()` | `WaitForPathToCenter` が `Utility.Wait(2.0)` の後、`Utility.Wait(0.05)` で距離を見て最大 15 秒回る（:512〜519） |
| 7 | `PrepareDone`（:931） | Making_M | 呼ばれた数が「人数 + 1」になったら、プレイヤーがいれば `BeginPlayerSheatheWait`（native）→ `NativeActorLockApplied` → `FinishPreparation` | C++ が `OnPlayerSheatheComplete`（:949）を呼び返す |
| 8 | `FinishPreparation`（:962） | Making_M | `LeadIn` を決め直す、`SendThreadEvent("AnimationStarting")`、`UndressAndStripActors` | |
| 9 | `UndressAndStripActors`（:970） | Making_M | 各アクターの `InitiateUndressing`（脱衣のアニメのイベント）、フェード、地図の目標、各アクターの `ReadyActor`（脱衣・ストラップオン・`SSL_READY` の登録）、`GoToState(Animating)` | 脱衣があれば `Utility.Wait(2.5)` と `Utility.Wait(1.5)`（:978、:998） |
| 10 | `Animating.OnBeginState`（:1116） | Animating | `SSL_READY_Thread<tid>` を送る、自分の分の `AnimationStart()` | |
| 11 | `sslActorAlias.Paused.OnStartPlaying`（:608） | Paused → Animating | `GoToState(Animating)`、`TrackedEvent(START)`、`_Thread.AnimationStart()`、`SOSBend0`、`CheckActiveHomoTypes`、`UpdateBaseEnjoymentCalculations` | 男性とクリーチャーで `Utility.Wait(0.5)`（:616） |
| 12 | `AnimationStart`（:1130） | Animating | 呼ばれた数が「人数 + 1」になったら、`AutoAdvance` を決め、`GetThreadControl`、`StartedAt`、`StartStage` | |
| 13 | `StartStage`（:1245） | Animating | `SendThreadEvent("StageStart")`、`RunHook(STAGESTART)`、`AdvanceScene`（native） | |
| 14 | C++ `UpdatePendingAnimations`（ThreadAnimation.cpp:656） | | アニメの切り替えがそろったら `OnAnimationSynchronized` を呼び返す（:801） | 非同期 |
| 15 | `OnAnimationSynchronized`（:1538） | Animating | HUD の更新、`ConfigureStageTimer(false)`、初回だけ `SendThreadEvent("AnimationStart")` と `"LeadInStart"` | |

### 1.2 アニメ中の更新ループ

| ループ | 関数 | 間隔 | 中身 |
|---|---|---|---|
| シーン枠 | `sslThreadModel.Animating.OnUpdate`（:1365） | 0.5 秒（`ANIMATING_UPDATE_INTERVAL`） | (1) `_initialRealignTicks` が 3 と 0 のときに `RealignActors`（開始後 0.5 秒と 2.0 秒）。(2) 固定長でないステージのタイマーを減らし、0 で `AdvanceFromTimer`。(3) `_SFXTimer` が切れたら `ListDetectedInteractionsInternal(None, None)` で行為を見て、`SexMixedFX` / `SuckingFX` / `SquishingFX` を `Play(CenterRef)`。次は `SFXDelay × 0.9〜1.3`（最小 0.8 秒）。(4) `UpdateAnimationSpeed` |
| アクター | `sslActorAlias.Animating.OnUpdate`（:766） | 0.25 秒（`UPDATE_INTERVAL`） | (1) `_CurrentInteractions` を取る。(2) `UpdateEffectiveEnjoymentCalculations`。(3) 快感バーの更新。(4) `CalcReaction` が 100 なら `DoOrgasm`。(5) 声（`sslBaseVoice.PlaySound`。`PlayAndWait` か `MoveLips` で、**声が終わるまでこのループが止まる**）。(6) 表情（`RefreshExpressionEx`。口を開けるときは `Utility.Wait(0.7)` で止まる）。(7) Lovense（プレイヤーだけ）。(8) VRIK（VR だけ） |
| 準備の時間切れ | `sslThreadModel.Making.OnUpdate`（:732） | 30 秒に 1 回 | `Making` の間に 30 秒たったら、シーン枠を初期化する |
| 終了の後 | `sslThreadModel.Ending.OnUpdateGameTime`（:1777） | ゲーム内 0.1 時間（標準で現実の約 18 秒） | `Initialize()` でシーン枠を空きに戻す |

### 1.3 ステージの進行（`Animating` の中）

`GoToStage`（:1256）→ 先へ進むなら（分岐が 2 つ以上でプレイヤーがいれば `OpenStageSelectMenuImpl`、そうでなければ `SelectNextStage`）→ `PlayNext`（:1193：`StageEnd` のイベントとフック）→ `PlayNextImpl`（:1199：絶頂の処理、各アクターの `TryLockAndUnpause` と `UpdateNext`）→ `StartStage`。
`AdvanceFromTimer`（:1353）は、`ThreadWaitsForOrgasm` が真なら `FindSimilarSceneStage` で似たシーンへ `ResetScene` する。
`ResetScene`（:1156）は、同期中なら次のシーンを `_queuedSceneReset` に積み、終わった直後 0.5 秒は受け付けない。

### 1.4 終了

`EndAnimation` → `GoToState(Ending)` → `Ending.OnBeginState`（:1694）：`CancelPendingAnimations`、`DisableThreadControl`、`SSL_CLEAR_Thread<tid>` を送る（各アクターが `OnRequestClear` → `Clear`）、`MoveActorsAwayFromPlayer`、`UnregisterCollision`、地図の目標を消す、`UpdateAllEncounters`、**全アクターが `Empty` に戻るまで `Utility.Wait(0.05)` で回る**（:1708〜1714）、`SendThreadEvent("AnimationEnding")`、`SendThreadEvent("AnimationEnd")`、`RunHook(END)`、`RegisterForSingleUpdateGameTime(0.1)`。

### 1.5 すでに C++ にあるもの

- 開始の準備：`CreateInstance`、`BeginPlayerDialogueWait`、`BeginActorRecovery`、`BeginPlayerSheatheWait`（いずれも終わったら Papyrus に呼び返す）。
- アニメの切り替えと同期：`AdvanceScene`、`UpdatePendingAnimations` → `OnAnimationSynchronized` / `OnAnimationSyncFailed`。
- 固定長タイマー：`RestartFixedLengthTimer` など。切れたら `OnFixedLengthStageComplete` を呼び返す。
- 行為の検出（`HasCollisionAction` など）、配置、統計（`SexLabStatistics`）、設定（`src/UserData/mcm.def` の値。Papyrus の `sslSystemConfig` のプロパティの多くは、この値を読み書きするだけ）。
- HUD（快感バー、タイマーの表示、ステージ選択）。
- C++ から Papyrus を呼ぶ道具：`src/Util/Script.h` の `DispatchMethodCall` と `DispatchStaticCall`（どちらも非同期。終わりは `IStackCallbackFunctor` で受ける）。

### 1.6 数字

| 項目 | 数 |
|---|---|
| `sslThreadModel.psc` | 3,511 行。関数 458 個（プロパティの get/set と、状態ごとの同名の関数を含む。native は 49 個） |
| `sslActorAlias.psc` | 1,820 行。関数 201 個（同上。native は 10 個） |
| `Utility.Wait` | 12 か所（`sslThreadModel` 4、`sslActorAlias` 4、`sslThreadController.MoveScene` 4） |
| 内部の ModEvent | `SSL_PREPARE` / `SSL_READY` / `SSL_ORGASM` / `SSL_CLEAR`（それぞれ `_Thread<tid>` 付き） |

---

## 2. 目標と、やらないこと

### 2.1 目標

1. 1.1〜1.4 の「いつ・どの順で進めるか」を C++ が決める。`Utility.Wait` による待ち（`StartThread` の 1 か所を除く。6.1 を参照）と、内部の 4 つの ModEvent をなくす。
2. 1.2 の 2 つの更新ループ（`RegisterForSingleUpdate`）をなくし、C++ の毎フレームの処理にする。
3. 快感・絶頂・行為の値の持ち主を C++ にする。
4. フックは今の「シーン枠を止めて呼ぶ」約束を守ったまま、時間を測ってログに出す。
5. 同時に動かせるシーンの数（シーン枠の数）を設定で変えられるようにする（P5）。
6. Papyrus のログを C++ のログ（`SexLabUtil.log`）にまとめる（P4）。

### 2.2 やらないこと

- 外部 MOD が呼ぶ関数の削除・引数の変更・イベント名の変更。11 章の関数は変えない。
- 脱衣・着衣・装備（`StripByData` の結果を Papyrus の `_equipment` に持つ部分）、表情、声の再生そのもの、Lovense、`SendThreadEvent`（外部 MOD 向けの型付きのイベント）、`RunHook`（外部 MOD のフック）を C++ で作り直すこと。これらは Papyrus に残し、**呼ぶタイミングだけ** C++ が決める。
- VR（VRIK）の処理。このフォークは VR を対象にしないので、`sslActorAlias.Animating.OnUpdate` の VRIK の部分（:798〜811）は削る。
- アクターの上限（5 人）の引き上げ。

---

## 3. 守らなければならない互換性

| 種類 | 内容 |
|---|---|
| Papyrus の関数 | 11 章の関数（`SexLabFramework`、`SexLabThread`、`sslThreadModel` / `sslThreadController` の公開関数、`sslActorAlias` の公開関数、Legacy の関数）。引数と戻り値の型を変えない |
| 状態の名前 | `sslThreadModel` の `Unlocked` / `Making` / `Making_M` / `Animating` / `Ending`、`sslActorAlias` の `Empty` / `Ready` / `Paused` / `Animating`。`GetState()` と `GetStatus()` の値を、今と同じ順で移す |
| 外部 MOD 向けのイベント | `SendThreadEvent` が送るもの（`AnimationStarting`、`AnimationStart`、`LeadInStart`、`StageStart`、`StageEnd`、`OrgasmStart`、`OrgasmEnd`、`LeadInEnd`、`ActorsRelocated`、`ActorChangeStart`、`ActorChangeEnd`、`AnimationEnding`、`AnimationEnd`。それぞれ `Hook<名前>`（int, bool）と `<名前>`（`SendModEvent`）、`_<フック名>` 付きの版）、`SexLabOrgasm`（Form, int, int）、`SexlabOrgasmSeparate`（Form, int）、`SexLabApplyCumFX`（Form, Form, int）、`sslThreadLibrary.SendTrackingEvents` が送るもの。名前・引数・送る順番を変えない |
| フック | `sslSystemConfig.RunHook` が `SexLabThreadHook` の 4 つの関数を、シーン枠を止めて登録順に呼ぶこと。呼ばれる位置（1.1 の #1・#13、1.3 の `PlayNext`、1.4） |
| Quest フォーム | `SexLabThread00`〜`14` の FormID と、各 Quest の ActorAlias 5 個 |
| 外からの `OnUpdate` | Rape Spell は 5 秒ごとに `onUpdate()` を外から呼ぶ。移行後の `OnUpdate` は空にする（呼ばれても何も起きない） |
| セーブ | ロードすると `sslSystemAlias.OnPlayerLoadGame` → `ThreadSlots.StopAll()` で進行中のシーンが終わる。この動きは変えない |

内部の ModEvent（`SSL_PREPARE` / `SSL_READY` / `SSL_ORGASM` / `SSL_CLEAR`）は SexLab の内部の同期のためのもので、移行後は送らない。**外部 MOD がこれを受けていても、送り続けない。** 受けている MOD は、この計画の対象外にする（P0 で見つかったものは一覧にして、README に「動かない MOD」として書く）。

---

## 4. C++ 側の共通の仕組み（P1 で作り、P2〜P5 でも使う）

### 4.1 シーン枠の進行の状態：`Thread::Instance::Flow`

新しいファイル `src/Thread/ThreadFlow.cpp` に置き、`Thread.h` の `Instance` にメンバーを足す。

```cpp
enum class Flow : uint8_t {
    Setup,          // Making。StartThread を待っている
    DialogueWait,   // プレイヤーの会話の終わりを待つ（既存の BeginPlayerDialogueWait）
    Recovery,       // アクターの復旧（既存の BeginActorRecovery）
    Pathing,        // 歩いて中心に近づくのを待つ（1.1 #6 の WaitForPathToCenter）
    Preparing,      // 各アクターの準備の完了を待つ（1.1 #6・#7）
    SheatheWait,    // プレイヤーが武器を納めるのを待つ（既存の BeginPlayerSheatheWait）
    Undressing,     // 脱衣のアニメの時間（1.1 #9 の 2.5 秒と 1.5 秒）
    Starting,       // 各アクターを Animating にする（1.1 #10〜#12）
    Playing,        // アニメ中
    Ending,         // 終了の処理
};
Flow flow{ Flow::Setup };
float flowTimer{ 0.0f };       // 今の Flow に入ってからの秒数（ゲームが止まっている間は進めない）
uint32_t generation{ 0 };     // シーンを始めるたび、終えるたびに 1 増やす（4.3）
```

- `Instance::UpdateAnimations`（ThreadAnimation.cpp:399）の中で、各シーン枠の **`Instance::UpdateFlow(float a_delta)`** を呼ぶ。`a_delta` は既存のとおり、ゲームが止まっている間は 0。
- 準備全体の時間切れ（今の `Making.OnUpdate` の 30 秒）は、`Flow` が `DialogueWait`〜`Starting` の間の合計の時間で見る。30 秒を超えたら **`Instance::AbortSetup()`** で 4.3 の世代を進め、Papyrus の `Fatal` 相当のログを出し、Papyrus の `Initialize()` をキューで呼ぶ。

### 4.2 C++ から Papyrus を順番に呼ぶ：`Thread::PapyrusCallQueue`

新しいファイル `src/Thread/PapyrusCallQueue.h/.cpp`。シーン枠ごとに 1 つ持つ。

```cpp
class PapyrusCallQueue {
public:
    using OnDone = std::function<void(const RE::BSScript::Variable& a_result)>;
    // a_object の a_function を呼ぶ要求を積む。前の呼び出しの OnDone が来てから次を呼ぶ
    template <class... Args>
    void Push(Script::ObjectPtr a_object, std::string_view a_function, OnDone a_onDone, Args&&... a_args);
    void PushStatic(std::string_view a_class, std::string_view a_function, OnDone a_onDone, ...);
    void Clear();   // 世代が変わったときに、まだ呼んでいない要求を捨てる
};
```

- 中では `Script::DispatchMethodCall` / `DispatchStaticCall` を使う。終わりは `IStackCallbackFunctor` を継承したクラスで受け、**メインスレッドのタスク**（`SKSE::GetTaskInterface()->AddTask`）に回してから `OnDone` を呼ぶ。Papyrus の VM のスレッドから `Instance` を直接触らないため。
- 1 つずつ順に呼ぶので、今の Papyrus の中での順番（例：`SendThreadEvent("StageStart")` → `RunHook(STAGESTART)` → `AdvanceScene`）が保たれる。
- フレームフックの中で戻りを待つことはしない。

### 4.3 世代の番号

- `generation` は `StartThread` が受け付けられたとき、`AbortSetup` のとき、`Ending` に入ったときに 1 増やす。
- キューの `OnDone` と、Papyrus から来る native の知らせ（4.5）は、呼んだときの世代を持つ。今の世代と違えば何もしない（時間切れの後に遅れて届いた知らせで、状態が戻るのを防ぐ）。

### 4.4 ロードのとき

- `Serialization::Serialize::RevertCallback`（src/Serialization.h:73）に **`Thread::Instance::DestroyAll()`** の呼び出しを足す。中身は `instances` を全部捨てること（各 `Instance` は生の `RE::Actor*` を持つため、ロードの後に触らない）。
- Papyrus 側は今のまま、`OnPlayerLoadGame` → `StopAll()` → 各シーン枠の `EndAnimation()` で片付く。そのとき C++ の `Instance` はもう無いので、`DestroyInstance` などの native は何もせずに戻る（今もそうなっていることを P1 で確かめる）。

### 4.5 Papyrus の状態の移し方

`GotoState` は Papyrus の中でしかできないので、Papyrus の状態は Papyrus 自身が移す。C++ は「次へ進んで」と Papyrus の関数をキューで呼び、その関数の中で `GoToState` する。対応は次のとおり。

| C++ の `Flow` | `sslThreadModel` の状態 | 状態を移す Papyrus の関数 |
|---|---|---|
| `Setup` | `Making` | `Make()`（今のまま） |
| `DialogueWait`〜`Undressing` | `Making_M` | `StartThread()`（今のまま。:867） |
| `Starting`・`Playing` | `Animating` | **`EnterPlayingNative()`**（新規。`GoToState(STATE_PLAYING)` だけを行う） |
| `Ending` | `Ending` | `EndAnimation()`（今のまま） |
| （空き） | `Unlocked` | `Initialize()`（今のまま） |

各状態の `OnBeginState` に今ある処理は、C++ に移すか、新しい Papyrus の関数に分ける（5〜8 章）。`OnBeginState` に残すのは、変数の初期化だけにする。

---

## 5. P0 調査と計測

調べる MOD は、ユーザーが指定する（以下「対象の MOD」）。

| 作業 | 方法 | 成果物 |
|---|---|---|
| 内部の ModEvent を外部 MOD が受けているか | 対象の MOD の `.psc` から `SSL_PREPARE`、`SSL_READY`、`SSL_ORGASM`、`SSL_CLEAR` を探す | 一覧（見つかった MOD は対象外として README に書く。3 章） |
| 内部の関数を外部 MOD が呼んでいるか | 6〜8 章で「削除」「空にする」とした関数の名前（`PrepareDone`、`AnimationStart`、`OnDoPrepare`、`OnStartPlaying`、`OnOrgasm`、`OnRequestClear`、`WaitForPathToCenter`、`UpdateEffectiveEnjoymentCalculations`、`DoOrgasm`、`OnUpdate` など）を `.psc` から探す | 一覧。見つかった関数は「空にする」をやめ、C++ への転送にする |
| 状態の名前を見ている MOD | `GetState()` と `"Animating"` などの文字列を探す | 一覧 |
| シーン枠の番号で大きさ 15 の配列を持つ MOD | `new .*\[15\]` と `GetThreadID`／`tid` の使い方を探す | 一覧（P5 で使う） |
| 今の遅さ | `sslLog` のログの時刻から、(a) `StartThread` から `AnimationStart` のイベントまで、(b) `GoToStage` から `StageStart` のイベントまで、を測る。シーン枠を 1・3・5 個同時に動かした場合と、スクリプトの多い環境・少ない環境で | 基準の数字（各段階の後に測り直す） |

---

## 6. P1 開始・準備・終了の C++ 化

### 6.1 `sslThreadModel`

| 関数（行） | 今の処理 | 移行後の Papyrus | 移行後の C++ |
|---|---|---|---|
| `Making.StartThread`（:842） | 1.1 #1・#3 | **今のまま残す**。`CreateInstance` を待つ `Utility.Wait(0.05)` のループも残す（`StartThread` は呼んだ側に `sslThreadController` か `none` を返す約束があり、家具の選択のメニューの間も待つ必要がある）。最後の `GoToState(STATE_SETUP_M)` の後に、native **`BeginPreparationNative()`** を呼ぶ | **`Instance::BeginPreparation()`**（ThreadFlow.cpp）：世代を進め、`flow = DialogueWait` にして、既存の `BeginPlayerDialogueWait()` を呼ぶ |
| `Making.OnUpdate`（:732） | 30 秒で時間切れ | 空にする。`Making.OnBeginState` の `RegisterForSingleUpdate(30.0)` も消す | 4.1 の `AbortSetup()`（`Making` の間も `flowTimer` を数える。`flow == Setup` で 30 秒） |
| `Making_M.OnBeginState`（:888） | 会話待ち → 復旧 → 準備 | 空にする | `BeginPreparation()` が行う |
| `Making_M.OnPlayerDialogueComplete`（:898） | 復旧へ進む | 空にする（ログだけ） | 既存の `Instance` の会話待ち（ThreadAnimation.cpp:672 付近）が、Papyrus を呼ぶ代わりに **`Instance::OnDialogueWaitDone()`** を呼ぶ → `flow = Recovery`、`BeginActorRecovery()` |
| `Making_M.OnNativeActorRecoveryComplete`（:905） | 失敗なら終了、成功なら準備へ | 空にする（ログだけ） | 既存の復旧（ThreadAnimation.cpp:290 付近）が **`Instance::OnRecoveryDone(bool)`** を呼ぶ → 失敗ならキューで `EndAnimation()`、成功なら `StartPathing()` |
| `Making_M.BeginAliasPreparation`（:914） | `SSL_PREPARE` を送る、シーンの配列の取り直し、`SortAliasesToPositions`、`_ThreadTags` | 名前を **`OnPreparationStartedNative()`** に変える（新規。シーンの配列の取り直し、`SortAliasesToPositions`、`_ThreadTags` だけを行う。`SSL_PREPARE` は送らない。`PrepareDone()` は呼ばない） | **`Instance::StartPathing()`**：キューで `OnPreparationStartedNative()` → 終わったら、各アクターについてキューで `sslActorAlias.BeginPrepareNative(CenterRef)` を呼ぶ（6.2） |
| `Making_M.PrepareDone`（:931） | 数を数える | 削除（P0 で外部の呼び出しが無いことを確かめてから。あれば空にする） | **`Instance::OnActorPrepared(size_t a_position)`**：準備ができたアクターのビットを立てる。全員そろったら `flow = SheatheWait`、プレイヤーがいれば既存の `BeginPlayerSheatheWait()`、いなければ `BeginUndress()` |
| `Making_M.OnPlayerSheatheComplete`（:949） | 失敗なら終了。成功ならプレイヤーの `NativeActorLockApplied` → `FinishPreparation` | 空にする（ログだけ） | 既存の武器を納める待ち（ThreadAnimation.cpp:721 付近）が **`Instance::OnSheatheDone(bool)`** を呼ぶ → 失敗ならキューで `EndAnimation()`。成功ならキューでプレイヤーの `sslActorAlias.NativeActorLockApplied()` → `BeginUndress()` |
| `Making_M.FinishPreparation`（:962） | `LeadIn` を決め直す、`AnimationStarting` のイベント、脱衣へ | 本体を **`OnPreparedNative()`**（新規）に移す：`LeadIn` を決め直し、`SendThreadEvent("AnimationStarting")` を送る。元の名前は削除 | **`Instance::BeginUndress()`**：キューで `OnPreparedNative()` → 以下の `UndressAndStripActors` の C++ 版へ |
| `Making_M.UndressAndStripActors`（:970） | 脱衣のアニメ、2.5 秒待つ、フェード、地図、`ReadyActor`、1.5 秒待つ、`GoToState(Animating)` | 本体を分ける：フェードと地図の目標の部分を **`ApplyStartPresentationNative()`**（新規）にする。`Utility.Wait` は消す。元の名前は、状態の外の版（:1062、ログだけ）を残し、`Making_M` の版は削除 | `BeginUndress()` の続き：各アクターについてキューで `InitiateUndressing()`（今のまま。戻り値の bool を集める）→ どれかが真なら `flow = Undressing` で 2.5 秒 → キューで `ApplyStartPresentationNative()` → 各アクターについてキューで `ReadyActor(strip, sex)`（引数は今と同じく `SexLabRegistry.GetStripDataA` と `GetPositionSexA` の値。C++ の `Registry` から直接取る）→ 脱衣があれば 1.5 秒 → キューで `EnterPlayingNative()` → **`Instance::BeginStarting()`** |
| `Animating.OnBeginState`（:1116） | 同期用の変数の初期化、`SSL_READY` を送る、`AnimationStart()` | 変数の初期化だけ残す。`SSL_READY` と `AnimationStart()` の呼び出しを消す | `BeginStarting()`：`flow = Starting`。各アクターについてキューで `sslActorAlias.StartPlayingNative()`（6.2）→ 全員の分が終わったら、キューで `BeginAnimatingNative()` |
| `Animating.AnimationStart`（:1130） | 数を数え、そろったら開始 | 数える部分を消し、残りを **`BeginAnimatingNative()`**（新規）にする：`AutoAdvance` を決める、`Config.GetThreadControl`、`StartedAt`、`StartStage(空, "")`。`_initialRealignTicks = 4` は消す（P2 で C++ に移す。P1 の間は残す）。元の名前は削除 | `BeginAnimatingNative()` を呼んだ後、`flow = Playing` |
| `Ending.OnBeginState`（:1694） | 1.4 のとおり | 前半（`CancelPendingAnimations`、`DisableThreadControl`、`MoveActorsAwayFromPlayer`、`UnregisterCollision`、地図、`UpdateAllEncounters`）を **`OnEndingStartedNative()`**（新規）に移す。`SSL_CLEAR` と、`Utility.Wait(0.05)` のループを消す。後半（`AnimationEnding`・`AnimationEnd` のイベント、`RunHook(END)`、`RegisterForSingleUpdateGameTime(0.1)`）を **`OnActorsClearedNative()`**（新規）に移す。`OnBeginState` には `_QuickResetScenes` のときに何もしない判定と、native **`BeginEndingNative()`** の呼び出しだけを残す | **`Instance::BeginEnding()`**：世代を進め、`flow = Ending`。キューで `OnEndingStartedNative()` → 各アクターについてキューで `sslActorAlias.Clear()` → 全員の分が終わったら、キューで `OnActorsClearedNative()` |
| `Ending.OnUpdateGameTime`（:1777） | `Initialize()` | 今のまま | なし（ゲーム内 0.1 時間の待ちは、外部 MOD が `AnimationEnd` の後にシーン枠を読むための余裕なので、変えない） |

### 6.2 `sslActorAlias`

| 関数（行） | 今の処理 | 移行後の Papyrus | 移行後の C++ |
|---|---|---|---|
| `Ready.OnBeginState`（:444） | `SSL_PREPARE` に登録 | 空にする | なし |
| `Ready.OnDoPrepare`（:459） | 歩かせる、アニメ変数の保存、`Paused` へ、声の間隔とストラップオン、`PrepareDone` | 2 つに分ける。**`BeginPrepareNative(ObjectReference akPathTo)`**（新規）：プレイヤーなら `Game.DisablePlayerControls`（今の :497 と同じ引数）。NPC なら `CheckBardAudience`、歩かせる必要があれば（`DoPathToCenter` が真で、距離が `CalcPathingTargetDistance` より遠く 6144 以下）`_AnimatingFaction` のランクを 2 にして `UpdateAnimatingActorMovement`。戻り値は「歩かせたか」（bool）。**`FinishPrepareNative()`**（新規）：:462〜488 の処理（アニメ変数の保存、`GoToState(STATE_PAUSED)`、声の間隔、ストラップオン、デバッグのログ）。`OnDoPrepare` は削除 | **`Instance::UpdatePathing(float)`**：`BeginPrepareNative` が真を返したアクターについて、2.0 秒待った後、毎フレーム中心との距離を見る。(a) 目標の距離以下になった、(b) 0.05 秒あたりの距離の変化が 0.5 未満になった（止まった）、(c) 15 秒たった、のどれかで終わり。全員終わったら `flow = Preparing`、各アクターについてキューで `FinishPrepareNative()` → 終わるたびに `OnActorPrepared(i)` |
| `Ready.WaitForPathToCenter`（:494） | 上の歩かせる処理と、距離を見て待つループ | 削除（`BeginPrepareNative` と C++ に分けた） | 上の `UpdatePathing`。目標の距離（`sslThreadModel.CalcPathingTargetDistance`、:1935）は C++ に写す：**`Thread::GetPathingTargetDistance(int raceID)`**（種族の番号 2,3,9,11,12,31,32,34,35,40,41,47 は 300、18,24,27,38,46 は 400、14,26,36 は 800、ほかは 128） |
| `Paused.ReadyActor`（:596） | 脱衣、ストラップオン、`SOSBend0`、`SSL_READY` に登録 | `SSL_READY` への登録（:605）を消す。ほかは今のまま | なし（6.1 の `BeginUndress` がキューで呼ぶ） |
| `Paused.OnStartPlaying`（:608） | `Animating` へ、`TrackedEvent(START)`、時刻、`AnimationStart()`、0.5 秒待って `SOSBend0`、`CheckActiveHomoTypes`、`UpdateBaseEnjoymentCalculations` | 本体を **`StartPlayingNative()`**（新規）に移す。`_Thread.AnimationStart()` と `Utility.Wait(0.5)` と 2 回目の `SOSBend0` を消す。`OnStartPlaying` は削除 | `BeginStarting()` がキューで呼ぶ。2 回目の `SOSBend0` は、男性とクリーチャー（`sex` が 1 と 4 以外）について、0.5 秒後に C++ から **`actor->NotifyAnimationGraph("SOSBend0")`** で送る |
| `Empty.OnEndState`（:411） | `SSL_CLEAR` に登録 | 空にする | なし |
| `OnRequestClear`（:1163） | `Clear()` | 削除（P0 で外部の呼び出しが無ければ） | 6.1 の `BeginEnding` がキューで `Clear()` を呼ぶ |
| `NativeActorLockApplied`（:421） | アクターの固定とカメラ | 今のまま | 6.1 の `OnSheatheDone` と、既存の `OnNativeActorsPrepared` の流れから、キューで呼ぶ |

### 6.3 C++ の既存の関数の変更

| 関数（ファイル） | 変更 |
|---|---|
| 会話待ちの終わり（ThreadAnimation.cpp:672 付近） | `DispatchMethodCall(..., "OnPlayerDialogueComplete")` をやめ、`OnDialogueWaitDone()` を呼ぶ |
| 復旧の終わり（ThreadAnimation.cpp:290 付近） | `"OnNativeActorRecoveryComplete"` をやめ、`OnRecoveryDone(bool)` を呼ぶ |
| 武器を納める待ちの終わり（ThreadAnimation.cpp:721 付近） | `"OnPlayerSheatheComplete"` をやめ、`OnSheatheDone(bool)` を呼ぶ |
| `Instance::UpdateAnimations`（ThreadAnimation.cpp:399） | 各シーン枠の `UpdateFlow(delta)` を足す |
| `Serialization::Serialize::RevertCallback`（Serialization.h:73） | `Thread::Instance::DestroyAll()` を足す（4.4） |
| `src/Papyrus/sslThreadModel.cpp` | native の登録を足す：`BeginPreparationNative`、`BeginEndingNative` |

### 6.4 P1 の終わりの条件

- 1〜5 人のシーン、クリーチャーのシーン、家具のシーン（家具の選択のメニューを含む）、プレイヤーを含むシーンと含まないシーンが、開始して終わる。
- `sslThreadModel` と `sslActorAlias` の状態が、1.1 と同じ順で移る（`sslLog` のログで確かめる）。
- 外部 MOD 向けのイベント `AnimationStarting`、`StageStart`、`AnimationStart`、`AnimationEnding`、`AnimationEnd` と、フック `OnAnimationStarting`、`OnStageStart`、`OnAnimationEnd` が、今と同じ順で来る。
- 1 人のアクターが遠くにいて歩いて近づく場合、途中で止まった場合（壁など）に、15 秒以内に先へ進む。
- 準備の途中で 30 秒たつと、シーン枠が空きに戻る（`AbortSetup`）。
- 進行中のシーンを含むセーブをロードしても落ちず、シーンが終わる。

---

## 7. P2 更新ループと快感の C++ 化

### 7.1 新しく作る C++ の型

**`Thread::Enjoyment`**（新しいファイル `src/Thread/Enjoyment.h/.cpp`）。`Instance::Position` に 1 つずつ持たせる。今の `sslActorAlias` の変数をそのまま写す。

| C++ のメンバー | 元の Papyrus の変数（`sslActorAlias`） |
|---|---|
| `bool enabled` | `_bEnjEnabled` |
| `bool crtMaleHugePP` | `_CrtMaleHugePP` |
| `int conSubStatus` | `_ConSubStatus` |
| `float painContext, enjFactor, baseFactor, arousalBase` | `_PainContext`、`_EnjFactor`、`_BaseFactor`、`_arousalBase` |
| `float interFactor, modEnjMult, arousalStat` | `_InterFactor`、`_ModEnjMult`、`_arousalStat` |
| `float painInterTimer, painInterBackup, painInterDecayBackup, painInterCur` | `_PainInterTimer`、`_PainInterBackup`、`_PainInterDecayBackup`、`_PainInterCur` |
| `int fullEnjoyment` | `_FullEnjoyment` |
| `int orgasmCount; bool canOrgasm; bool inOrgasm; float lastOrgasm; float startedAt` | `_OrgasmCount`、`_CanOrgasm`、`_hasOrgasm`、`_LastOrgasm`、`_StartedAt` |
| `std::bitset<N> interactions` | `_CurrentInteractions`（N は `SUPPORTED_INTER_COUNT`） |
| `std::array<bool, 5> homoTypes` | `_HomoTypes` |
| `float enjoymentDelay = 0.8, loopEnjoymentDelay` | `_EnjoymentDelay`、`_LoopEnjoymentDelay` |
| `float voiceDelay, loopVoiceDelay, expressionDelay = 1.0, loopExpressionDelay, loopLovenseDelay` | `_VoiceDelay`、`_LoopVoiceDelay`、`_ExpressionDelay`、`_LoopExpressionDelay`、`_LoopLovenseDelay` |
| `bool busy` | なし（新規。声と表情の Papyrus の呼び出しの間、真にする。7.3） |

設定の値は `src/UserData/mcm.def` の値を直接読む（`bInternalEnjoymentEnabled`、`iClimaxType`、`fEnjRaiseMultInter`、`iNoPainRequiredXP`、`fPainHugePPMult`、`iNoPainRequiredTime`、`fEnjMultVictim`、`fEnjMultAggressor`、`fEnjMultSub`、`fEnjMultDom`、`bGameRequiredOnHighEnj`、`bNoStaminaEndsScene`、`bHighEnjOrgasmWait`、`bPlayerMustOrgasm`、`bDomMustOrgasm`、`iMaxNoPainOrgasmMale`、`iMaxNoPainOrgasmFemale`、`bMaleOrgasmEndsScene`、`fMaleVoiceDelay`、`fFemaleVoiceDelay`、`fSFXDelay`、`bSetAnimSpeedByEnjoyment`、`bOrgasmEffects`、`bFallbackToTagsForDetection`。いずれも `mcm.def` にあることを確かめた）。

### 7.2 計算の関数の移し先

| Papyrus の関数（行） | 移行後の Papyrus | 移行後の C++ |
|---|---|---|
| `sslThreadModel.ListDetectedInteractionsInternal`（:2101）、`ListDetectedPhysicsInteractionsInternal`（:2115）、`ListDetectedPosTagsInteractionsInternal`（:2148） | 本体を消し、native **`ListDetectedInteractionsNative(Actor, Actor)`** を呼ぶだけにする（`ApplyCumFX` などが使うので名前は残す） | **`Instance::ListDetectedInteractions(RE::Actor*, RE::Actor*)`**：:2117〜2143 の対応（行為の種類ごとに、どちらを先に渡すか）をそのまま写す。衝突の情報が無く、`bFallbackToTagsForDetection` が真でシーンに `PosTagged` があれば、位置のタグから作る。どれも無ければ `pAnal` だけ真 |
| `sslThreadModel.CalculateInteractionFactor`（:2356）、`CalcInterVelocityFactor`（:2376） | 削除 | **`Enjoyment::CalcInteractionFactor`**、**`CalcInterVelocityFactor`**（式は同じ。`0.25 + Σ (0.25 + factor/5) × (1 + |速度| × 11)`。衝突が無ければ速度の係数は 1.5） |
| `sslThreadModel.IdentifyConsentSubStatus`（:2418）、`CheckActiveHomoTypes`（:2434）、`CrtMaleHugePP`（:2448）、`ActorIsWithLover`（:2543）、`CheckLoverAssociation`（:2537） | 削除 | **`Instance::IdentifyConsentSubStatus`**、**`CheckActiveHomoTypes`**、**`HasCreatureMaleHugePP`**、**`ActorIsWithLover`**。恋人の判定は `PlayerMarriedFaction`（Skyrim.esm `0C6472`）、`SpouseAssocation`（Skyrim.esm `0142CA`）、関係のランク 4 以上で見る（`RE::BGSRelationship` を使う） |
| `sslActorAlias.UpdateBaseEnjoymentCalculations`（:1265）、`CalcContextPain`（:1312）、`CalcContextEnjFactor`（:1336） | 削除 | **`Enjoyment::UpdateBase(Instance&, Position&)`**。統計（`SexlabStatistics.GetStatistic(…, 17)`、`GetSexuality`）は `Registry::Statistics` を直接読む |
| `sslActorAlias.UpdateEffectiveEnjoymentCalculations`（:1285）、`CalcInteractionPain`（:1364）、`CalcEffectivePain`（:1382）、`CalcEffectiveEnjoyment`（:1412）、`UpdateArousalStat`（:1423）、`EnjFindConSubStatusMult`（:1428） | 削除 | **`Enjoyment::UpdateEffective(...)`**。スタミナが 10% 未満で終わる判定（:1297）も含む。`SetStatistic(…, 17)` は `Registry::Statistics` に直接書く |
| `sslActorAlias.CalcReaction`（:1446）、`WaitForOrgasm`（:1454） | 削除 | **`Enjoyment::CalcReaction`**、**`Enjoyment::WaitForOrgasm`** |
| `sslActorAlias.StoreExcitementState`（:1468） | 削除 | **`Thread::ExcitementStore`**（C++ の表。アクターの FormID ごとに時刻・絶頂の回数・快感を持つ）。今は `StorageUtil` にアクターの**名前**をキーにして保存しているが、FormID をキーにする（同じ名前の別のアクターが混ざる不具合が直る）。60 秒で薄れる式は同じ |
| `sslActorAlias.InitRaiseEnjAttempt`（:1487）、`OnRaiseEnjAttemptResult`（:1503） | 削除 | **`Enjoyment::InitRaiseAttempt`**、**`Enjoyment::OnRaiseAttemptResult`**。スタミナとマジカの増減は `AsActorValueOwner()->RestoreActorValue` / `DamageActorValue`。`EnjBarsOverlay.cpp:120` は Papyrus の `OnRaiseEnjAttemptResult` を呼ぶのをやめ、C++ を直接呼ぶ |
| `sslThreadModel.GameRaiseEnjoyment`（:2563）、`GameHoldback`（:2573）、`ProcessEnjGameArg`（:2583）、`OnRaiseEnjAttemptResult`（:2599） | 削除（呼んでいるのは HUD の C++ だけであることを P0 で確かめる） | **`Instance::ProcessEnjoymentGame(...)`** |
| `sslThreadModel.ThreadWaitsForOrgasm`（:2472） | 削除 | **`Instance::WaitsForOrgasm()`** |
| `sslThreadModel.CalcInstThreadAnimSpeed`（:2631）、`UpdateAnimationSpeed`（:2648）、`UpdateBaseSpeed`（:2627） | `UpdateBaseSpeed` は native **`SetBaseAnimSpeedNative(float)`** を呼ぶだけにする。ほかは削除 | **`Instance::UpdateAnimationSpeed()`**：`bSetAnimSpeedByEnjoyment` が真なら、各アクターの `基本の速さ × clamp(快感 / 90, 0.8, 1.2)` の最大、偽なら基本の速さ。既存の `SetAnimationPlaybackSpeed` に渡す |

### 7.3 アクターの更新ループ（`sslActorAlias.Animating.OnUpdate`、:766）

`OnUpdate` は**空にする**（外から呼ばれても何も起きない）。`Animating.OnBeginState` の `RegisterForSingleUpdate`（:744）、`DoOrgasm` の中の `UnregisterForUpdate` と `RegisterForSingleUpdate`（:906、:964）も消す。
代わりに **`Instance::UpdateActors(float a_delta)`**（`UpdateFlow` から、`flow == Playing` のときに毎フレーム呼ぶ）が、各アクターについて次を行う。今の 0.25 秒ごとの処理を、0.25 秒ごとのまま行う（毎フレームにはしない。快感の増え方を変えないため）。

| 今の処理（行） | 移行後 |
|---|---|
| `_CurrentInteractions` を取る（:774） | C++ の `ListDetectedInteractions(actor, nullptr)` → `Enjoyment::interactions` |
| `UpdateEffectiveEnjoymentCalculations`（:775） | `Enjoyment::UpdateEffective` |
| 快感バー（:776〜778） | 既存の `Instance::EnjBarsUpdateSlider` を C++ から直接呼ぶ（行為の文字列は `GetCurrentInteractionString` の C++ 版 **`Instance::GetInteractionString`** で作る） |
| `CalcReaction` が 100 なら `DoOrgasm`（:779〜782） | `Enjoyment::CalcReaction` → **`Instance::TryOrgasm(Position&, bool forced)`**（7.4） |
| 声（:783〜788） | `loopVoiceDelay ≥ voiceDelay` で、`busy` が偽なら、`busy = true` にしてキューで **`sslActorAlias.PlayVoiceNative(int strength)`**（新規。:785〜787 の処理：口パクを使うかの判定、`GetAliasSound`、`sslBaseVoice.PlaySound`）。終わったら `busy = false` |
| 表情（:789〜792） | `loopExpressionDelay ≥ 1.0` で、`busy` が偽なら、`busy = true` にしてキューで `RefreshExpressionEx(float)`（今のまま）。終わったら `busy = false` |
| Lovense（:793〜797） | プレイヤーで、開始のときに `sslLovense.IsLovenseInstalled()` を 1 回だけ `DispatchStaticCall` で確かめ、真なら、`loopLovenseDelay ≤ 0` のときにキューで `RefreshLovenseActions()`（今のまま） |
| VRIK（:798〜811） | 削除（VR は対象外） |
| 間隔の数え（:813〜815） | **`busy` が真の間は、そのアクターの間隔の数え（声・表情・快感・Lovense）を止める。** 今は声と表情の Papyrus の待ちの間、ループ全体が止まっているので、それに合わせる |

**声と表情を Papyrus に残す理由**：声は `PlayAndWait` と、表情の値を Papyrus の待ちで動かす口パク（`sslBaseVoice.MoveLips`）で鳴らしている。C++ で作り直すと、口パクの作り直しが要る。この計画では、呼ぶタイミングだけを C++ にする。

### 7.4 絶頂（`sslActorAlias.Animating.DoOrgasm`、:886）

| 今の処理（行） | 移行後 |
|---|---|
| 二重に入らない判定、`_CanOrgasm`、前回からの時間（男性とクリーチャー 20 秒、ほか 10 秒）（:887〜905） | C++ の **`Instance::TryOrgasm(Position&, bool forced)`** |
| `_OrgasmCount += 1`（:907） | C++（`Enjoyment::orgasmCount`） |
| 画面のゆれ・ホワイトアウト、絶頂の声、`OrgasmFX`、Lovense、`ApplyCumFX`、`SexLabOrgasm` と `SexlabOrgasmSeparate` のイベント、`TrackedEvent(ORGASM)`（:909〜942） | キューで **`sslActorAlias.OnOrgasmNative(int aiFullEnjoyment, int aiOrgasmCount)`**（新規）。引数の快感は**リセットする前の値**を渡す（今の `SexLabOrgasm` は、リセットの前に `_FullEnjoyment` を送っているため） |
| 快感のリセットと、回数が多いときの痛み（:945〜962） | C++（`Enjoyment` の中） |
| 男性の絶頂でシーンを終える（:954 `EnjBasedSkipToLastStage`） | P2 の間はキューで `sslThreadModel.EnjBasedSkipToLastStage(true)`（今のまま）。P3 で C++ に移す |
| `DoOrgasm` という名前 | 本体を消し、native **`DoOrgasmNative(bool forced)`** を呼ぶだけにする（`ForceOrgasm` などが使うので名前は残す） |
| `OnOrgasm`（:875。`SSL_ORGASM` を受ける） | 削除。`PlayNextImpl` と `TriggerOrgasm` は、`SSL_ORGASM` を送る代わりに native **`TriggerOrgasmNative(bool abStageDriven)`** を呼ぶ。C++ は全アクターについて `abStageDriven` なら `canOrgasm` のときだけ `TryOrgasm(forced = true)`、そうでなければ `TryOrgasm(false)`（:876〜884 と同じ） |

### 7.5 外部 MOD が使う関数（名前は残し、中身を native にする）

| 関数 | 移行後 |
|---|---|
| `sslThreadModel.GetEnjoyment` / `SetEnjoyment` / `AdjustEnjoyment` / `ModEnjoymentMult` / `DisableOrgasm` / `IsOrgasmAllowed` / `ForceOrgasm` / `GetOrgasmCount`（:174〜237） | 今はアクターの alias を探して alias の関数を呼ぶ。alias の関数が native を呼ぶようになるので、**今のまま** |
| `sslActorAlias.GetEnjoyment`（:55）、`SetEnjoyment`（:60）、`AdjustEnjoyment`（:64）、`ModEnjoymentMult`（:68）、`DisableOrgasm`（:39）、`IsOrgasmAllowed`（:43）、`GetOrgasmCount`（:47）、`GetCurrentInteractionFlags`（:80）、`GetPain`（:1695）、`GetFullEnjoyment`（:1703）、`BonusEnjoyment`（:1706）、`NeedsOrgasm`（:1716）、`SetOrgasmCount`（:1719） | native に変える（`sslActorAlias` の native として `src/Papyrus` に登録する。C++ の `Enjoyment` を読み書きする）。`IsVaginalComplex`、`IsAnalComplex`、`IsOralComplex`、`ShouldMouthOpen`、`IsAnalPenetrated`、`IsGenitalInteraction` は、中の `_CurrentInteractions` を `GetCurrentInteractionFlags()` に置き換える |

### 7.6 シーン枠の更新ループ（`sslThreadModel.Animating.OnUpdate`、:1365）

`OnUpdate` は**空にする**。`ConfigureStageTimer` の `RegisterForSingleUpdate`（:1304）も消す。
代わりに **`Instance::UpdatePlaying(float a_delta)`**（`flow == Playing` のときに毎フレーム）が次を行う。

| 今の処理（行） | 移行後 |
|---|---|
| `_initialRealignTicks`（:1370〜1375） | ステージの開始（`BeginAnimatingNative` の後）から 0.5 秒と 2.0 秒のときに、既存の `Instance::RealignActors()` を C++ から直接呼ぶ |
| 固定長でないステージのタイマー（:1376〜1383） | ステージのタイマーを**すべて** C++ の固定長タイマー（`fixedLengthTimer`）で数える。`ConfigureStageTimer`（:1290）は、`GetTimer()` の値と、`AutoAdvance` か強制かを、native **`ConfigureStageTimerNative(float afDuration, bool abCounts)`**（新規）で渡すだけにする。`abCounts` が偽のときは表示を 0 にし、数えない（今の :1299〜1300 と同じ）。切れたら既存の `OnFixedLengthStageComplete` → `AdvanceFromTimer`（P3 までは Papyrus） |
| `UpdateTimer`（:1307）、`PauseTimer`（:1317）、`EnjBasedSkipToLastStage` の `_StageTimer -= …`（:2616） | `UpdateTimer` は既存の `AdjustFixedLengthTimer` だけにする。`PauseTimer` は既存の `SetFixedLengthTimerPaused` だけにする。`_StageTimer` を減らす所は `AdjustFixedLengthTimer(-GetTimer() / 2)` にする。`_StageTimer`、`_StageDuration`、`_NativeFixedLengthTimer`、`_TimerPaused` の変数は削除 |
| `AutoAdvance`（Auto のプロパティ） | 外部 MOD が書き換えるので、Auto をやめて Get/Set を持つプロパティにする。Set の中で native **`SetAutoAdvanceNative(bool)`** を呼び、C++ のタイマーが数えるかどうかを変える |
| SFX（:1384〜1404） | **`Instance::UpdateSFX(float)`**：`sfxTimer` を減らし、0 以下で `ListDetectedInteractions(nullptr, nullptr)` を見て、`SexMixedFX`（SexLab.esm `065A33`）・`SuckingFX`（`065A32`）・`SquishingFX`（`065A31`）のどれかを選び、その `Sound` フォームの Papyrus の `Play(CenterRef)` を `DispatchMethodCall` で呼ぶ（新しいゲームのアドレスを使わない）。次は `fSFXDelay × 乱数(0.9〜1.3)`、最小 0.8 秒 |
| `UpdateAnimationSpeed`（:1405） | 7.2 の `Instance::UpdateAnimationSpeed()` を 0.5 秒ごとに呼ぶ |

### 7.7 P2 の終わりの条件

- アニメ中に、`sslThreadModel` と `sslActorAlias` のどちらにも `RegisterForSingleUpdate` が登録されていない（Papyrus のデバッグのログで確かめる）。
- 快感の増え方、絶頂の起きる間隔、声と表情の間隔、SFX の間隔が、P0 で測った今の値と同じ程度になる（同じシーンで、絶頂までの時間を 3 回ずつ測って比べる）。
- `SexLabOrgasm`、`SexlabOrgasmSeparate`、`SexLabApplyCumFX` のイベントが、今と同じ引数で来る。
- 外部 MOD の `GetEnjoyment` / `AdjustEnjoyment` / `ForceOrgasm` が効く。
- Rape Spell の外からの `onUpdate()` で、何も起きない。

---

## 8. P3 ステージの進行・イベント・フックの C++ 化

### 8.1 ステージの進行

ステージの履歴 `_StageHistory`（Papyrus の変数）の持ち主を C++ にする（**`Instance::stageHistory`**、`std::vector<const Registry::Stage*>`）。

| 関数（行） | 今の処理 | 移行後の Papyrus | 移行後の C++ |
|---|---|---|---|
| `GetStageHistory`（:30）、`GetStageHistoryLength`（:33）、`GetLegacyStageNum`（:36）、`Stage` のプロパティの Get（:645） | `_StageHistory` を読む | native に変える | `stageHistory` を返す |
| `Animating.StartStage`（:1245） | `StageStart` のイベント、`RunHook(STAGESTART)`、`AdvanceScene` | native **`StartStageNative(String[] asHistory, String asNextStageId)`** を呼ぶだけにする | **`Instance::StartStage(...)`**：同期中の印を立てる → キューで `SendThreadEvent("StageStart")` → キューで `RunHook(HOOKID_STAGESTART)` → 終わったら `AdvanceScene`（C++）で履歴を更新 |
| `Animating.PlayNext`（:1193） | `StageEnd` のイベントとフック、次のステージを決めて `PlayNextImpl` | native **`PlayNextNative(int)`** を呼ぶだけ | **`Instance::PlayNext(int branch)`**：キューで `SendThreadEvent("StageEnd")` → キューで `RunHook(HOOKID_STAGEEND)` → 次のステージを `Registry` で決めて `PlayNextImpl` |
| `Animating.PlayNextImpl`（:1199） | 次が無ければ `EndLeadIn` か `EndAnimation`。絶頂の処理。各アクターの `TryLockAndUnpause` と `UpdateNext`。`StartStage` | native **`PlayNextImplNative(String)`** を呼ぶだけ | **`Instance::PlayNextImpl(const Stage*)`**：次が無ければ `EndLeadIn()`（C++）かキューで `EndAnimation()`。`iClimaxType` が Legacy で、次のステージの種類が 2（絶頂）なら、キューで `SendThreadEvent("OrgasmStart")` → `TriggerOrgasm(stageDriven = true)`。Scene か、プレイヤーがいないなら、`Registry` の絶頂するアクターについて、キューで `SendThreadEvent("OrgasmStart")` → `TryOrgasm(false)`。各アクターについてキューで `TryLockAndUnpause()` と `UpdateNext(strip)`。`StartStage` |
| `Animating.GoToStage`（:1256） | 1.3 のとおり | native **`GoToStageNative(int)`** を呼ぶだけ | **`Instance::GoToStage(int)`**：同じ分け方。分岐の選択のメニューは既存の `OpenStageSelectMenuImpl` を C++ から呼ぶ |
| `Animating.BranchTo`（:1279）、`SkipTo`（:1282）、`ResetStage`（:1241） | `PlayNext` / `PlayNextImpl` / `GoToStage` を呼ぶ | 今のまま（呼ぶ先が native になる） | なし |
| `Animating.AdvanceFromTimer`（:1353）、`FindSimilarSceneStage`（:2485）、`CheckSpecificStageTags`（:2515） | 1.3 のとおり | 削除（`OnFixedLengthStageComplete` から C++ を直接呼ぶ） | **`Instance::AdvanceFromTimer()`**、**`FindSimilarSceneStage()`**（13 個のタグ `Oral`〜`PosSlow` が全部同じステージを探す。最初の 3 ステージは飛ばす。:2498 と同じ） |
| `Animating.ResetScene`（:1156）、`OnAnimationSynchronized`（:1538）、`OnAnimationSyncFailed`（:1511）、`OnFixedLengthStageComplete`（:1528） | 同期中の印、積まれたシーン、0.5 秒の受け付けない時間 | `ResetScene` は native **`ResetSceneNative(String)`** を呼ぶだけ。ほか 3 つは削除 | **`Instance::ResetScene(...)`**。`_animationSyncPending`、`_sceneResetSyncPending`、`_nextSceneResetAt`、`_queuedSceneReset` を C++ のメンバーにする。`UpdatePendingAnimations` は Papyrus を呼び返さず、`Instance::OnAnimationSynchronized()` / `OnAnimationSyncFailed()` を直接呼ぶ。`OnAnimationSynchronized` の中の HUD の更新・タイマーの設定は C++ から。初回の `AnimationStart`・`LeadInStart` のイベントはキューで `SendThreadEvent` |
| `Animating.EndLeadIn`（:1455） | `LeadInEnd` のイベント、主のシーンへ `ResetScene` | native を呼ぶだけ | **`Instance::EndLeadIn()`** |
| `EnjBasedSkipToLastStage`（:2607） | 1〜2 人で最後のステージでなければ、最後のステージへ飛び、タイマーを半分にし、基本の速さを 0.8 に | 削除 | **`Instance::SkipToLastStageByEnjoyment()`** |
| `Animating.ReStartTimer`（:1286）、`ConfigureStageTimer`（:1290）、`GetTimer`（:1330）、`GetStageTimer`（:1340）、`SetTimers`（:1322）、`Timers` のプロパティ | タイマーの値を決める | 今のまま（`GetTimer` と `Timers` は外部 MOD が使い、`_CustomTimers` は Papyrus の変数のため）。C++ は `ConfigureStageTimer` をキューで呼ぶ | なし |

### 8.2 フック

- `RunHook`（:2230）と `sslSystemConfig.RunHook`（:833）は**今のまま**。C++ はキューで `sslThreadModel.RunHook(int)` を呼び、終わってから次へ進む。フックが返るまで、そのシーン枠は今と同じく止まる。
- **`PapyrusCallQueue`** は `RunHook` の呼び出しにかかった時間を測り、1 秒（設定 **`fHookWarnTime`**、`mcm.def` に追加。既定は 1.0）を超えたら、フックの番号とシーン枠の番号と時間をログに出す。先へ進むことはしない。
- 呼ぶ位置と順番：`StartThread` の中（今のまま Papyrus）、`StartStage`（`StageStart` のイベントの後）、`PlayNext`（`StageEnd` のイベントの後）、`OnActorsClearedNative`（`AnimationEnd` のイベントの後）。今と同じ。

### 8.3 外部 MOD 向けのイベント

- `SendThreadEvent`（:2234）、`SetupThreadEvent`（:2243）は**今のまま** Papyrus に残す。型付きの ModEvent（`ModEvent.Create` と `Push*`）は、SKSE のプラグイン API では C++ から送れないため。
- C++ はキューで `SendThreadEvent(String)` を呼ぶ。キューが順に呼ぶので、フックやほかのイベントとの順番は今と同じになる。

### 8.4 シーンの移動（`sslThreadController.MoveScene`、:239）

| 今の処理（行） | 移行後 |
|---|---|
| 確認のメッセージ（:239〜262） | Papyrus に残す |
| 各アクターを `Paused` にし、プレイヤーを動けるようにする（:264〜271） | Papyrus に残し、最後に native **`BeginMoveSceneNative()`** を呼ぶ。`Utility.Wait` から後（:273〜）は C++ |
| 1 秒待って、移動のキーが押されるまで最大 30 秒待つ（:273〜278） | **`Instance::UpdateMoveScene(float)`**：1 秒後から、キー（設定 `iMoveScene`）が押されるか 30 秒たつまで待つ。キーの状態は `RE::BSInputDeviceManager` から読む（UI ホストと同じ方法） |
| プレイヤーを固定し、止まるまで 0.5 秒ごとに位置を比べる（:279〜290） | 同じ関数で、0.5 秒ごとに位置を比べる |
| 各アクターを戻し、`CenterOnObject(PlayerRef)`（:291〜） | キューで Papyrus の **`FinishMoveSceneNative()`**（新規。:291 以降の処理） |

### 8.5 P3 の終わりの条件

- ステージの手動の進行と自動の進行、分岐の選択、前のステージに戻る、シーンの変更、リードインからの移り、タイマーによる進行と、絶頂を待つための別のシーンへの移りが、今と同じに動く。
- `StageStart` / `StageEnd` / `OrgasmStart` などのイベントと、`OnStageStart` / `OnStageEnd` のフックが、今と同じ順で来る（`sslLog` と、テスト用のフックの MOD で確かめる）。
- わざと 3 秒かかるフックを入れると、そのシーン枠は 3 秒止まり、ログに警告が出る。ほかのシーン枠は止まらない。
- `MoveScene` が今と同じに動く。

---

## 9. P4 整理とログ

| 作業 | 対象 | 内容 |
|---|---|---|
| 使われなくなった関数の削除 | 6〜8 章で「削除」とした関数 | P0 で外部の呼び出しが無かったものだけ消す。あったものは「空にする」か「C++ への転送」にする |
| 使われなくなった変数の削除 | `sslThreadModel`：`_instanceCreationWaitLock` 以外の同期の変数（`_prepareAsyncCount`、`_animationSyncCount`、`_animationSyncPending`、`_sceneResetSyncPending`、`_nextSceneResetAt`、`_queuedSceneReset`、`_initialRealignTicks`、`_StageTimer`、`_StageDuration`、`_NativeFixedLengthTimer`、`_TimerPaused`、`_SFXTimer`、`_StageHistory`）。`sslActorAlias`：7.1 の表の変数 | Papyrus の変数を消しても、古いセーブの値は読み捨てられるだけ（ロードでシーンが終わるので、値は要らない） |
| ログ | `sslLog.Log`、`sslLog.Error`、`sslLog.LogImpl`（sslLog.psc） | `LogImpl` を native **`sslLog.LogImpl(String, bool)`** に変え、C++ の spdlog に出す（`Log` は情報、`Error` はエラーの重さで）。`Debug.Trace` / `Debug.TraceStack` は、設定 **`bPapyrusTrace`**（`mcm.def` に追加、既定は偽）が真のときだけ呼ぶ。`bDebugMode` のときのコンソールへの出力は今のまま |
| 外部 MOD 向けの文書 | `SexLabThread.psc` | 「外部 MOD は `SexLabThread` の関数を使う」「`sslThreadModel` の内部の関数（6〜8 章で native にしたもの）は呼ばない」と、ファイルの先頭のコメントと README に書く |

---

## 10. P5 同時に動かせるシーンの数（シーン枠の数）を設定で変える

| 対象（ファイル:行） | 今 | 変更 |
|---|---|---|
| ESM（`res/SexLab.esm/Quests/`） | `SexLabThread00`〜`14` | `SexLabThread15`〜`SexLabThread(用意する数−1)` を足す。各 Quest に、`sslThreadController` のスクリプトとプロパティ（`ActorAlias` 5 個、`CenterAlias`、`config`、`DoNothingPackage`、`InvalidCenterMsg`、`PlayerMarriedFaction`、`PlayerRef`、`SpouseAssocation` など、`SexLabThread00` と同じ）、ActorAlias 5 個（`sslActorAlias`）、`CenterAlias` を作る。既存の 15 個は変えない |
| `sslThreadSlots.GetTotalThreadCount`（:6） | `return 15` | native **`GetTotalThreadCount()`** にし、設定 **`iThreadCount`**（`mcm.def` に追加。15〜ESM の Quest の数）を返す |
| `sslThreadSlots.InstallSlots`（:127） | `new int[15]` に FormID を手で書く。`new sslThreadController[15]` | FormID の表を native **`GetThreadQuestFormIDs()`**（ESM の Quest を EditorID `SexLabThreadNN` で探して返す）から取る。配列は `Utility` の配列の作成の関数で、`GetTotalThreadCount()` の大きさで作る |
| `sslThreadSlots` の導入済みの判定（:125） | `Threads.Length == 15` | `Threads.Length == GetTotalThreadCount()` にする。上限を変えたら、次のロードで `InstallSlots` をやり直す |
| `SexLabThreadHook._m`（SexLabThreadHook.psc:27、:105、:110） | `OnInit` で 15 の大きさで作る。セーブに残る | `IsLocked` と `SetLocked` の中で、`_m.Length` が `GetTotalThreadCount()` より小さければ `Utility.ResizeBoolArray` で広げる（外部 MOD のフックは、このスクリプトを継承しているので、ここを直せば全部に効く） |
| C++ の `Instance` | 数の制限は無い（Quest に紐づく） | 変更なし |

**終わりの条件**：`iThreadCount` を 30 にして、30 のシーンを同時に動かせる。15 のときのセーブを読み込んでも壊れない。`SexLabThreadHook` を使う MOD で、シーン枠 16 以降の `IsLocked` がエラーにならない。

---

## 11. 変えない関数

次の関数は、引数・戻り値・中身を変えない（中で呼んでいる関数が native になるものはある）。

**`sslThreadModel`**

- 公開の関数（:10〜570）：`GetThreadID`、`GetActiveScene`、`GetActiveStage`、`GetPlayingScenes`、`StopAnimation`、`GetTime`、`GetTimeTotal`、`GetLegacyStagesCount`、`GetPositions`、`HasPlayer`、`HasActor`、`GetPositionIdx`、`GetNthPosition`、`GetActorSex`、`GetNthPositionSex`、`GetPositionSexes`、`SetCustomStrip`、`ResetCustomStrip`、`IsUndressAnimationAllowed`、`SetIsUndressAnimationAllowed`、`IsRedressAllowed`、`SetIsRedressAllowed`、`SetPathingFlag`、`SetActorVoice`、`GetActorVoice`、`GetActorExpression`、`SetActorExpression`、`SetActorMouthForcedOpen`、`GetEnjoyment`、`SetEnjoyment`、`AdjustEnjoyment`、`ModEnjoymentMult`、`DisableOrgasm`、`IsOrgasmAllowed`、`ForceOrgasm`、`GetOrgasmCount`、`CanBeImpregnated`、`IsUsingStrapon`、`SetStrapon`、`GetStrapon`、`IsConsent`、`SetConsent`、`GetSubmissives`、`SetIsSubmissive`、`GetSubmissive`、`IsVictim`、`IsAggressor`、`HasTag`、`HasSceneTag`、`IsVaginal`、`IsAnal`、`IsOral`、`HasStageTag`、`GetTags`、`HasContext`、`AddContext`、`RemoveContext`、`AddContextEx`、`IsLeadIn`、`IsInteractionRegistered`、`GetInteractionTypes`、`HasInteractionType`、`GetPartnerByType`、`GetPartnersByType`、`GetPartnerByTypeRev`、`GetPartnersByTypeRev`、`GetVelocity`、`GetCurrentInteractionFlags`、`HasCurrentInteractionFlag`、`HasCurrentInteractionFlagsAll`、`HasCurrentInteractionFlagsAny`、`GetCurrentInteractionString`、`GetCurrentInteractionStringA`、`IsVaginalComplex`、`IsAnalComplex`、`IsOralComplex`、`SetHook`、`RemoveHook`、`GetHooks`、`SetConfigsVRIK`
  - 例外：`GetStageHistory`、`GetStageHistoryLength`、`GetLegacyStageNum` は P3 で native にする（8.1）。
- `Making` の設定の関数：`AddActor`、`AddActors`、`AddActorsA`、`SetScenes`、`ClearScenes`、`SetForcedScenes`、`ClearForcedScenes`、`SetLeadInScenes`、`ClearLeadInScenes`、`AddScene`、`DisableLeadIn`、`SetFurnitureStatus`、`CenterOnObject`、`ContinueSetup`、と状態の外の同名の関数（:1013〜1064）
- `Animating` の `CenterOnObject`（:1409）、`RealignActors`（:1431）、`ChangeActors`（:1435）、`Initialize`（:1471）、`EndAnimation`（:1474）、`ResetAnimation`（:1484）、`ResetAnimationQuick`（:1489）、`OnSceneResetBySearch`（:1501）、`OnNativeActorsPrepared`（:1520）、`GetStatus`（:1564）、`OnEndState`（:1568）
- `Ending` の `ResetAnimation`（:1724）、`ResetAnimationQuick`（:1754）、`OnUpdateGameTime`（:1777）、`OnEndState`（:1780）、`GetStatus`（:1785）
- 状態によらない関数：`PickAlias`、`SetFurnitureIgnored`、`IndexTravelComplex`、`FindSlot`、`ActorAlias`、`PositionAlias`、`SortAliasesToPositions`、`GetAliasSound`、`GetAliasOrgasmSound`、`CalcPathingTargetDistance`（C++ に写すが Papyrus の版も残す）、`UpdateAnimatingActorMovement`、`MoveActorsAwayFromPlayer`、`RequestStatisticUpdate`、`UpdateEncounters`、`UpdateAllEncounters`、`TryInitSceneHUD`、`TryCloseSceneHUD`、`RefreshPropertiesSceneHUD`、`ApplyCumFX`、`RunHook`、`SendThreadEvent`、`SetupThreadEvent`、`SetTID`、`Initialize`、`Log`、`Fatal`
- Legacy の関数（:2655〜3511）すべて：`GetSetAnimationLegacyCast`、`LogConsole`、`LogRedundant`、`AddAnimation`、`SetAnimation`、`SetAnimationImpl`、`SetVoice`、`GetVoice`、`SetExpression`、`GetExpression`、`CheckTags`、`AddString`、`SyncDone`、`RefreshDone`、`ResetDone`、`StripDone`、`OrgasmDone`、`StartupDone`、`GetAnimationsLegacyCast`、`GetForcedAnimations`、`GetAnimations`、`GetLeadAnimations`、`GetHighestPresentRelationshipRank`、`GetLowestPresentRelationshipRank`、`GetHook`、`Action`、`FireAction`、`EndAction`、`InitShares`、`FilterAnimations`、`HookAnimationStarting`、`HookStageStart`、`HookStageEnd`、`HookAnimationEnd`、`SendTrackedEvent`、`SetupActorEvent`、`UpdateAdjustKey`、`Key`、`QuickEvent`、`GetPlayer`、`GetVictim`、`RemoveFade`、`ApplyFade`、`IsPlayerActor`、`IsPlayerPosition`、`GetPosition`、`GetPlayerPosition`、`DisableRagdollEnd`、`SetStartAnimationEvent`、`SetEndAnimationEvent`、`CenterOnBed`、`CenterOnCoords`、`AreUsingFurniture`、`ResolveTimers`、`SetStrip`、`SetNoStripping`、`UseLimitedStrip`、`DisableUndressAnimation`、`DisableRedress`、`DisablePathToCenter`、`ForcePathToCenter`、`StopTranslations`、`StartTranslations`、`SetAnimations`、`ClearAnimations`、`SetForcedAnimations`、`ClearForcedAnimations`、`SetLeadAnimations`、`ClearLeadAnimations`、`SetStartingAnimation`、`DisableBedUse`、`SetBedFlag`、`SetBedding`、`GetPain`、`DisableAllOrgasms`、`NeedsOrgasm`、`EquipStrapon`、`UnequipStrapon`、`PregnancyRisk`、`SetBonuses`、`RecordSkills`、とプロパティの get/set

**`sslThreadController`**：`MoveScene` の後半（8.4）以外のすべて（ホットキー、HUD、オフセットの調整、`AdvanceStage`、`ChangeAnimation`、`ChangePositions` など）。

**`sslActorAlias`**：7.5 で native にする関数と、6.2・7.3・7.4 で変える関数以外のすべて（`SetActor`、`Clear`、`Initialize`、`Setup`、`LockActor`、`UnlockActor`、`TryLockAndUnpause`、`TryPauseAndUnlock`、`InitiateUndressing`、`ReadyActor`、`UpdateNext`、`ResetPosition`、`Redress`、`RemoveStrapon`、`SetStrapon`、`ResolveStrapon`、`StripByData`、`StripByDataEx`、`GetStripSettings`、`SendDefaultAnimEvent`、`TrackedEvent`、`RefreshExpressionEx`、`RefreshLovenseActions`、`PlayLouder`、`OnCellDetach`、`OnUnload`、`OnDying`、Legacy の関数（:1551〜1818）など）。

---

## 12. 危険と対策

| 危険 | 影響 | 対策 |
|---|---|---|
| 外部 MOD が内部の関数やイベントを使っている | MOD が動かない | P0 で調べ、使われているものは消さずに転送にする（5 章） |
| C++ と Papyrus の状態のずれ | Papyrus の状態が C++ より遅れて移る。外部 MOD が `GetState()` で古い状態を見る | 状態は Papyrus 自身が移す（4.5）。C++ はキューで順に頼むので、順番は崩れない。遅れは 1〜数フレーム |
| 遅れて届いた知らせ | 時間切れの後に、前のシーンの知らせで状態が戻る | 世代の番号（4.3） |
| ロードの後の古いポインター | クラッシュ | `RevertCallback` で C++ のシーン枠のデータ（`Instance`）を捨てる（4.4） |
| 快感の増え方が変わる | 絶頂までの時間が変わる | 0.25 秒ごとの処理を 0.25 秒ごとのまま行い、声と表情の呼び出しの間は数えるのを止める（7.3）。P0 の数字と比べる（7.7） |
| Papyrus の VM のスレッドから C++ を触る | クラッシュ | キューの終わりの知らせはメインスレッドのタスクに回す（4.2）。native 関数（VM のスレッドで動く）から `Instance` を触るところは、既存の `_mInstances` のロックを取る |
| AE 1.7.104 の配置 | AE でだけ落ちる | 手順3（割り込み先と構造体の配置の確認）は、この計画とは別に後で行う。この計画で新しく使うゲームの関数は、`NotifyAnimationGraph`、`AsActorValueOwner()` の関数、`BGSRelationship`、`BSInputDeviceManager`（いずれも CommonLib にあり、既存のコードでも使っているもの）だけにし、新しいアドレスを足さない |

---

## 13. 確認のしかた

- **段階ごと**：SE 1.5.97 と AE 1.7.104 の両方でビルドし、6.4・7.7・8.5・10 章の終わりの条件を確かめる。
- **いつも確かめること**：2 人、3 人以上、クリーチャー、家具のシーンの開始から終了まで。同時に 3 つ以上のシーン。セーブとロード（進行中のシーンを含む）。
- **互換**：P0 の対象の MODを、改造なしで動かす。
- **効果**：P0 の計測を、各段階の後にやり直して比べる。

---

## 14. 決めてほしいこと

1. **P5 で ESM に用意するシーン枠の数と、既定で使う数**（例：ESM に 64 個用意し、既定は 15。CPU の数では決めない。用語の説明を参照）。

**決まったこと**（2026-10-07）

- AE 1.7.104 の確認（手順3）は、この計画とは別に後で行う。
- P0 で調べる MOD は、ユーザーが指定する。
- フックの時間の警告の値は 1 秒（`fHookWarnTime` の既定 1.0）。
- 内部の ModEvent（`SSL_PREPARE` / `SSL_READY` / `SSL_ORGASM` / `SSL_CLEAR`）は、外部 MOD が受けていても送り続けない。受けている MOD は対象外にする。

---

## 15. 敵対的レビューの記録

### 15.1 1 回目（2026-10-07、初版に対して）

| # | 重大度 | 初版の主張 | ソースで分かったこと | 直したところ |
|---|---|---|---|---|
| 1 | 高 | フックに時間の上限を付け、超えたら先へ進む | `SexLabThreadHook.psc` は「シーン枠を止めて、その間に読み書きしてよい」と約束している。先へ進むと、遅れて動いたフックがシーンの途中で書き込む | 8.2（警告だけ） |
| 2 | 高 | C++ から Papyrus の関数を呼び、戻りを待つ | フレームフックも VM もメインスレッドで動く。待つと止まる | 4.2（キューとコールバック） |
| 3 | 高 | `SexLabOrgasm` などのイベントを C++ から送る | 型付きのイベントは、SKSE のプラグイン API では送れない | 7.4、8.3（Papyrus に残す） |
| 4 | 高 | C++ の状態を co-save に保存する | ロードでシーンを終わらせるのが今の仕様。`Instance` は生の `Actor*` を持ち、`RevertCallback` で消していない | 4.4 |
| 5 | 中 | 準備の同期は ModEvent と待ち時間 | すでに `PrepareDone()` の数え上げがあり、30 秒の時間切れもある。固定の待ちは脱衣の 2 か所 | 1.1、6.1 |
| 6 | 中 | 声を C++ から直接鳴らす | 声は `PlayAndWait` か口パクで、ループを止めている | 7.3（呼ぶタイミングだけ C++） |
| 7 | 中 | 快感の計算を C++ へ | 値は Papyrus の変数にあり、外部 MOD が読む | 7.1、7.5（持ち主を C++ に） |
| 8 | 中 | P5 は Quest を足すだけ | 15 に依存する所がほかに 4 つある | 10 章 |
| 9 | 中 | Papyrus の状態は C++ を映すだけ | `GotoState` は Papyrus の中でしかできない | 4.5 |
| 10 | 低 | 遅いフックがほかのシーン枠を止める | 今もほとんど起きない | 8.2 |

### 15.2 2 回目（2026-10-07、ユーザーの指摘「どの関数をどうするのかが見えない」に対して）

初版と 1 回目の修正版は、「指揮」「Papyrus にしかできない処理」のような分け方だけを書き、関数の名前と移し先を書いていなかった。この版で、関数ごとの表（6〜8 章）、新しく作る C++ と Papyrus の関数の名前、変えない関数の一覧（11 章）を書いた。
また、1 回目で関数の数を「234 個」に直したのは数え方の誤り（小文字の `function` と、プロパティの get/set を数えていなかった）。正しくは 1.6 のとおり（`sslThreadModel` は 458 個、`sslActorAlias` は 201 個）。

この版を書くためにソースを読んで、新しく分かったこと：

| # | 内容 | 反映した所 |
|---|---|---|
| 1 | `StartThread` は呼んだ側に `sslThreadController` か `none` を返す約束があり、家具の選択の間も待つ必要がある。この `Utility.Wait(0.05)` は消せない | 2.1、6.1 |
| 2 | `AutoAdvance` は Auto のプロパティで、外部 MOD が書き換える。C++ のタイマーに知らせるには Get/Set を持つプロパティにする必要がある | 7.6 |
| 3 | `_CurrentInteractions` は、口を開けるかの判定（`ShouldMouthOpen`）など、alias の公開の関数 6 つが読んでいる | 7.5 |
| 4 | `StoreExcitementState` は、アクターの名前をキーに `StorageUtil` に保存している（同じ名前の別のアクターと混ざる） | 7.2（FormID をキーに） |
| 5 | 終了の後の待ち（ゲーム内 0.1 時間）は、`OnUpdate` の登録の漏れを避けるための作りで、外部 MOD が `AnimationEnd` の後にシーン枠を読む余裕にもなっている | 6.1（変えない） |
| 6 | SFX の音は ESM のフォーム（`065A31`〜`065A33`）。Papyrus の `Sound.Play` を `DispatchMethodCall` で呼べば、新しいゲームのアドレスは要らない | 7.6 |
