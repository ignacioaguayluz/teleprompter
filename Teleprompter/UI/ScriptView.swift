import SwiftUI
import TeleprompterCore

/// Presentational: renders the script, highlights the next word, dims read text,
/// and keeps the current line in the reading zone (S3, S5, S8).
struct ScriptView: View {
    /// Vertical position of the reading zone as a fraction of the window height (S5).
    static let readingZone = UnitPoint(x: 0.5, y: 0.3)

    let script: Script
    let cursor: Int
    let currentWord: Int?
    let currentLine: Int?
    let fontSize: Double
    let onTapWord: (Int) -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: fontSize * 0.5) {
                        ForEach(script.lines.indices, id: \.self) { index in
                            line(script.lines[index])
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, geometry.size.height * Self.readingZone.y)
                    .padding(.bottom, geometry.size.height * (1 - Self.readingZone.y))
                }
                .scrollIndicators(.never)
                .onChange(of: currentLine) { _, line in
                    withAnimation(.easeInOut(duration: 0.15)) { proxy.scrollTo(line, anchor: Self.readingZone) }
                }
                .onChange(of: script) { _, _ in proxy.scrollTo(currentLine, anchor: Self.readingZone) }
                .onAppear { proxy.scrollTo(currentLine, anchor: Self.readingZone) }
            }
        }
    }

    @ViewBuilder
    private func line(_ line: Script.Line) -> some View {
        let font = Font.system(size: line.kind == .heading ? fontSize * 1.15 : fontSize,
                               weight: line.kind == .heading ? .bold : .regular)
        if line.wordRange.isEmpty {
            Text(line.text).font(font).foregroundStyle(.secondary)
        } else {
            FlowLayout(spacing: fontSize * 0.28, rowSpacing: fontSize * 0.18) {
                ForEach(line.wordRange, id: \.self) { index in
                    word(index, font: font)
                }
            }
        }
    }

    private func word(_ index: Int, font: Font) -> some View {
        let isCurrent = index == currentWord
        return Text(script.words[index].display)
            .font(font)
            .foregroundStyle(index <= cursor ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))
            .padding(.horizontal, 3)
            .background(isCurrent ? Color.accentColor.opacity(0.35) : .clear, in: .rect(cornerRadius: 6))
            .contentShape(.rect)
            .onTapGesture { onTapWord(index) }
    }
}
