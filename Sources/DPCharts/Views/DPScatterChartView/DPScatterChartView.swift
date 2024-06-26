//
//  DPScatterChartView.swift
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

// MARK: - DPScatterChartView

/// A scatter chart, also known as a scatter plot, is a graphical representation that
/// displays individual data points as dots on a two-dimensional coordinate system.
/// It is used to show the relationship or correlation between two variables. Each data
/// point on the chart represents a specific value pair for the two variables being analyzed.
@IBDesignable
open class DPScatterChartView: DPCanvasView {
    
    // MARK: - Static properties
    
    /// Default alpha for scatter points
    static let defaultPointAlpha: CGFloat = 0.7
    /// Default size for scatter points
    static let defaultPointSize: CGFloat = 10.0
    /// Default color to use when rendering points
    static let defaultPointColor: UIColor = .black
    /// Default shape type to use when rendering points
    static let defaultPointShapeType: DPShapeType = .circle

    // MARK: - Animation properties
    
    /// The duration (in seconds) to use when animating points (default = `0.2`).
    @IBInspectable
    open var animationDuration: Double = 0.2 {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// The animation function to use when animating points (default = `linear`).
    @IBInspectable
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'animationTimingFunction' instead.")
    open var animationTimingFunctionName: String {
        get { animationTimingFunction.rawValue }
        set { animationTimingFunction = CAMediaTimingFunctionName(rawValue: newValue) }
    }
    
    /// The animation function to use when animating points (default = `.linear`).
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

    /// The alpha value for scatter points (default = `0.7`).
    @IBInspectable
    open var scatterPointsAlpha: Double = DPScatterChartView.defaultPointAlpha {
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
    
    /// Alpha channel predominance for selected dots (default = `0.6`).
    @IBInspectable
    open var touchAlphaPredominance: CGFloat = 0.6 {
        didSet {
            setNeedsLayout()
        }
    }
    
    // MARK: - X-axis properties

    /// The number of markers on X-axis (default = `6`).
    @IBInspectable
    open var xAxisMarkersCount: Int = 6 {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    /// The spacing between the marker label and the bottom border (default = `8`).
    @IBInspectable
    open var xAxisMarkersSpacing: CGFloat = 8 {
        didSet {
            setNeedsLayout()
            setNeedsDisplay()
        }
    }
    
    // MARK: - Public weak properties
    
    /// Reference to the chart datasource.
    open weak var datasource: (any DPScatterChartViewDataSource)? {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// Reference to the chart delegate.
    open weak var delegate: (any DPScatterChartViewDelegate)? {
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
        
    var points: [[DPScatterPoint]] = []
    var datasetLayers: [DPScatterDatasetLayer] = []
    var numberOfPointsByDataset: [Int] = []
    var numberOfDatasets: Int = 0
    var xAxisMaxValue: CGFloat = 0
    var yAxisMaxValue: CGFloat = 0
    
    // MARK: - Overridden properties
    
    override var xAxisLabelsMaxHeight: CGFloat {
        guard xAxisMarkersCount > 0 else {
            return 0
        }
        var height: CGFloat = 0
        for i in 0..<xAxisMarkersCount {
            if let marker = xAxisLabelAtIndex(i, for: xAxisValueAtIndex(i)) {
                height = max(height, marker.size().height)
            }
        }
        return height + xAxisMarkersSpacing
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
        initDatasetsIfNeeded()
        initLimits()
        initPoints()
        layoutDatasets()
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

    func initDatasetsIfNeeded() {
        guard let datasource else {
            return
        }
        let numberOfDatasetsChanged = datasource.numberOfDatasets(self) != numberOfDatasets
        var numberOfPointsChanged = false
        for (index, numberOfPoints) in numberOfPointsByDataset.enumerated() {
            if numberOfPoints != datasource.scatterChartView(self, numberOfPointsForDatasetAtIndex: index) {
                numberOfPointsChanged = true
                break
            }
        }
        if numberOfDatasetsChanged || numberOfPointsChanged {
            initDatasets()
        }
    }
    
    func initDatasets() {
        guard let datasource else {
            return
        }
        datasetLayers.forEach { $0.removeFromSuperlayer() }
        datasetLayers.removeAll()
        numberOfPointsByDataset.removeAll()
        numberOfDatasets = datasource.numberOfDatasets(self)
        for i in 0..<numberOfDatasets {
            let numberOfPoints = datasource.scatterChartView(self, numberOfPointsForDatasetAtIndex: i)
            let datasetLayer = DPScatterDatasetLayer(datasetIndex: i, numberOfPoints: numberOfPoints)
            numberOfPointsByDataset.append(numberOfPoints)
            datasetLayers.append(datasetLayer)
            layer.addSublayer(datasetLayer)
        }
    }
    
    func initLimits() {
        xAxisMaxValue = 0.0
        yAxisMaxValue = 0.0
        guard let datasource else { return }
        var shiftBy: CGFloat = 0
        for i in 0..<numberOfDatasets {
            for j in 0..<numberOfPointsByDataset[i] {
                let x = datasource.scatterChartView(self, xAxisValueForDataSetAtIndex: i, forPointAtIndex: j)
                let y = datasource.scatterChartView(self, yAxisValueForDataSetAtIndex: i, forPointAtIndex: j)
                let size = datasource.scatterChartView(self, shapeSizeForDataSetAtIndex: i, forPointAtIndex: j)
                xAxisMaxValue = max(x, yAxisMaxValue)
                yAxisMaxValue = max(y, yAxisMaxValue)
                shiftBy = max(size, shiftBy)
            }
        }
        xAxisMaxValue += shiftBy
        yAxisMaxValue += shiftBy
    }

    func initPoints() {
        points.removeAll()
        guard let datasource else { return }
        let canvasHeight = canvasHeight
        let canvasWidth = canvasWidth
        for i in 0..<numberOfDatasets {
            points.insert([], at: i)
            for j in 0..<numberOfPointsByDataset[i] {
                let x = datasource.scatterChartView(self, xAxisValueForDataSetAtIndex: i, forPointAtIndex: j)
                let y = datasource.scatterChartView(self, yAxisValueForDataSetAtIndex: i, forPointAtIndex: j)
                let size = datasource.scatterChartView(self, shapeSizeForDataSetAtIndex: i, forPointAtIndex: j)
                let xAxisPosition: CGFloat = ((xAxisMaxValue - x) / xAxisMaxValue) * canvasWidth
                let yAxisPosition: CGFloat = ((yAxisMaxValue - y) / yAxisMaxValue) * canvasHeight
                points[i].insert(DPScatterPoint(
                    x: xAxisPosition,
                    y: yAxisPosition,
                    datasetIndex: i,
                    index: j,
                    size: size), at: j)
            }
        }
    }

    // MARK: - Layout

    func layoutDatasets() {
        let canvasPosX = canvasPosX
        let canvasPosY = canvasPosY
        let canvasWidth = canvasWidth
        let canvasHeight = canvasHeight
        for i in 0..<numberOfDatasets {
            guard i < datasetLayers.count else { break }
            let dataset = datasetLayers[i]
            dataset.frame = CGRect(x: canvasPosX, y: canvasPosY, width: canvasWidth, height: canvasHeight)
            dataset.animationEnabled = animationsEnabled
            dataset.animationDuration = animationDuration
            dataset.animationTimingFunction = animationTimingFunction
            dataset.scatterPointsAlpha = scatterPointsAlpha
            dataset.scatterPointsColor = datasource?.scatterChartView(self, shapeColorForDataSetAtIndex: i) ?? DPScatterChartView.defaultPointColor
            dataset.scatterPointsType = datasource?.scatterChartView(self, shapeTypeForDataSetAtIndex: i) ?? DPScatterChartView.defaultPointShapeType
            dataset.scatterPoints = points[i]
            dataset.setNeedsLayout()
        }
    }
    
    func layoutTrackingView() {
        trackingView.frame = CGRect(x: canvasPosX, y: canvasPosY, width: canvasWidth, height: canvasHeight)
        trackingView.insets = insets
        trackingView.isEnabled = touchEnabled
    }
   
    // MARK: - Touch gesture
    
    func closestPoint(at point: CGPoint) -> DPScatterPoint? {
        var compare: CGFloat = .greatestFiniteMagnitude
        var p: DPScatterPoint?
        for datasetLayer in datasetLayers {
            for scatterPoint in datasetLayer.scatterPoints {
                let distance = sqrt(pow(point.x - scatterPoint.x, 2) + pow(point.y - scatterPoint.y, 2))
                if distance < compare {
                    compare = distance
                    p = scatterPoint
                }
            }
        }
        return p
    }

    func touchAt(_ point: CGPoint) {
        guard touchEnabled else { return } // Disabled
        guard point.x >= 0 else { return } // Out of bounds
        guard let p = closestPoint(at: point) else { return } // Out of scope
        datasetLayers.forEach { $0.selectedIndex = p.datasetIndex }
        delegate?.scatterChartView(self, didTouchDatasetAtIndex: p.datasetIndex, withPointAt: p.index)
    }

    func touchEndedAt(_ point: CGPoint) {
        guard touchEnabled else { return } // Disabled
        guard let p = closestPoint(at: point) else { return } // Out of scope
        datasetLayers.forEach { $0.selectedIndex = nil }
        delegate?.scatterChartView(self, didReleaseTouchFromDatasetAtIndex: p.datasetIndex, withPointAt: p.index)
    }
    
    // MARK: - Custom drawing
    
    public override func draw(_ rect: CGRect) {
        drawXAxisMarkers(rect)
        super.draw(rect)
    }

    func drawXAxisMarkers(_ rect: CGRect) {
        
        guard xAxisMarkersCount >= 2 else {
            return
        }
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        ctx.saveGState()
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let canvasPosX = canvasPosX
        let canvasPosY = canvasPosY
        let canvasWidth = canvasWidth
        let canvasHeight = canvasHeight
        let yAxisLineBeginPosition: CGFloat = canvasPosY + (markersLineWidth * 0.5)
        let yAxisLineEndPosition: CGFloat = yAxisLineBeginPosition + canvasHeight - (markersLineWidth * 0.5)
        let distance: CGFloat = canvasWidth / CGFloat(xAxisMarkersCount - 1)
        for i in 0..<xAxisMarkersCount {
            let xAxisPosition: CGFloat = canvasPosX + (CGFloat(i) * distance) - markersLineWidth * 0.5
            // Draw the marker line without overlapping with the LEADING and TRAILING border/marker line
            if i > 0 && i < xAxisMarkersCount - 1 {
                ctx.setAlpha(markersLineAlpha)
                ctx.setLineWidth(markersLineWidth)
                ctx.setStrokeColor(markersLineColor.cgColor)
                ctx.setLineDash(phase: 0, lengths: markersLineDashed ? markersLineDashLengths : [])
                ctx.move(to: CGPoint(x: xAxisPosition, y: yAxisLineBeginPosition))
                ctx.addLine(to: CGPoint(x: xAxisPosition, y: yAxisLineEndPosition))
                ctx.strokePath()
            }
            // Draw the marker text if we have some content
            if let label = xAxisLabelAtIndex(i, for: xAxisValueAtIndex(i)) {
                let xMin: CGFloat = 0.0
                let xMax: CGFloat = bounds.width - label.size().width
                let xAxisLabelPosition: CGFloat = (xAxisPosition - (label.size().width * 0.5)).clamped(to: xMin...xMax)
                let yAxisLabelPosition: CGFloat = canvasPosY + canvasHeight + xAxisMarkersSpacing
                ctx.setAlpha(1.0)
                label.draw(at: CGPoint(x: xAxisLabelPosition, y: yAxisLabelPosition))
            }
        }
        
        ctx.restoreGState()
        
    }

    // MARK: - Misc
    
    func xAxisLabelAtIndex(_ index: Int, for value: CGFloat) -> NSAttributedString? {
        guard let string = datasource?.scatterChartView(self, xAxisLabelAtIndex: index, for: value) else {
            return nil
        }
        return axisLabel(string)
    }
    
    func xAxisValueAtIndex(_ index: Int) -> CGFloat {
        return (xAxisMaxValue / CGFloat(xAxisMarkersCount)) * CGFloat(index)
    }
    
    // MARK: - Overrides
    
    override func yAxisLabelAtIndex(_ index: Int, for value: CGFloat) -> NSAttributedString? {
        guard let string = datasource?.scatterChartView(self, yAxisLabelAtIndex: index, for: value) else {
            return nil
        }
        return axisLabel(string)
    }
    
    override func yAxisValueAtIndex(_ index: Int) -> CGFloat {
        return (yAxisMaxValue / CGFloat(yAxisMarkersCount)) * CGFloat(index)
    }
    
    // MARK: - Storyboard
    
    #if TARGET_INTERFACE_BUILDER
    let ibDataSource = DPScatterChartViewIBDataSource()
    
    // swiftlint:disable:next overridden_super_call
    public override func prepareForInterfaceBuilder() {
        datasource = ibDataSource
    }
    #endif

}

// MARK: - DPTrackingViewDelegate

extension DPScatterChartView: DPTrackingViewDelegate {
    
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
