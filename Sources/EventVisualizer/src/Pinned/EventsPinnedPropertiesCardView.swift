//
//  EventsPinnedPropertiesCardView.swift
//  EventVisualizer
//
//  Copyright © 2025 Gojek. All rights reserved.
//

import UIKit

/// Callbacks from the pinned-properties card to its host.
/// All methods have empty default implementations and are called on the main thread.
@MainActor
public protocol EventsPinnedPropertiesCardViewDelegate: AnyObject {
    /// The card wants `viewController` presented (event details, pin picker).
    func cardView(_ cardView: EventsPinnedPropertiesCardView, wantsToPresent viewController: UIViewController)
    /// The card's size or visibility changed; the host should re-position it.
    func cardViewDidChangeLayout(_ cardView: EventsPinnedPropertiesCardView)
    /// The user toggled capturing via the card's Start/Stop button.
    func cardView(_ cardView: EventsPinnedPropertiesCardView, didSetCapturing isCapturing: Bool)
}

public extension EventsPinnedPropertiesCardViewDelegate {
    func cardView(_ cardView: EventsPinnedPropertiesCardView, wantsToPresent viewController: UIViewController) {}
    func cardViewDidChangeLayout(_ cardView: EventsPinnedPropertiesCardView) {}
    func cardView(_ cardView: EventsPinnedPropertiesCardView, didSetCapturing isCapturing: Bool) {}
}

/// A floating card listing the latest value of every pinned property, plus the capture
/// status and a Start/Stop button. It refreshes itself when events or pins change and
/// hides itself when nothing is pinned. The host only needs to add it to a view
/// hierarchy, size it (`systemLayoutSizeFitting`) and react to `delegate` callbacks.
public final class EventsPinnedPropertiesCardView: UIView {

    public weak var delegate: EventsPinnedPropertiesCardViewDelegate?

    public private(set) var isCollapsed = false

    private let store: EventsPinnedPropertiesStore
    private let helper: EventsHelper

    private let headerLabel = UILabel()
    private let statusDot = UIView()
    private let statusLabel = UILabel()
    private let toggleButton = UIButton(type: .system)
    private let rowsStackView = UIStackView()
    private var rowViews: [PinnedRowView] = []
    private var refreshScheduled = false

