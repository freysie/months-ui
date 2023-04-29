//import SwiftUI
//
//public struct MonthsView: UIViewControllerRepresentable {
//  public init() {}
//
//  // public init(in range: ClosedRange<Date>) {}
//  // public init(in range: PartialRangeFrom<Date>) {}
//  // public init(in range: PartialRangeThrough<Date>) {}
//
//  public func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
//
//  public func updateUIViewController(_ viewController: UIViewController, context: Context) {
//    let controller = MonthsViewController(
//      minimumDate: Calendar.current.date(from: DateComponents(year: 2023, month: 1))!,
//      maximumDate: Calendar.current.date(from: DateComponents(year: 2023, month: 4))!
//    )
//
//    controller.delegate = context.coordinator
//
//    DispatchQueue.main.async {
//      viewController.present(UINavigationController(rootViewController: controller), animated: false)
//    }
//  }
//
//  public func makeCoordinator() -> Coordinator {
//    Coordinator()
//  }
//
//  public class Coordinator: NSObject, MonthsViewControllerDelegate {
//    public func monthsViewController(_ monthsViewController: MonthsViewController, viewForDate date: Date) -> UIView? {
//      return UIImageView(image: UIImage(systemName: "tablecells")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [.systemPink])))
//    }
//  }
//}
//
//struct MonthsView_Previews: PreviewProvider {
//  static var previews: some View {
//    MonthsView()
//      .preferredColorScheme(.dark)
//  }
//}
