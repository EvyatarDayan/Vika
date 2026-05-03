//
//  CompactSwitch.swift
//  Vika
//

import SwiftUI

/// `UISwitch` ignores `controlSize` on iOS; use scale + fixed layout for a smaller switch.
enum CompactSwitchMetrics {
    static let scale: CGFloat = 0.82
    static let layoutWidth: CGFloat = 51 * scale
    static let layoutHeight: CGFloat = 31 * scale
}

/// Label on the left, compact switch on the right (Edit Profile privacy toggles).
struct CompactLabeledToggleRow: View {
    @Binding var isOn: Bool
    let label: String
    var tint: Color = Color.appGreen

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            CompactSwitchControl(isOn: $isOn, accessibilityLabelText: label, tint: tint)
        }
    }
}

/// Compact switch for custom rows (e.g. Settings) where the label is laid out separately.
struct CompactSwitchControl: View {
    @Binding var isOn: Bool
    var accessibilityLabelText: String
    var tint: Color = Color.appGreen

    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .tint(tint)
            .scaleEffect(CompactSwitchMetrics.scale)
            .frame(width: CompactSwitchMetrics.layoutWidth, height: CompactSwitchMetrics.layoutHeight)
            .accessibilityLabel(Text(accessibilityLabelText))
    }
}
