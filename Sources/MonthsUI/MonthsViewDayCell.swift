#if os(iOS)

import UIKit

@available(iOS 15, *)
open class MonthsViewDayCell: UICollectionViewCell {
  public let label = UILabel()
  public let circleLayer = CAShapeLayer()
  public let indicator = UIView()
  open var isToday = false { didSet { updateCircle() } }
  open var circleSize = 24.0
  open var todayCircleColor = UIColor.systemRed
  open var defaultCircleColor = UIColor.systemGray.withAlphaComponent(0.5)

  public override init(frame: CGRect) {
    super.init(frame: frame)

    label.font = .systemFont(ofSize: 15)
    label.textAlignment = .center
    label.adjustsFontForContentSizeCategory = true
    label.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(label)

    circleLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: circleSize, height: circleSize)).cgPath
    circleLayer.fillColor = defaultCircleColor.cgColor

    indicator.layer.addSublayer(circleLayer)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    contentView.insertSubview(indicator, belowSubview: label)

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      label.topAnchor.constraint(equalTo: contentView.topAnchor),

      indicator.centerXAnchor.constraint(equalTo: label.centerXAnchor),
      indicator.centerYAnchor.constraint(equalTo: label.centerYAnchor),
      indicator.widthAnchor.constraint(equalToConstant: circleSize),
      indicator.heightAnchor.constraint(equalToConstant: circleSize),
    ])
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open func updateCircle() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)

    label.textColor = isToday ? .white : .label

    if isToday {
      indicator.alpha = 1
      circleLayer.fillColor = todayCircleColor.cgColor
    } else {
      indicator.alpha = 0
      circleLayer.fillColor = defaultCircleColor.cgColor
    }

    CATransaction.commit()
  }

  open override func prepareForReuse() {
    super.prepareForReuse()

    label.text = nil
    isToday = false
  }
}

#endif
