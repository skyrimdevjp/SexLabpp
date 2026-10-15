ScriptName SexLabStatistics Hidden
{
  統計情報アクセス用のグローバルスクリプト
}

; 現在追跡中の全アクターを含む配列を返す
Actor[] Function GetAllTrackedActors() native global
; 上記と同じだが、重複するアクターを除外し、表示名の辞書順で並べた一覧を返す
Actor[] Function GetAllTrackedUniqueActorsSorted() native global

int Property LastUpdate_GameTime  = 0   AutoReadOnly
int Property SecondsInScene       = 1   AutoReadOnly
int Property XP_Vaginal           = 2   AutoReadOnly
int Property XP_Anal              = 3   AutoReadOnly
int Property XP_Oral              = 4   AutoReadOnly
int Property PartnersMale         = 5   AutoReadOnly
int Property PartnersFemale       = 6   AutoReadOnly
int Property PartnersFuta         = 7   AutoReadOnly
int Property PartnersCreature     = 8   AutoReadOnly
int Property TimesOral            = 9   AutoReadOnly
int Property TimesVaginal         = 10  AutoReadOnly
int Property TimesAnal            = 11  AutoReadOnly
int Property TimesMasturbated     = 12  AutoReadOnly
int Property TimesSubmissive      = 13  AutoReadOnly
int Property TimesDominant        = 14  AutoReadOnly
int Property TimesTotal           = 15  AutoReadOnly
int Property Sexuality            = 16  AutoReadOnly
int Property Arousal              = 17  AutoReadOnly

; 統計値を取得する。IDには上記のいずれかを指定する
float Function GetStatistic(Actor akActor, int id) native global

int Property Sexuality_Hetero = 0 AutoReadOnly
int Property Sexuality_Homo   = 1 AutoReadOnly
int Property Sexuality_Bi     = 2 AutoReadOnly

; 指定されたアクターの性的嗜好の対応値を取得する（上記参照）
int Function GetSexuality(Actor akActor) native global
int Function MapSexuality(float aiSexualityStat) native global

; --- カスタム統計

; このアクター専用のカスタム統計を設定する。統計名はすべての型を通じて一意でなければならない
; 統計がまだ存在しない場合は作成する
Function SetCustomStatFlt(Actor akActor, String asStat, float afValue) native global
Function SetCustomStatStr(Actor akActor, String asStat, String asValue) native global

; このアクターのカスタム統計を取得する。存在しない場合、または型が一致しない場合は'default'を返す
float Function GetCustomStatFlt(Actor akActor, String asStat, float afDefault = 0.0) native global
String Function GetCustomStatStr(Actor akActor, String asStat, String asDefault = "") native global

; 指定されたアクターにカスタム統計が設定されているか確認する
bool Function HasCustomStat(Actor akActor, String asStat) native global
; このアクターのカスタム統計を削除し、メモリを解放する
Function DeleteCustomStat(Actor akActor, String asStat) native global

; --- 遭遇統計
int Property ENC_Any 			  = 0	AutoReadOnly Hidden
int Property ENC_Victim		  = 1	AutoReadOnly Hidden
int Property ENC_Assault	  = 2	AutoReadOnly Hidden
int Property ENC_Submissive	= 3	AutoReadOnly Hidden
int Property ENC_Dominant	  = 4	AutoReadOnly Hidden

; このアクターとの全遭遇を、最も古いものから並べた一覧で返す
Actor[] Function GetAllEncounters(Actor akActor) native global
; このアクターが襲った全アクターの配列を返す
Actor[] Function GetAllEncounteredVictims(Actor akActor) native global
Actor[] Function GetAllEncounteredAssailants(Actor akActor) native global
; 指定された種類の最も最近の遭遇を返す
Actor Function GetMostRecentEncounter(Actor akActor, int aiEncounterType) native global
; 2人のアクターが遭遇した時刻をGameDaysPassedで取得する
float Function GetLastEncounterTime(Actor akActor, Actor akPartner) native global
; 2人のアクターが遭遇した回数
int Function GetTimesMet(Actor akActor, Actor akPartner) native global
int Function GetTimesVictimzed(Actor akActor, Actor akAssailant) native global
int Function GetTimesAssaulted(Actor akActor, Actor akVictim) native global
int Function GetTimesSubmissive(Actor akActor, Actor akPartner) native global
int Function GetTimesDominant(Actor akActor, Actor akPartner) native global

; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;
; ----------------------------------------------------------------------------- ;
;        ██╗███╗   ██╗████████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗            ;
;        ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║            ;
;        ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝██╔██╗ ██║███████║██║            ;
;        ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║            ;
;        ██║██║ ╚████║   ██║   ███████╗██║  ██║██║ ╚████║██║  ██║███████╗       ;
;        ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝       ;
; ----------------------------------------------------------------------------- ;
; *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-* ;

String[] Function GetAllCustomStatIDs(Actor akActor) native global
Function SetStatistic(Actor akActor, int id, float afValue) native global
Function SetSexuality(Actor akActor, int mapping) native global
Function AddEncounter(Actor akActor, Actor akPartner, int aiEncounterType) native global
Function ResetStatistics(Actor akActor) native global
