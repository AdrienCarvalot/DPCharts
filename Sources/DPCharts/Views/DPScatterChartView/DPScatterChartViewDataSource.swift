//
//  DPScatterChartViewDataSource.swift
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

/// A protocol to configure scatter chart appearance.
public protocol DPScatterChartViewDataSource: AnyObject {
    /// The number of datasets to display in this scatter chart.
    func numberOfDatasets(_ scatterChartView: DPScatterChartView) -> Int
    /// The number of points to display for the given dataset.
    func scatterChartView(_ scatterChartView: DPScatterChartView, numberOfPointsForDatasetAtIndex datasetIndex: Int) -> Int
    /// The color used to render the given dataset.
    func scatterChartView(_ scatterChartView: DPScatterChartView, shapeColorForDataSetAtIndex datasetIndex: Int) -> UIColor
    /// The shape type used to render the given dataset.
    func scatterChartView(_ scatterChartView: DPScatterChartView, shapeTypeForDataSetAtIndex datasetIndex: Int) -> DPShapeType
    /// The size for the given dataset/point combination.
    func scatterChartView(_ scatterChartView: DPScatterChartView, shapeSizeForDataSetAtIndex datasetIndex: Int, forPointAtIndex index: Int) -> CGFloat
    /// The X-axis value for the given dataset/point combination.
    func scatterChartView(_ scatterChartView: DPScatterChartView, xAxisValueForDataSetAtIndex datasetIndex: Int, forPointAtIndex index: Int) -> CGFloat
    /// The Y-axis value for the given dataset/point combination.
    func scatterChartView(_ scatterChartView: DPScatterChartView, yAxisValueForDataSetAtIndex datasetIndex: Int, forPointAtIndex index: Int) -> CGFloat
    /// The string to be displayed below the marker at the given index on the X-axis.
    func scatterChartView(_ scatterChartView: DPScatterChartView, xAxisLabelAtIndex index: Int, for value: CGFloat) -> String?
    /// The string to be displayed right next to the marker at the given index on the Y-axis.
    func scatterChartView(_ scatterChartView: DPScatterChartView, yAxisLabelAtIndex index: Int, for value: CGFloat) -> String?
}

public extension DPScatterChartViewDataSource {
    
    func scatterChartView(_ scatterChartView: DPScatterChartView, shapeColorForDataSetAtIndex datasetIndex: Int) -> UIColor {
        return DPScatterChartView.defaultPointColor
    }
    func scatterChartView(_ scatterChartView: DPScatterChartView, shapeTypeForDataSetAtIndex datasetIndex: Int) -> DPShapeType {
        return DPScatterChartView.defaultPointShapeType
    }
    func scatterChartView(_ scatterChartView: DPScatterChartView, shapeSizeForDataSetAtIndex datasetIndex: Int, forPointAtIndex index: Int) -> CGFloat {
        return DPScatterChartView.defaultPointSize
    }
    func scatterChartView(_ scatterChartView: DPScatterChartView, xAxisLabelAtIndex index: Int, for value: CGFloat) -> String? {
        return String(format: "%ld", Int(floor(value)))
    }
    func scatterChartView(_ scatterChartView: DPScatterChartView, yAxisLabelAtIndex index: Int, for value: CGFloat) -> String? {
        return String(format: "%ld", Int(floor(value)))
    }
    
}

#if TARGET_INTERFACE_BUILDER
public class DPScatterChartViewIBDataSource: DPScatterChartViewDataSource {
    
    public func numberOfDatasets(_ scatterChartView: DPScatterChartView) -> Int {
        return 2
    }
    public func scatterChartView(_ scatterChartView: DPScatterChartView, numberOfPointsForDatasetAtIndex datasetIndex: Int) -> Int {
        if datasetIndex == 0 {
            return 40
        } else {
            return 20
        }
    }
    public func scatterChartView(_ scatterChartView: DPScatterChartView, xAxisValueForDataSetAtIndex datasetIndex: Int, forPointAtIndex index: Int) -> CGFloat {
        if index == 0 {
            return .random(in: 100...300)
        } else {
            return .random(in: 20...140)
        }
    }
    public func scatterChartView(_ scatterChartView: DPScatterChartView, yAxisValueForDataSetAtIndex datasetIndex: Int, forPointAtIndex index: Int) -> CGFloat {
        if index == 0 {
            return .random(in: 100...300)
        } else {
            return .random(in: 20...140)
        }
    }
    
}
#endif
