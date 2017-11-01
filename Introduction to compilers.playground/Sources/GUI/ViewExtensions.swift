import Cocoa

public extension NSView {
    func addHeightConstraint(forHeight height: CGFloat, withPriority priority: Float = 1000) {
        let heightConstraint = NSLayoutConstraint(item: self,
                                                  attribute: .height,
                                                  relatedBy: .equal,
                                                  toItem: nil,
                                                  attribute: .notAnAttribute,
                                                  multiplier: 1,
                                                  constant: 100)
        heightConstraint.priority = NSLayoutConstraint.Priority(priority)
        self.addConstraint(heightConstraint)
    }

    func addWidthConstraint(forWidth width: CGFloat, withPriority priority: Float = 1000) {
        let widthConstraint = NSLayoutConstraint(item: self,
                                                 attribute: .width,
                                                 relatedBy: .equal,
                                                 toItem: nil,
                                                 attribute: .notAnAttribute,
                                                 multiplier: 1,
                                                 constant: 100)
        widthConstraint.priority = NSLayoutConstraint.Priority(priority)
        self.addConstraint(widthConstraint)
    }
}

public extension NSStackView {
    func addFullWidthView(_ view: NSView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addView(view, in: .top)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[view]|",
                                                           options: [],
                                                           metrics: nil,
                                                           views: ["view": view]))
    }
}
