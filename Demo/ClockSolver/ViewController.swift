//
//  ViewController.swift
//  ClockSolver
//
//  Created by Jason Kirchner on 4/9/16.
//  Copyright © 2016 Jason Kirchner. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var clockContainer: UIView!
    @IBOutlet var unsolvableLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    private var clockPositions = [Int]()
    private var clock: ZMClock?
    private static let possibleNumbers = Array(1...6)
    private var clockFaceViews: [UIView] {
        return clockContainer.subviews
    }
    private let maxNumbers = 13
    private var showingSolution = false
    private var solutionLayer: CAShapeLayer?
    private var notificationObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        notificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(UIDeviceOrientationDidChangeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self] _ in
            self?.refreshClockFace()
        }
    }

    deinit {
        if let observer = notificationObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }

    @IBAction func didTapNumber(sender: UIButton) {
        guard ViewController.possibleNumbers.contains(sender.tag) && !showingSolution else { return }

        clockPositions.append(sender.tag)
        updateClock()
    }

    @IBAction func didTapClockFace(sender: AnyObject) {
        guard clock?.positions.count > 1 else { return }

        showSolution()
    }

    @IBAction func didResetClock(sender: AnyObject) {
        unsolvableLabel.hidden = true
        clockPositions.removeAll()
        clockFaceViews.forEach{ $0.removeFromSuperview() }
        clockContainer.layer.sublayers?.forEach{ $0.removeFromSuperlayer() }
        clock = nil
        showingSolution = false

        refreshClockFace()
    }

    override func viewDidLayoutSubviews() {
        configureClockFace()
    }

    private func configureClockFace() {
        clockContainer.layer.cornerRadius = clockContainer.frame.size.width / 2
    }

    private func updateClock() {
        guard clockFaceViews.count < maxNumbers else { return }

        clock = ZMClock(positions: clockPositions)
        clockPositions = clock?.positions ?? [Int]()

        if clockPositions.count > clockFaceViews.count {
            for i in clockFaceViews.count ..< clockPositions.count {
                addNumberToClockFace(clockPositions[i])
            }
        } else {
            refreshClockFace()
        }
    }

    private func addNumberToClockFace(number: Int) {
        guard clockFaceViews.count < maxNumbers else { return }

        let view = numberViewWithNumber(number)
        view.alpha = 1.0
        view.tag = clockFaceViews.count

        clockContainer.addSubview(view)

        refreshClockFace()
    }

    private let maxPadSize = 170
    private let maxPhoneSize = 100
    private let minPadSize = 44
    private let minPhoneSize = 44

    private var maxSize: CGFloat {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad ? CGFloat(maxPadSize) : CGFloat(maxPhoneSize)
    }
    private var minSize: CGFloat {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad ? CGFloat(minPadSize) : CGFloat(minPhoneSize)
    }

    private func refreshClockFace() {
        let containerSize = clockContainer.frame.size
        let angleIncrement = CGFloat(2 * M_PI) / CGFloat(clockFaceViews.count)
        let viewAdjust = clockFaceViews.count > 4 ? CGFloat(4.75 / Float(clockFaceViews.count)) : CGFloat(1.0)
        var viewSize = maxSize * viewAdjust
        viewSize = (viewSize > maxSize) ? maxSize : viewSize
        viewSize = (viewSize < minSize) ? minSize : viewSize
        let radius = containerSize.width / 2 - viewSize / 2 - 10

        for (index, view) in clockFaceViews.enumerate() {
            let x = (cos(angleIncrement * CGFloat(index) - CGFloat(M_PI_2)) * radius) + containerSize.width / 2 - viewSize / 2
            let y = (sin(angleIncrement * CGFloat(index) - CGFloat(M_PI_2)) * radius) + containerSize.height / 2 - viewSize / 2
            view.frame = CGRectMake(x, y, viewSize, viewSize)
            view.layer.cornerRadius = viewSize / 2
        }

        if showingSolution {
            showSolution()
        }
    }

    private func numberViewWithNumber(number: Int) -> UIView {
        let view = UIView(frame: CGRectZero)
        view.backgroundColor = UIColor.redColor()
        view.layer.cornerRadius = view.frame.size.width / 2
        let label = UILabel(frame: view.frame)
        label.text = String(number)
        label.textAlignment = .Center
        view.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        label.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        label.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        label.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true

        return view
    }

    private func showSolution() {
        showingSolution = true
        activityIndicator.startAnimating()

        clock?.calculateSolutionOnComplete({ (solution) in
            self.activityIndicator.stopAnimating()

            guard let solution = solution else {
                self.unsolvableLabel.hidden = false
                return
            }

            self.unsolvableLabel.hidden = true

            self.solutionLayer?.removeFromSuperlayer()

            let startingView = self.clockContainer.subviews[solution[0]]
            startingView.backgroundColor = UIColor.greenColor()

            let shapeLayer = CAShapeLayer()
            shapeLayer.path = self.solutionPath()?.CGPath
            shapeLayer.strokeColor = UIColor.blackColor().CGColor
            shapeLayer.fillColor = UIColor.clearColor().CGColor
            shapeLayer.lineWidth = 1.0

            self.solutionLayer = shapeLayer
            self.clockContainer.layer.insertSublayer(shapeLayer, atIndex: 0)
        })

    }

    private func solutionPath() -> UIBezierPath? {
        guard let solution = clock?.solution else { return nil }

        let path = UIBezierPath()
        let startingView = clockContainer.subviews[solution[0]]
        path.moveToPoint(CGPointMake(CGRectGetMidX(startingView.frame), CGRectGetMidY(startingView.frame)))

        for index in 1..<solution.count {
            let view = clockContainer.subviews[solution[index]]
            path.addLineToPoint(CGPointMake(CGRectGetMidX(view.frame), CGRectGetMidY(view.frame)))
        }
        return path
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate {

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "informationSegue" {
            let popoverViewController = segue.destinationViewController
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController?.delegate = self
        }
    }

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }

}
