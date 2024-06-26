//
//  DPBarChartView.swift
//  DPCharts
//
//  Created by Daniele Pantaleone
//    - Github: https://github.com/danielepantaleone
//    - LinkedIn: https://www.linkedin.com/in/danielepantaleone
//
//  Copyright © 2023 Daniele Pantaleone. Licensed under MIT License.
//

import Foundation
import UIKit

// MARK: - DPBarChartView

/// A bar chart is a graphical representation of data using rectangular
/// bars to represent different categories or variables. Each bar's length
/// corresponds to the value or frequency of the category it represents.
@IBDesignable
open class DPBarChartView: DPCanvasView {
    
    // MARK: - Static properties
    
    /// Default color for every bar.
    static let defaultBarColor: UIColor = .darkGray
    
    // MARK: - Animation properties
    
    /// The duration (in seconds) to use when animating bars (default = `0.2`).
    @IBInspectable
    open var animationDuration: Double = 0.2 {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// The animation function to use when animating bars (default = `linear`).
    @IBInspectable
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'animationTimingFunction' instead.")
    open var animationTimingFunctionName: String {
        get { animationTimingFunction.rawValue }
        set { animationTimingFunction = CAMediaTimingFunctionName(rawValue: newValue) }
    }
    
    /// The animation function to use when animating bars (default = `.linear`).
    open var animationTimingFunction: CAMediaTimingFunctionName = .linear {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// True to enable animations (default = `true`).
    @IBInspectable
    open var animationsEnabled: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }
    
    // MARK: - Bar configuration properties
    
    /// The corner radius of each bar (default = `4.0`).
    @IBInspectable
    open var barCornerRadius: CGFloat = 4.0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// The spacing between each group of bars (default = `6.0`).
    @IBInspectable
    open var barSpacing: CGFloat = 6.0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// Whether group of bars need to be stacked on top of each other (default = `false`).
    @IBInspectable
    open var barStacked: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    // MARK: - Interaction configuration properties

    /// Whether or not to enable touch events (default = `true`).
    @IBInspectable
    open var touchEnabled: Bool = true {
        didSet {
            trackingView.isEnabled = touchEnabled
        }
    }
    
    /// Alpha channel predominance for selected bars (default = `0.6`).
    @IBInspectable
    open var touchAlphaPredominance: CGFloat = 0.6 {
        didSet {
            setNeedsLayout()
        }
    }
    
    // MARK: - X-axis properties
    
    /// The spacing between X-axis label and the bottom border (default = `8`).
    @IBInspectable
    open var xAxisLabelsSpacing: CGFloat = 8 {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    // MARK: - Y-axis properties
    
    /// Y-axis shift percentage over the maximum value not to let bars touch the top of the chart (default = `0.05`).
    @IBInspectable
    open var yAxisShiftPercentage: CGFloat = 0.05 {
        didSet {
            setNeedsLayout()
        }
    }
    
    // MARK: - Public weak properties

    /// Reference to the view datasource.
    open weak var datasource: (any DPBarChartViewDataSource)? {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// Reference to the view delegate.
    open weak var delegate: (any DPBarChartViewDelegate)? {
        didSet {
            setNeedsLayout()
        }
    }

    // MARK: - Subviews
    
    lazy var trackingView: DPTrackingView = {
        let trackingView = DPTrackingView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        trackingView.insets = insets
        trackingView.delegate = self
        trackingView.isEnabled = touchEnabled
        return trackingView
    }()
    
    // MARK: - Private properties
        
    var barLayers: [DPBarLayer] = []
    var barPoints: [[DPBarPoint]] = []
    var numberOfItems: Int = 0
    var numberOfDatasets: Int = 0
    var yAxisMaxValue: CGFloat = 0
    var barWidth: CGFloat {
        guard numberOfDatasets > 0 && numberOfItems > 0 else {
            return 0
        }
        var width: CGFloat = canvasWidth
        if numberOfItems > 1 {
            width -= (barSpacing * CGFloat(numberOfItems - 1))
        }
        width -= barSpacing
        width /= CGFloat(numberOfItems * (barStacked ? 1 : numberOfDatasets))
        return width
    }
    var barGroups: [DPBarGroup] {
        var barGroups: [DPBarGroup] = []
        for p in barPoints.flatMap({ $0 }) {
            if p.index >= barGroups.count {
                barGroups.append(DPBarGroup(
                    x: .greatestFiniteMagnitude,
                    y: 0.0,
                    width: p.width * (barStacked ? 1.0 : CGFloat(numberOfDatasets)),
                    index: p.index))
            }
            barGroups[p.index].x = min(barGroups[p.index].x, p.x)
            barGroups[p.index].y = max(barGroups[p.index].y, p.y)
        }
        return barGroups
    }
    
    // MARK: - Overridden properties
    
    override var xAxisLabelsMaxHeight: CGFloat {
        guard numberOfItems > 0 else {
            return 0
        }
        var height: CGFloat = 0
        for i in 0..<numberOfItems {
            if let label = xAxisLabelAtItem(i) {
                height = max(height, label.size().height)
            }
        }
        return height + xAxisLabelsSpacing
    }
    
    // MARK: - Lifecycle
    
    public init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        initBarsIfNeeded()
        initLimits()
        initPoints()
        layoutBars()
        layoutTrackingView()
        setNeedsDisplay()
    }
        
    // MARK: - Interface
    
    /// Reload chart content by reading its datasource.
    open func reloadData() {
        setNeedsLayout()
    }
    
    // MARK: - Initialization

    func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        addSubview(trackingView)
    }
    
    func initBarsIfNeeded() {
        guard let datasource else {
            return
        }
        let numberOfItemsChanged = datasource.numberOfItems(self) != numberOfItems
        let numberOfBarsChanged = datasource.numberOfDatasets(self) != numberOfDatasets
        let numberOfBarLayersInvalidated = datasource.numberOfDatasets(self) != barLayers.count
        if numberOfItemsChanged || numberOfBarsChanged || numberOfBarLayersInvalidated {
            initBars()
        }
    }
    
    func initBars() {
        guard let datasource else {
            return
        }
        barLayers.forEach { $0.removeFromSuperlayer() }
        barLayers.removeAll()
        numberOfItems = datasource.numberOfItems(self)
        numberOfDatasets = datasource.numberOfDatasets(self)
        for i in 0..<numberOfDatasets {
            barLayers.append(DPBarLayer(datasetIndex: i))
        }
        // We reverse the order of bar layers to ease stacked bars layout
        for barLayer in barLayers.reversed() {
            layer.addSublayer(barLayer)
        }
    }
    
    func initLimits() {
        yAxisMaxValue = 0
        guard let datasource else { return }
        if barStacked {
            for i in 0..<numberOfItems {
                var accumulator: CGFloat = 0
                for j in 0..<numberOfDatasets {
                    accumulator += abs(datasource.barChartView(self, valueForDatasetAtIndex: j, forItemAtIndex: i))
                }
                yAxisMaxValue = max(yAxisMaxValue, accumulator)
            }
        } else {
            for i in 0..<numberOfDatasets {
                for j in 0..<numberOfItems {
                    yAxisMaxValue = max(abs(datasource.barChartView(self, valueForDatasetAtIndex: i, forItemAtIndex: j)), yAxisMaxValue)
                }
            }
        }
        // Adjust max value so that the chart is not cut on top and values are better distributed in the canvas
        if yAxisMaxValue != 0 && yAxisShiftPercentage > 0 {
            yAxisMaxValue += (yAxisMaxValue * yAxisShiftPercentage)
        }
    }
    
    func initPoints() {
        barPoints.removeAll()
        guard let datasource else {
            return
        }
        let barWidth = barWidth
        let canvasHeight = canvasHeight
        for i in 0..<numberOfDatasets {
            barPoints.insert([], at: i)
            for j in 0..<numberOfItems {
                let value = datasource.barChartView(self, valueForDatasetAtIndex: i, forItemAtIndex: j)
                var barHeight = yAxisMaxValue == 0 ? canvasHeight : (canvasHeight * (value / yAxisMaxValue))
                let barSpacing = barSpacing * CGFloat(j)
                let xAxisPosition: CGFloat
                let yAxisPosition: CGFloat
                if barStacked {
                    var stackHeight: CGFloat = 0
                    for k in 0..<i {
                        stackHeight += barPoints[k][j].height
                    }
                    xAxisPosition = (barWidth * CGFloat(j)) + barSpacing
                    yAxisPosition = canvasHeight - barHeight - stackHeight
                    barHeight = canvasHeight - yAxisPosition // recompute to prevent glitches when changing bars alpha
                } else {
                    xAxisPosition = ((barWidth * CGFloat(numberOfDatasets) * CGFloat(j)) + (barWidth * CGFloat(i))) + barSpacing
                    yAxisPosition = canvasHeight - barHeight
                }
                barPoints[i].insert(DPBarPoint(x: xAxisPosition, y: yAxisPosition, height: barHeight, width: barWidth, datasetIndex: i, index: j), at: j)
            }
        }
    }
    
    // MARK: - Layout

    func layoutBars() {
        let canvasPosX = canvasPosX + (barSpacing * 0.5)
        let canvasPosY = canvasPosY
        let canvasWidth = canvasWidth - barSpacing
        let canvasHeight = canvasHeight
        for i in 0..<numberOfDatasets {
            let bar = barLayers[i]
            bar.frame = CGRect(x: canvasPosX, y: canvasPosY, width: canvasWidth, height: canvasHeight)
            bar.animationEnabled = animationsEnabled
            bar.animationDuration = animationDuration
            bar.animationTimingFunction = animationTimingFunction
            bar.selectedIndexAlphaPredominance = touchAlphaPredominance
            bar.barCornerRadius = barCornerRadius
            bar.barColor = datasource?.barChartView(self, colorForDatasetAtIndex: i) ?? DPBarChartView.defaultBarColor
            bar.barPoints = barPoints[i]
            bar.setNeedsLayout()
        }
    }
    
    func layoutTrackingView() {
        trackingView.frame = CGRect(x: canvasPosX, y: canvasPosY, width: canvasWidth, height: canvasHeight)
        trackingView.insets = insets
        trackingView.isEnabled = touchEnabled
    }
    
    // MARK: - Touch gesture
    
    func closestIndex(at x: CGFloat) -> Int? {
        var compare: CGFloat = .greatestFiniteMagnitude
        var index: Int?
        for group in barGroups {
            let distance = abs((group.x + (group.width * 0.5)) - x)
            if distance < compare {
                compare = distance
                index = group.index
            }
        }
        return index
    }
    
    func touchAt(_ point: CGPoint) {
        guard touchEnabled else { return } // Disabled
        guard point.x >= 0 else { return } // Out of bounds
        guard let index = closestIndex(at: point.x) else { return } // Out of scope
        barLayers.forEach { $0.selectedIndex = index }
        delegate?.barChartView(self, didTouchAtItem: index)
    }
    
    func touchEndedAt(_ point: CGPoint) {
        guard touchEnabled else { return } // Disabled
        guard let index = closestIndex(at: point.x) else { return } // Out of scope
        barLayers.forEach { $0.selectedIndex = nil }
        delegate?.barChartView(self, didReleaseTouchFromItem: index)
    }
    
    // MARK: - Custom drawing
    
    public override func draw(_ rect: CGRect) {
        drawXAxisMarkers(rect)
        super.draw(rect)
    }
    
    func drawXAxisMarkers(_ rect: CGRect) {
        
        guard numberOfItems > 0 else {
            return
        }
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let canvasPosX = canvasPosX
        let canvasPosY = canvasPosY
        let canvasHeight = canvasHeight
        let yAxisLineBeginPosition: CGFloat = canvasPosY + (markersLineWidth * 0.5)
        let yAxisLineEndPosition: CGFloat = yAxisLineBeginPosition + canvasHeight - (markersLineWidth * 0.5)
        let barItemWidth: CGFloat = barWidth * (barStacked ? 1.0 : CGFloat(numberOfDatasets))
        
        ctx.saveGState()
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        for i in 0..<numberOfItems {
            // Draw the marker line without overlapping with the LEADING and TRAILING border/marker line
            if i > 0 {
                let xAxisShift: CGFloat = ((barItemWidth + barSpacing) * CGFloat(i)) - (barSpacing * 0.5)
                let xAxisPosition: CGFloat = canvasPosX + xAxisShift - markersLineWidth * 0.5 + (barSpacing * 0.5)
                ctx.setAlpha(markersLineAlpha)
                ctx.setLineWidth(markersLineWidth)
                ctx.setStrokeColor(markersLineColor.cgColor)
                ctx.setLineDash(phase: 0, lengths: markersLineDashed ? markersLineDashLengths : [])
                ctx.move(to: CGPoint(x: xAxisPosition, y: yAxisLineBeginPosition))
                ctx.addLine(to: CGPoint(x: xAxisPosition, y: yAxisLineEndPosition))
                ctx.strokePath()
            }
            // Draw the label if we have some content
            if let label = xAxisLabelAtItem(i) {
                let xAxisLabelShift: CGFloat = ((barItemWidth + barSpacing) * CGFloat(i + 1)) - (barItemWidth * 0.5)
                let xAxisLabelPosition: CGFloat = canvasPosX + xAxisLabelShift - (label.size().width * 0.5) - (barSpacing * 0.5)
                let yAxisLabelPosition: CGFloat = canvasPosY + canvasHeight + xAxisLabelsSpacing
                ctx.setAlpha(1.0)
                label.draw(at: CGPoint(x: xAxisLabelPosition, y: yAxisLabelPosition))
            }
        }
        
        ctx.restoreGState()
        
    }
    
    // MARK: - Misc
    
    func xAxisLabelAtItem(_ index: Int) -> NSAttributedString? {
        guard let string = datasource?.barChartView(self, xAxisLabelForItemAtIndex: index) else {
            return nil
        }
        return axisLabel(string)
    }
    
    // MARK: - Overrides
    
    override func yAxisLabelAtIndex(_ index: Int, for value: CGFloat) -> NSAttributedString? {
        guard let string = datasource?.barChartView(self, yAxisLabelAtIndex: index, for: value) else {
            return nil
        }
        return axisLabel(string)
    }
        
    override func yAxisValueAtIndex(_ index: Int) -> CGFloat {
        return (yAxisMaxValue / CGFloat(yAxisMarkersCount)) * CGFloat(index)
    }
    
    // MARK: - Storyboard
    
    #if TARGET_INTERFACE_BUILDER
    let ibDataSource = DPBarChartViewIBDataSource()
    // swiftlint:disable:next overridden_super_call
    public override func prepareForInterfaceBuilder() {
        datasource = ibDataSource
    }
    #endif
    
}

// MARK: - DPTrackingViewDelegate

extension DPBarChartView: DPTrackingViewDelegate {
    
    func trackingView(_ trackingView: DPTrackingView, touchDownAt point: CGPoint) {
        touchAt(point)
    }
    
    func trackingView(_ trackingView: DPTrackingView, touchMovedTo point: CGPoint) {
        touchAt(point)
    }
    
    func trackingView(_ trackingView: DPTrackingView, touchUpAt point: CGPoint) {
        touchEndedAt(point)
    }
    
    func trackingView(_ trackingView: DPTrackingView, touchCanceledAt point: CGPoint) {
        touchEndedAt(point)
    }
    
    func trackingView(_ trackingView: DPTrackingView, tapSingleAt point: CGPoint) {
        touchEndedAt(point)
    }
    
    func trackingView(_ trackingView: DPTrackingView, tapDoubleAt point: CGPoint) {
        touchEndedAt(point)
    }
    
}