    public override init(frame: CGRect) {
        self.store = .shared
        self.helper = .shared
        super.init(frame: frame)
        setUpViews()
        observeChanges()
        refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Builds a navigation-wrapped picker for choosing an event and pinning its properties.
    public static func makePinPickerViewController() -> UINavigationController {
        let nav = UINavigationController(rootViewController: EventsPinPickerViewController())
        nav.modalPresentationStyle = .overCurrentContext
        return nav
    }

    /// Re-reads pins, values and capture state immediately.
    public func refresh() {
        let values = store.currentValues()
        let wasHidden = isHidden
        isHidden = values.isEmpty
        guard !values.isEmpty else {
            if !wasHidden { delegate?.cardViewDidChangeLayout(self) }
            return
        }

        let sizeBefore = rowViews.count
        if rowViews.map(\.pinnedValue.pin) == values.map(\.pin) {
            zip(rowViews, values).forEach { $0.apply($1) }
        } else {
            rebuildRows(with: values)
        }
        updateHeader(count: values.count)
        updateCaptureState(isCapturing: helper.isCapturing)
        if wasHidden || sizeBefore != rowViews.count {
            delegate?.cardViewDidChangeLayout(self)
        }
    }

    // MARK: - Setup

    private func setUpViews() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
        isHidden = true

        headerLabel.font = .preferredFont(forTextStyle: .subheadline).bold()
        headerLabel.textColor = .label
        headerLabel.numberOfLines = 2
        headerLabel.isUserInteractionEnabled = true
        headerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap)))

        statusDot.layer.cornerRadius = 4
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        statusDot.heightAnchor.constraint(equalToConstant: 8).isActive = true
        statusLabel.font = .preferredFont(forTextStyle: .caption1)

        let statusStack = UIStackView(arrangedSubviews: [statusDot, statusLabel])
        statusStack.axis = .horizontal
        statusStack.alignment = .center
        statusStack.spacing = 4

        let titleStack = UIStackView(arrangedSubviews: [headerLabel, statusStack])
        titleStack.axis = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 2
        titleStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.cornerStyle = .capsule
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
        buttonConfiguration.baseForegroundColor = .white
        toggleButton.configuration = buttonConfiguration
        toggleButton.setContentHuggingPriority(.required, for: .horizontal)
        toggleButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        toggleButton.addTarget(self, action: #selector(handleCaptureToggleTap), for: .touchUpInside)

        let headerStack = UIStackView(arrangedSubviews: [titleStack, toggleButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 8
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        rowsStackView.axis = .vertical
        rowsStackView.spacing = 4
        rowsStackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(headerStack)
        addSubview(rowsStackView)
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            rowsStackView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            rowsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            rowsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            rowsStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        updateHeader(count: 0)
        updateCaptureState(isCapturing: helper.isCapturing)
    }

    private func observeChanges() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(scheduleRefresh),
            name: EventsHelper.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(scheduleRefresh),
            name: EventsPinnedPropertiesStore.didChangeNotification, object: nil)
    }

    /// Notifications can arrive on background queues at a high rate; coalesce them
    /// into at most one refresh every 0.25s on the main queue.
    @objc private func scheduleRefresh() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.refreshScheduled else { return }
            self.refreshScheduled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self = self else { return }
                self.refreshScheduled = false
                self.refresh()
            }
        }
    }

    // MARK: - Updates

    private func rebuildRows(with values: [EventsPinnedValue]) {
        rowViews.forEach { $0.removeFromSuperview() }
        rowViews = values.map { value in
            let row = PinnedRowView(pinnedValue: value)
            row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleRowTap)))
            row.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleRowLongPress)))
            row.isHidden = isCollapsed
            rowsStackView.addArrangedSubview(row)
            return row
        }
    }

    private func updateHeader(count: Int) {
        headerLabel.text = "Pinned properties (\(count)), tap to \(isCollapsed ? "show" : "hide")"
        rowsStackView.isHidden = isCollapsed
    }

    private func updateCaptureState(isCapturing: Bool) {
        statusLabel.text = isCapturing ? "Capturing events" : "Not capturing events"
        statusLabel.textColor = isCapturing ? .systemGreen : .systemRed
        statusDot.backgroundColor = isCapturing ? .systemGreen : .systemRed
        var buttonConfiguration = toggleButton.configuration ?? .filled()
        var title = AttributedString(isCapturing ? "Stop" : "Start")
        title.font = UIFont.preferredFont(forTextStyle: .caption1).bold()
        buttonConfiguration.attributedTitle = title
        buttonConfiguration.baseBackgroundColor = isCapturing ? .systemRed : .systemGreen
        toggleButton.configuration = buttonConfiguration
    }

    // MARK: - Actions

    @objc private func handleHeaderTap() {
        isCollapsed.toggle()
        rowViews.forEach { $0.isHidden = isCollapsed }
        updateHeader(count: rowViews.count)
        delegate?.cardViewDidChangeLayout(self)
    }

    @objc private func handleCaptureToggleTap() {
        let shouldCapture = !helper.isCapturing
        if shouldCapture {
            helper.startCapturing()
        } else {
            helper.stopCapturing()
        }
        updateCaptureState(isCapturing: helper.isCapturing)
        delegate?.cardView(self, didSetCapturing: helper.isCapturing)
    }

    @objc private func handleRowTap(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view as? PinnedRowView,
              let event = store.latestEvent(named: row.pinnedValue.pin.eventName) else { return }
        let details = EventDetailsViewController()
        details.messageSelected = event.msg
        details.pinnedEventName = row.pinnedValue.pin.eventName
        details.focusedKeyPath = row.pinnedValue.pin.keyPath
        let nav = UINavigationController(rootViewController: details)
        nav.modalPresentationStyle = .overCurrentContext
        details.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak nav] _ in nav?.dismiss(animated: true) })
        delegate?.cardView(self, wantsToPresent: nav)
    }

    @objc private func handleRowLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let row = gesture.view as? PinnedRowView else { return }
        store.remove(row.pinnedValue.pin)
    }
}

// MARK: - Row

private final class PinnedRowView: UIView {

    private let highlightView = UIView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    private(set) var pinnedValue: EventsPinnedValue

    init(pinnedValue: EventsPinnedValue) {
        self.pinnedValue = pinnedValue
        super.init(frame: .zero)
        setUpViews()
        apply(pinnedValue)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ newValue: EventsPinnedValue) {
        let didChange = newValue.value != pinnedValue.value
        pinnedValue = newValue
        titleLabel.text = "\(newValue.pin.eventName) / \(newValue.pin.keyPath)"
        valueLabel.text = newValue.value
        if didChange { flash() }
    }

    private func setUpViews() {
        layer.cornerRadius = 8
        layer.masksToBounds = true

        highlightView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
        highlightView.alpha = 0
        highlightView.isUserInteractionEnabled = false
        highlightView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = .secondaryLabel
        titleLabel.numberOfLines = 2

        valueLabel.font = .preferredFont(forTextStyle: .subheadline).bold()
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 3

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(highlightView)
        addSubview(stack)
        NSLayoutConstraint.activate([
            highlightView.topAnchor.constraint(equalTo: topAnchor),
            highlightView.bottomAnchor.constraint(equalTo: bottomAnchor),
            highlightView.leadingAnchor.constraint(equalTo: leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }

    private func flash() {
        highlightView.layer.removeAllAnimations()
        highlightView.alpha = 1
        UIView.animate(withDuration: 1.2, delay: 0.2, options: [.allowUserInteraction]) { [weak self] in
            self?.highlightView.alpha = 0
        }
    }
}

private extension UIFont {
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
