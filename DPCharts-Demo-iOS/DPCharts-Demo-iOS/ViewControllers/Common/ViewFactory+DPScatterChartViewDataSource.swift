//
//  ViewFactory+DPScatterChartViewDataSource.swift
//  DPCharts-Demo-iOS
//
//  Created by Daniele Pantaleone
//    - Github: https://github.com/danielepantaleone
//    - LinkedIn: https://www.linkedin.com/in/danielepantaleone
//
//  Copyright © 2023 Daniele Pantaleone. Licensed under MIT License.
//

import DPCharts
import Foundation
import UIKit

extension ViewFactory: DPScatterChartViewDataSource {
    
    func numberOfDatasets(_ scatterChartView: DPScatterChartView) -> Int {
        return scatterChartValues.count
    }
    
    func scatterChartView(_ scatterChartView: DPScatterChartView, numberOfPointsForDatasetAtIndex datasetIndex: Int) -> Int {
        return scatterChartValues[datasetIndex].count
    }
    
    func scatterChartView(_ scatterChartView: DPScatterChartView, shapeColorForDataSetAtIndex datasetIndex: Int) -> UIColor {
        if datasetIndex == 0 {
            return .primary500
        } else {
            return .secondary500
        }
    }
    
    func scatterChartView(_ scatterChartView: DPScatterChartView, shapeTypeForDataSetAtIndex datasetIndex: Int) -> DPShapeType {
        return .circle
    }
    
    func scatterChartView(_ scatterChartView: DPScatterChartView, shapeSizeForDataSetAtIndex datasetIndex: Int, forPointAtIndex index: Int) -> CGFloat {
        return .random(in: 8...14)
    }
    
    func scatterChartView(_ scatterChartView: DPScatterChartView, xAxisValueForDataSetAtIndex datasetIndex: Int, forPointAtIndex index: Int) -> CGFloat {
        return scatterChartValues[datasetIndex][index].x
    }
    
    func scatterChartView(_ scatterChartView: DPScatterChartView, yAxisValueForDataSetAtIndex datasetIndex: Int, forPointAtIndex index: Int) -> CGFloat {
        return scatterChartValues[datasetIndex][index].y
    }
    
    func scatterChartView(_ scatterChartView: DPScatterChartView, xAxisLabelAtIndex index: Int, for value: CGFloat) -> String? {
        return String(format: "%.2f", value)
    }
    
    func scatterChartView(_ scatterChartView: DPScatterChartView, yAxisLabelAtIndex index: Int, for value: CGFloat) -> String? {
        return String(format: "%.2f", value)
    }
    
}
