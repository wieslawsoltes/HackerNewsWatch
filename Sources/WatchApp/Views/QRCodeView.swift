import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let url: URL
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        VStack(spacing: 8) {
            if let image = generateQR(from: url.absoluteString) {
                Image(decorative: image, scale: 1.0)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Text("Failed to generate QR")
                    .foregroundStyle(.secondary)
            }
            Text("Scan on iPhone to open")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Open on Phone")
    }
    
    private func generateQR(from string: String) -> CGImage? {
        filter.message = Data(string.utf8)
        filter.correctionLevel = .quartile
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)) else { return nil }
        return context.createCGImage(output, from: output.extent)
    }
}
