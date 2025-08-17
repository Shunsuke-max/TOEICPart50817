import SwiftUI

struct ScrambleSection: Identifiable {
    let id: String // themeをidとして使う
    let theme: String
    let subtitle: String // 新しく追加
    let questions: [SyntaxScrambleQuestion]
}

@MainActor
class ScrambleMapViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var error: Error?
    @Published var sections: [ScrambleSection] = [] 
    
    private let fileName = "syntax_scramble_vol1.json"

    func refreshProgress() {
        // ScrambleProgressManagerの状態が変更されたことをビューに通知
        objectWillChange.send()
    }

    func loadQuestions() async {
        self.isLoading = true
        do {
            let quizSet = try await DataService.shared.loadSyntaxScrambleSet(from: fileName)
            let groupedByTheme = Dictionary(grouping: quizSet.syntaxScrambleQuestions, by: { $0.theme })
            
            let themeSubtitles: [String: String] = [
                "基本文型 SVO + 後置修飾": "",
                "否定語の倒置": "",
                "基本文型 SVO": "",
                "基本文型 SVC": "",
                "to不定詞の名詞的用法": "",
                "名詞節 (間接疑問文)": "",
                "過去分詞の後置修飾": "",
                "動名詞主語": "",
                "基本文型 SVOO": "",
                "基本文型 SVOC": "",
                "強調構文": "",
                "助動詞 + 受動態": "",
                "関係代名詞": "",
                "so ～ that ... 構文": "",
                "仮定法（ifの省略と倒置）": "",
                "受動態": "",
                "主語と動詞の一致": "",
                "No sooner ... than 構文": "",
                "to不定詞の副詞的用法（目的）": "",
                "現在進行形": "",
                "依頼の表現": "",
                "基本的なビジネス語彙": "",
                "to不定詞（目的）": "",
                "関係代名詞 which": "",
                "比較級": "",
                "ビジネス語彙（効率化）": "",
                "仮定法過去完了": "",
                "倒置 (Not only... but also...)": "",
                "時事語彙（国際協力）": "",
                "使役動詞 have + 過去分詞": "",
                "未来形 will": "",
                "There is/are 構文": "",
                "提案・誘い": "",
                "予約する": "",
                "現在完了形": "",
                "動名詞を目的語にとる動詞": "",
                "経済用語": "",
                "会議用語": "",
                "知覚動詞 + O + -ing": "",
                "時事・政治用語": "",
                "契約・交渉用語": "",
                "関係副詞 where": "",
                "分詞構文": "",
                "最上級": "",
                "接続詞 Although": "",
                "使役動詞 let": "",
                "未来完了形": "",
                "動名詞目的語": "",
                "関係代名詞の所有格 whose": "",
                "付帯状況の with": "",
                "義務・助言 should": "",
                "It is ... for A to do": "",
                "仮定法 wish": "",
                "受動態の進行形": "",
                "提案 Let's": "",
                "無生物主語": "",
                "間接話法": "",
                "現在完了形（経験）": "",
                "句動詞": "",
                "The 比較級, the 比較級": "",
                "関係代名詞の目的格省略": "",
                "There is/are + 複数形": "",
                "責任": "",
                "as if + 仮定法": "",
                "環境問題": "",
                "be going to": "",
                "as ... as possible": "",
                "whatever, whoeverなど": "",
                "動詞 + A with B": "",
                "命令文": "",
                "It is no use -ing": "",
                "take advantage of": "",
                "How about -ing?": "",
                "not A but B": "",
                "keep O C": "",
                "前置詞 at, in, on": "",
                "either A or B": "",
                "倒置 (Little...)": "",
                "経済動向": "",
                "Can I ...?": "",
                "A is to B what C is to D": "",
                "It takes (人) 時間 to do": "",
                "be afraid of": "",
                "look forward to -ing": "",
                "受動態 by A to do B": "",
                "基本的な動詞 go": "",
                "too ... to do": "",
                "be likely to do": "",
                "Can you ...?": "",
                "remind A to do": "",
                "both A and B": "",
                "Would you like ...?": "",
                "despite + 名詞": "",
                "使役動詞 make": "",
                "be used to -ing": "",
                "倒置 (Only...)": "",
                "句動詞 (fall short of)": "",
                "It is ... of A to do": "",
                "neither A nor B": "",
                "使役動詞 get + O + to do": "",
                "現在完了進行形": "",
                "接続詞 as long as": "",
                "I'd like to ...": "",
                "関係副詞 why": "",
                "比較級 + than": "",
                "助動詞 + have + 過去分詞": "",
                "分詞構文（理由）": "",
                "持続可能性 (Sustainability)": "",
                "SVOOからSVOへの書き換え": "",
                "句動詞 (come up with)": "",
                "強調の do": "",
                "It goes without saying that...": "",
                "not so much A as B": "",
                "基本的な句動詞 (look for)": "",
                "関係代名詞 what": "",
                "all the 比較級 for...": "",
                "知覚動詞 + O + 原形不定詞": "",
                "have difficulty -ing": "",
                "ビジネス語彙 (implement)": "",
                "仮定法 (If it were not for...)": "",
                "be about to do": "",
                "分詞構文 (付帯状況)": "",
                "句動詞 (put up with)": "",
                "倒置 (so... that...構文)": "",
                "It is time + 仮定法": "",
                "what is called": "",
                "to say nothing of ...": "",
                "否定疑問文": "",
                "複合関係副詞 wherever": "",
                "使役動詞 have + O + 過去分詞 (被害)": "",
                "関係代名詞の非制限用法": "",
                "句動詞 (run out of)": "",
                "時事語彙 (tackle an issue)": "",
                "be supposed to do": "",
                "倒置 (Not until...)": "",
                "It dawns on (人) that...": "",
                "prevent O from -ing": "",
                "A is no more B than C is D": "",
                "譲歩の as": "",
                "all but": "",
                "make the most of": "",
                "仮定法 (Without...)": "",
                "倒置 (On no account...)": "",
                "be bound to do": "",
                "句動詞 (look down on)": "",
                "使役動詞 make の受動態": "",
                "時事語彙 (address an issue)": "",
                "完了不定詞 (to have p.p.)": "",
                "How often...?": "",
                "enable O to do": "",
                "be worth -ing": "",
                "倒置 (So do I / Neither do I)": "",
                "How about ...?": "",
                "in spite of": "",
                "used to do": "",
                "as if + 仮定法過去": "",
                "be able to": "",
                "provide A with B": "",
                "Let me...": "",
                "not only A but also B": "",
                "Nothing but": "",
                "句動詞 (turn down)": "",
                "知覚動詞 + O + 過去分詞": "",
                "take over": "",
                "It is no wonder that...": "",
                "be familiar with": "",
                "How long...?": "",
                "関係代名詞の挿入": "",
                "What ... for?": "",
                "so as to do": "",
                "分詞構文（否定）": "",
                "by the time": "",
                "be good at": "",
                "make sure": "",
                "仮定法 wish + 過去完了": "",
                "in case": "",
                "Can I ask you a favor?": "",
                "prefer A to B": "",
                "強調構文 (It is ... that ...)": "",
                "as soon as": "",
                "How much...?": "",
                "be supposed to": "",
                "倒置 (Hardly... when...)": "",
                "considering": "",
                "総合 (無生物主語 + so...that...)": ""
            ]

            let themeOrder = Array(themeSubtitles.keys).sorted() // 辞書のキーをソートして使用

            // 読み込みのたびにsectionsを初期化する
            var newSections: [ScrambleSection] = []
            newSections = themeOrder.compactMap { theme in
                guard let questions = groupedByTheme[theme] else { return nil }
                let sortedQuestions = questions.sorted { $0.difficultyLevel < $1.difficultyLevel } // 難易度でソート
                let subtitle = themeSubtitles[theme] ?? "" // サブタイトルを取得
                
                
                
                return ScrambleSection(id: theme, theme: theme, subtitle: subtitle, questions: sortedQuestions)
            }
            self.sections = newSections.sorted { (section1, section2) -> Bool in
                guard let firstQuestion1 = section1.questions.first else { return true } // Empty sections go to the end
                guard let firstQuestion2 = section2.questions.first else { return false } // Empty sections go to the end
                
                // Primary sort by difficulty level
                if firstQuestion1.difficultyLevel != firstQuestion2.difficultyLevel {
                    return firstQuestion1.difficultyLevel < firstQuestion2.difficultyLevel
                }
                // Secondary sort by theme name (alphabetical) for sections with same starting difficulty
                return section1.theme < section2.theme
            }
            
        } catch {
            self.error = error
        }
        self.isLoading = false
    }
}
