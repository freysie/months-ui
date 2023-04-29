import SwiftUI
import MonthsUI
import DynamicColor
@testable import RingProgressView

let accent = UIColor.systemPurple

@main
struct MonthsUIExampleApp: App {
  var body: some Scene {
    WindowGroup {
      MonthsView()
        .ignoresSafeArea()
    }
  }
}

let calendar = {
  var calendar = Calendar.autoupdatingCurrent
  //calendar.timeZone = .gmt
  return calendar
}()
let today = calendar.startOfDay(for: Date())
let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today)!

let data = {
  var result = [Date: Double]()

  calendar.enumerateDates(
    startingAfter: oneYearAgo,
    matching: DateComponents(hour: 0, minute: 0, second: 0),
    matchingPolicy: .nextTime
  ) { date, exactMatch, stop in
    guard let date else { return }
    guard date <= today else { return stop = true }
    result[date] = .random(in: 0...1.66)
    if result[date]! < 0.15 { result[date] = 0 }
  }

  return result
}()

struct MonthsView: UIViewControllerRepresentable {
  init() {}

  func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

  func updateUIViewController(_ viewController: UIViewController, context: Context) {
    let controller = MonthsViewController(
      //minimumDate: calendar.date(from: DateComponents(year: 2023, month: 1))!,
      //maximumDate: calendar.date(byAdding: .month, value: 1, to: today)!,
      //todayColor: .systemMint,
      dayCellClass: MonthsViewRingProgressDayCell.self
    )

    controller.delegate = context.coordinator
    controller.isModalInPresentation = true
    controller.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""))
    controller.navigationItem.leftBarButtonItem!.tintColor = accent
    controller.todayColor = .systemGreen

//    Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
//      controller.todayColor = [.systemGreen, .systemBrown, .systemMint, .systemPink].randomElement()!
//    }

    DispatchQueue.main.async {
      viewController.present(UINavigationController(rootViewController: controller), animated: false)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator: NSObject, MonthsViewControllerDelegate {
    func monthsViewController(_ monthsViewController: MonthsViewController, prepare cell: UICollectionViewCell, for date: Date) {
      guard let cell = cell as? MonthsViewRingProgressDayCell else { return }

      if let value = data[date] {
        cell.imageView.image = ringImage(for: value)
      } else {
        cell.imageView.image = emptyRingImage
      }
    }

    func monthsViewController(_ monthsViewController: MonthsViewController, shouldSelectDate date: Date) -> Bool {
      date <= today
    }

    func monthsViewController(_ monthsViewController: MonthsViewController, didSelectDate date: Date) {
      print((#function, date))
    }

    func monthsViewController(_ monthsViewController: MonthsViewController, prefetchItemsIn dateInterval: DateInterval) {
      print((#function, dateInterval))
    }
  }
}

struct MonthsView_Previews: PreviewProvider {
  static var previews: some View {
    MonthsView()
      .preferredColorScheme(.dark)
  }
}

class MonthsViewRingProgressDayCell: MonthsViewDayCell {
  let imageView = UIImageView()

  override var isHighlighted: Bool {
    didSet {
      UIView.animate(withDuration: 0.2) { [self] in
        if isHighlighted {
          indicator.alpha = 1
          imageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } else {
          if !isToday { indicator.alpha = 0 }
          imageView.transform = .identity
        }
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.layer.cornerRadius = 40 / 2
    contentView.addSubview(imageView)

    NSLayoutConstraint.activate([
      imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      imageView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: -5),
      imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      imageView.widthAnchor.constraint(equalToConstant: 40),
      imageView.heightAnchor.constraint(equalToConstant: 40),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.userInterfaceStyle == .light {
      imageView.layer.backgroundColor = UIColor.black.cgColor
    } else {
      imageView.layer.backgroundColor = nil
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    imageView.image = nil
  }
}

#if os(macOS)
let screenScale = NSScreen.main?.backingScaleFactor ?? 1
#elseif os(watchOS)
let screenScale = WKInterfaceDevice.current().screenScale
#else
let screenScale = UIScreen.main.scale
#endif

var cachedRingImages = [Double: UIImage]()
var emptyRingImage = ringImage(for: 0, hidesRingForZeroProgress: true, caching: false)

func ringImage(for progress: Double, hidesRingForZeroProgress: Bool = false, caching: Bool = true) -> UIImage {
  let progress = (progress * 100).rounded() / 100
  if caching, let image = cachedRingImages[progress] { return image }

  let size = CGSize(width: 40, height: 40)
  UIGraphicsBeginImageContextWithOptions(size, false, screenScale)

  let inset = 1 / screenScale
  UIGraphicsGetCurrentContext()!.translateBy(x: inset, y: inset)

  let layer = RingProgressLayer()
  layer.bounds.size = CGSize(width: size.width - inset * 2, height: size.height - inset * 2)
  layer.progress = progress
  layer.ringWidth = 8
  layer.startColor = accent.cgColor
  layer.endColor = accent.lighter(amount: 0.05).cgColor
  layer.hidesRingForZeroProgress = hidesRingForZeroProgress
  layer.drawContent(in: UIGraphicsGetCurrentContext()!)

  let image = UIGraphicsGetImageFromCurrentImageContext()!
  UIGraphicsEndImageContext()
  if caching { cachedRingImages[progress] = image }
  return image
}
