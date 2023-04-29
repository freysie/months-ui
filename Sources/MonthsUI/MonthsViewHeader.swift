#if os(iOS)

import UIKit

@available(iOS 15, *)
open class MonthsViewHeader: UICollectionReusableView {
  public let label = UILabel()
  public let stack = UIStackView()

  open var firstWeekday: Int = 1 { didSet { updateLabelPosition() } }

  public override init(frame: CGRect) {
    super.init(frame: frame)

    //layer.borderColor = UIColor.systemPink.cgColor
    //layer.borderWidth = 1

    label.font = .systemFont(ofSize: 21, weight: .semibold)
    label.textAlignment = .center
    label.adjustsFontForContentSizeCategory = true
    label.translatesAutoresizingMaskIntoConstraints = false
    //label.layer.borderColor = UIColor.systemPink.cgColor
    //label.layer.borderWidth = 1

    stack.distribution = .fillEqually
    stack.spacing = 0
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func updateLabelPosition() {
    stack.arrangedSubviews.forEach(stack.removeArrangedSubview(_:))

    for i in 0..<7 {
      stack.addArrangedSubview(i == firstWeekday ? label : UIView())
    }
  }
}

#endif
