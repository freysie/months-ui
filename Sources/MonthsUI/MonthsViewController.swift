#if os(iOS)

import UIKit

// TODO: add an option for doing the underscroll thing like in Fitness.app

@available(iOS 15, *)
@objc public protocol MonthsViewControllerDelegate: NSObjectProtocol {
  //@objc optional func monthsViewController(_ monthsViewController: MonthsViewController, viewForDate date: Date) -> UIView?
  @objc optional func monthsViewController(_ monthsViewController: MonthsViewController, prepare cell: UICollectionViewCell, for date: Date)
  @objc optional func monthsViewController(_ monthsViewController: MonthsViewController, shouldSelectDate date: Date) -> Bool
  @objc optional func monthsViewController(_ monthsViewController: MonthsViewController, didSelectDate date: Date)
  @objc optional func monthsViewController(_ monthsViewController: MonthsViewController, prefetchItemsIn dateInterval: DateInterval)
  @objc optional func monthsViewController(_ monthsViewController: MonthsViewController, cancelPrefetchingForItemsIn dateInterval: DateInterval)
}

@available(iOS 15, *)
open class MonthsViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching {

  public static let shiftAmount = 3
  public static let weekdaysViewHeight = 20.0
  public static let monthHeaderIdentifier = "monthHeader"
  public static let dayCellIdentifier = "dayCell"

  open weak var delegate: MonthsViewControllerDelegate?

  public private(set) var calendar: Calendar
  public private(set) var minimumDate: Date?
  public private(set) var maximumDate: Date?

  public var todayColor: UIColor? {
    didSet { collectionView.reloadItems(at: [indexPath(forDate: today)]) }
  }

  private var fromDate: Date!
  private var toDate: Date!
  private var today: Date!

