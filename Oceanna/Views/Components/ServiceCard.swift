import SwiftUI

struct ServiceCard: View {
    let service: Service

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.headline)

                Text(service.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("$\(Int(service.price))")
                    .font(.title3)
                    .fontWeight(.bold)

                Text(service.priceType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    VStack {
        ServiceCard(service: Service(
            name: "Logo Design",
            description: "Custom logo design with multiple revisions and source files",
            price: 150,
            priceType: .fixed
        ))

        ServiceCard(service: Service(
            name: "UI Consultation",
            description: "Review and feedback on your app's user interface",
            price: 75,
            priceType: .hourly
        ))
    }
    .padding()
}
