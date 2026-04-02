import SwiftUI

struct VPNWarningBanner: View {

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text("Обнаружен VPN — результаты могут быть неточными")
                .font(.subheadline)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.yellow.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