  public init(
    calendar _calendar: Calendar = .autoupdatingCurrent,
    minimumDate: Date? = nil,
    maximumDate: Date? = nil,
    //todayColor: UIColor? = nil,
    dayCellClass: UICollectionViewCell.Type = MonthsViewDayCell.self
  ) {
    //calendar = Calendar(identifier: .gregorian)
    calendar = _calendar
    //calendar.locale = .autoupdatingCurrent
    calendar.locale = Locale(identifier: Locale.preferredLanguages[0])
    //calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    //calendar.timeZone = .gmt

    super.init(collectionViewLayout: MonthsViewLayout())

    self.minimumDate = minimumDate.map(dateWithoutTimeComponents(_:))
    self.maximumDate = maximumDate.map(dateWithoutTimeComponents(_:))
    //self.todayColor = todayColor

    additionalSafeAreaInsets = UIEdgeInsets(top: Self.weekdaysViewHeight, left: 0, bottom: 0, right: 0)
    installsStandardGestureForInteractiveMovement = false

    collectionView.isScrollEnabled = true
    collectionView.showsVerticalScrollIndicator = false
    collectionView.prefetchDataSource = self

    collectionView.register(
      MonthsViewHeader.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: Self.monthHeaderIdentifier
    )

    collectionView.register(dayCellClass, forCellWithReuseIdentifier: Self.dayCellIdentifier)

    let navigationBarAppearance = UINavigationBarAppearance()
    navigationBarAppearance.configureWithTransparentBackground()
    navigationItem.standardAppearance = navigationBarAppearance
    navigationItem.scrollEdgeAppearance = navigationBarAppearance
    navigationItem.compactAppearance = navigationBarAppearance
    // if #available(iOS 15.0, *) {
      navigationItem.compactScrollEdgeAppearance = navigationBarAppearance
    // }

    let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!

    if let minimumDate {
      fromDate = dateWithFirstDayOfMonth(minimumDate)
    } else {
      fromDate = calendar.date(byAdding: .month, value: -Self.shiftAmount, to: thisMonth)
    }

    if let maximumDate {
      toDate = dateWithFirstDayOfNextMonth(maximumDate)
    } else {
      toDate = calendar.date(byAdding: .month, value: Self.shiftAmount, to: thisMonth > fromDate ? thisMonth : fromDate)
    }

    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    effectView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(effectView)

    let border = UIView()
    border.backgroundColor = .separator
    border.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(border)

    let dateFormatter = DateFormatter()
    dateFormatter.locale = calendar.locale!

    let weekdaySymbols = dateFormatter.veryShortStandaloneWeekdaySymbols!
    let localizedWeekdays: [String] = Array(
      weekdaySymbols[calendar.firstWeekday - 1 ..< calendar.shortWeekdaySymbols.count] + weekdaySymbols[0 ..< calendar.firstWeekday - 1]
    )

    let weekdaysView = UIStackView(arrangedSubviews: localizedWeekdays.map {
      let label = UILabel()
      label.font = .systemFont(ofSize: 11, weight: .medium)
      label.text = "\($0)"
      label.textAlignment = .center
      label.textColor = .secondaryLabel
      label.translatesAutoresizingMaskIntoConstraints = false
      return label
    })
    weekdaysView.distribution = .fillEqually
    weekdaysView.spacing = 0
    weekdaysView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(weekdaysView)

    NSLayoutConstraint.activate([
      effectView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      effectView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      effectView.topAnchor.constraint(equalTo: view.topAnchor),
      effectView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

      border.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
      border.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
      border.topAnchor.constraint(equalTo: effectView.bottomAnchor),
      border.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

      weekdaysView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 5),
      weekdaysView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -5),
      weekdaysView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
      weekdaysView.heightAnchor.constraint(equalToConstant: Self.weekdaysViewHeight),
    ])

    today = dateWithoutTimeComponents(Date())

    collectionView.reloadData()
    collectionView.layoutIfNeeded()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(significantTimeChanged(_:)),
      name: UIApplication.significantTimeChangeNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(currentLocaleChanged(_:)),
      name: NSLocale.currentLocaleDidChangeNotification,
      object: nil
    )
  }

  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc func significantTimeChanged(_ notification: Notification) {
    today = dateWithoutTimeComponents(Date())
    collectionView.reloadData()
    // restoreSelection()
  }

  @objc func currentLocaleChanged(_ notification: Notification) {
    // TODO: update weekdays view, etc.
  }

  open override func viewWillAppear(_ animated: Bool) {
    // FIXME: only do this first time view will appear?
    scrollToToday(animated: false)
    super.viewWillAppear(animated)
  }

  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if minimumDate == nil && collectionView.contentOffset.y < 0 {
      applyPastDates()
    }

    if maximumDate == nil && collectionView.contentOffset.y > collectionView.contentSize.height - collectionView.bounds.height {
      applyFutureDates()
    }
  }

  // MARK: - Collection View Data Source Prefetching

  open func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    delegate?.monthsViewController?(self, prefetchItemsIn: dateInterval(at: indexPaths))
  }

  open func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    delegate?.monthsViewController?(self, cancelPrefetchingForItemsIn: dateInterval(at: indexPaths))
  }

  // MARK: - Collection View Data Source

  open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//    NSLog("%lu, %@, %lld, %lld", section, dateForFirstDayInSection(section) as NSDate, numberOfWeeksForMonthOfDate(dateForFirstDayInSection(section)), calendar.daysInWeek * numberOfWeeksForMonthOfDate(dateForFirstDayInSection(section)))
    //print((section, dateForFirstDayInSection(section) as NSDate, numberOfWeeksForMonthOfDate(dateForFirstDayInSection(section)), calendar.daysInWeek * numberOfWeeksForMonthOfDate(dateForFirstDayInSection(section))))
    return calendar.daysInWeek * numberOfWeeksForMonthOfDate(dateForFirstDayInSection(section))
  }

  open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.dayCellIdentifier, for: indexPath) as! MonthsViewDayCell

    delegate?.monthsViewController?(self, prepare: cell, for: dateForCell(at: indexPath))

    return cell
  }

  open override func numberOfSections(in collectionView: UICollectionView) -> Int {
    calendar.dateComponents([.month], from: fromDate, to: toDate).month!
  }

  open override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    delegate?.monthsViewController?(self, shouldSelectDate: dateForCell(at: indexPath)) ?? true
  }

  open override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    let (date, isInMonth) = dateAndIsInMonthForCell(at: indexPath)
    guard isInMonth else { return false }
    return delegate?.monthsViewController?(self, shouldSelectDate: date) ?? true
  }

  open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    delegate?.monthsViewController?(self, didSelectDate: dateForCell(at: indexPath))
  }

  open override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionView.elementKindSectionHeader:
      let header = collectionView.dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: Self.monthHeaderIdentifier,
        for: indexPath
      ) as! MonthsViewHeader

      let date = dateForFirstDayInSection(indexPath.section)
      let month = calendar.component(.month, from: date)
      let weekday = calendar.component(.weekday, from: date)

      header.label.text = "\(calendar.shortMonthSymbols[month - 1])"//.localizedCapitalized
      header.firstWeekday = reorderedWeekday(weekday)

      return header

    default:
      fatalError()
    }
  }

  // MARK: - Collection View Delegate

  open override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard let cell = cell as? MonthsViewDayCell else { return }

    let (cellDate, isInMonth) = dateAndIsInMonthForCell(at: indexPath)

    todayColor.map { cell.todayCircleColor = $0 }
    cell.label.text = "\(calendar.component(.day, from: cellDate))"
    cell.isToday = isInMonth && calendar.isDateInToday(cellDate)
    cell.contentView.isHidden = !isInMonth
  }

  // MARK: - Scrolling

  func scrollToDate(_ date: Date, animated: Bool) {
    if let minimumDate, date.compare(minimumDate) == .orderedAscending { return }
    if let maximumDate, date.compare(maximumDate) == .orderedDescending { return }

    let month = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!

    if minimumDate == nil {
      fromDate = dateWithFirstDayOfMonth(calendar.date(byAdding: .month, value: -Self.shiftAmount, to: month)!)
    }

    if maximumDate == nil {
      toDate = dateWithFirstDayOfMonth(calendar.date(byAdding: .month, value: Self.shiftAmount, to: month)!)
    }

    collectionView.reloadData()
    collectionView.collectionViewLayout.prepare()

    // restoreSelection()

    let dateItemIndexPath = indexPath(forDate: date)
    let monthSection = section(forDate: date)

    let dateItemRect = frameForItem(at: dateItemIndexPath)
    let monthSectionHeaderRect = frameForHeaderForSection(monthSection)

    let delta = dateItemRect.maxY - monthSectionHeaderRect.minY
    let actualViewHeight = collectionView.frame.height - collectionView.contentInset.top - collectionView.contentInset.bottom

    if delta <= actualViewHeight {
      scrollToSection(monthSection, animated: animated)
    } else {
      collectionView.scrollToItem(at: dateItemIndexPath, at: .bottom, animated: animated)
    }
  }

  func scrollToSection(_ section: Int, animated: Bool) {
    let newOffset = CGPoint(x: 0, y: frameForHeaderForSection(section).minY - collectionView.safeAreaInsets.top)
    collectionView.setContentOffset(newOffset, animated: animated)
  }

  func scrollToToday(animated: Bool) {
    scrollToDate(today, animated: animated)
  }

  // MARK: - Scroll View Delegate

  private var visibleSection: Int = 0 { didSet { if visibleSection != oldValue { updateNavigationTitle() } } }

  open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let y = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
    for section in 0..<collectionView.numberOfSections {
      if frameForHeaderForSection(section).contains(CGPoint(x: 0, y: y)) {
        visibleSection = section
        break
      }
    }
  }

  open override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
    scrollToToday(animated: true)
    return false
  }

  open func updateNavigationTitle() {
    let date = dateForFirstDayInSection(visibleSection)
    navigationItem.title = date.formatted(.dateTime.month(.wide).year().locale(calendar.locale!))
  }

  // MARK: - Date Manipulation

  func applyPastDates() { shiftDates(byMonths: -Self.shiftAmount) }
  func applyFutureDates() { shiftDates(byMonths: Self.shiftAmount) }

  func shiftDates(byMonths months: Int) {
    guard let firstVisibleCell = collectionView.visibleCells.first else { return }

    let fromIndexPath = collectionView.indexPath(for: firstVisibleCell)!
    let fromAttributes = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: fromIndexPath.section))!
    let fromSectionOrigin = collectionView.convert(fromAttributes.frame.origin, from: collectionView)
    let fromSectionOfDate = dateForFirstDayInSection(fromIndexPath.section)

    if minimumDate == nil {
      fromDate = calendar.date(byAdding: .month, value: months, to: fromDate)
    }

    if maximumDate == nil {
      toDate = calendar.date(byAdding: .month, value: months, to: toDate)
    }

    collectionView.reloadData()
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.collectionViewLayout.prepare()

    let toSection = section(forDate: fromSectionOfDate)
    let toAttributes = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: toSection))!
    let toSectionOrigin = collectionView.convert(toAttributes.frame.origin, from: collectionView)

    collectionView.contentOffset = CGPoint(
      x: collectionView.contentOffset.x,
      y: collectionView.contentOffset.y + (toSectionOrigin.y - fromSectionOrigin.y)
    )
  }

  func dateInterval(at indexPaths: [IndexPath]) -> DateInterval {
    let dates = indexPaths.map { dateForCell(at: $0) }.sorted()
    return DateInterval(start: dates.first!, end: dates.last!)
  }

  func dateForCell(at indexPath: IndexPath) -> Date {
    let firstDayInMonth = dateForFirstDayInSection(indexPath.section)
    let weekday = reorderedWeekday(calendar.component(.weekday, from: firstDayInMonth))
    return calendar.date(byAdding: .day, value: indexPath.item - weekday, to: firstDayInMonth)!
  }

  func dateAndIsInMonthForCell(at indexPath: IndexPath) -> (Date, Bool) {
    let firstDayInMonth = dateForFirstDayInSection(indexPath.section)
    let weekday = reorderedWeekday(calendar.component(.weekday, from: firstDayInMonth))
    let date = calendar.date(byAdding: .day, value: indexPath.item - weekday, to: firstDayInMonth)!
    let isInMonth = (
      calendar.isDate(firstDayInMonth, equalTo: date, toGranularity: .year) &&
      calendar.isDate(firstDayInMonth, equalTo: date, toGranularity: .month)
    )
    return (date, isInMonth)
  }

  func dateForFirstDayInSection(_ section: Int) -> Date {
    calendar.date(byAdding: .month, value: section, to: fromDate)!
  }

  func dateWithFirstDayOfMonth(_ date: Date) -> Date {
    var components = calendar.dateComponents([.year, .month, .day], from: date)
    components.day = 1
    return calendar.date(from: components)!
  }

  func dateWithFirstDayOfNextMonth(_ date: Date) -> Date {
    var components = calendar.dateComponents([.year, .month, .day], from: date)
    components.month! += 1
    components.day = 1
    return calendar.date(from: components)!
  }

  func dateWithoutTimeComponents(_ date: Date) -> Date {
    calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date))!
  }

  func frameForHeaderForSection(_ section: Int) -> CGRect {
    collectionView.layoutAttributesForSupplementaryElement(
      ofKind: UICollectionView.elementKindSectionHeader,
      at: IndexPath(item: 0, section: section)
    )?.frame ?? .null
  }

  func frameForItem(at indexPath: IndexPath) -> CGRect {
    collectionView.layoutAttributesForItem(at: indexPath)?.frame ?? .null
  }

  func section(forDate date: Date) -> Int {
    calendar.dateComponents([.month], from: dateForFirstDayInSection(0), to: date).month!
  }

  func indexPath(forDate date: Date) -> IndexPath {
    let monthSection = section(forDate: date)
    let firstDayInMonth = dateForFirstDayInSection(monthSection)
    let weekday = reorderedWeekday(calendar.component(.weekday, from: firstDayInMonth))
    let item = calendar.dateComponents([.day], from: firstDayInMonth, to: date).day! + weekday
    return IndexPath(item: item, section: monthSection)
  }

  func numberOfWeeksForMonthOfDate(_ date: Date) -> Int {
    //print(date)
    let firstDayInMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
    let lastDayInMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayInMonth)!
    //print((firstDayInMonth, lastDayInMonth))

    var fromFirstWeekdayComponents = calendar.dateComponents([.year, .weekOfYear], from: firstDayInMonth)
    fromFirstWeekdayComponents.weekday = calendar.firstWeekday

    var toFirstWeekdayComponents = calendar.dateComponents([.year, .weekOfYear], from: lastDayInMonth)
    toFirstWeekdayComponents.weekday = calendar.firstWeekday

    //print(fromFirstWeekdayComponents)
    //print(toFirstWeekdayComponents)

    let fromFirstWeekday = calendar.date(from: fromFirstWeekdayComponents)!
    let toFirstWeekday = calendar.date(from: toFirstWeekdayComponents)!

    //print((fromFirstWeekday, toFirstWeekday))
    //print()

    return 1 + calendar.dateComponents([.weekOfYear], from: fromFirstWeekday, to: toFirstWeekday).weekOfYear!
  }

  //func monthsViewDateFromDate(_ date: Date) -> MonthsViewDate {
  //  MonthsViewDate(calendar.dateComponents([.year, .month, .day], from: date))
  //}

  func reorderedWeekday(_ weekday: Int) -> Int {
    var ordered = weekday - calendar.firstWeekday
    if ordered < 0 { ordered = calendar.daysInWeek + ordered }
    return ordered
  }

}

//public struct MonthsViewDate: Hashable {
//  public let year: Int
//  public let month: Int
//  public let day: Int
//
//  public init(_ components: DateComponents) {
//    year = components.year!
//    month = components.month!
//    day = components.day!
//  }
//}

extension Calendar {
  var daysInWeek: Int { maximumRange(of: .weekday)!.count }
}

#endif
