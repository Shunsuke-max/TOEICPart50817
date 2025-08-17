import SwiftUI
import UIKit
import SwiftData

struct StudyCalendarView: View {
    let studiedDates: Set<DateComponents>
    // ★ 追加: 選択された日付を外部と同期するためのBinding
    @Binding var selectedDate: Date?

    var body: some View {
        CalendarViewRepresentable(studiedDates: studiedDates, selectedDate: $selectedDate)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// UIKitのUICalendarViewをSwiftUIで利用するためのラッパー
private struct CalendarViewRepresentable: UIViewRepresentable {
    let studiedDates: Set<DateComponents>
    // ★ 追加: selectedDateのBindingを受け取る
    @Binding var selectedDate: Date?

    func makeCoordinator() -> Coordinator {
        // ★ 修正: CoordinatorにBindingを渡す
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = Calendar.current
        
        // --- ★ ここからが選択機能の追加部分 ---
        
        // 1. SingleDateSelectionオブジェクトを作成し、delegateとしてCoordinatorを設定
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = selection
        
        // --- ここまで ---
        
        calendarView.wantsDateDecorations = true
        calendarView.setContentCompressionResistancePriority(.required, for: .vertical)
        return calendarView
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // データが実際に変更されたか確認
        if context.coordinator.parent.studiedDates != self.studiedDates {
            context.coordinator.parent = self
            uiView.reloadDecorations(forDateComponents: Array(self.studiedDates), animated: true)
        }
    }

    // ★★★ Coordinatorを大幅に修正 ★★★
    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarViewRepresentable

        init(parent: CalendarViewRepresentable) {
            self.parent = parent
        }
        
        // --- 装飾用のデリゲートメソッド (変更なし) ---
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            if parent.studiedDates.contains(dateComponents) {
                return .default(color: UIColor.orange.withAlphaComponent(0.3), size: .large)
            } else {
                return nil
            }
        }
        
        // --- ★ 新設: 日付が選択されたときに呼ばれるデリゲートメソッド ---
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            // 選択された日付をDateオブジェクトに変換し、@Bindingを通じて親Viewに通知
            if let dateComponents = dateComponents {
                parent.selectedDate = Calendar.current.date(from: dateComponents)
            } else {
                parent.selectedDate = nil
            }
        }
    }
}
