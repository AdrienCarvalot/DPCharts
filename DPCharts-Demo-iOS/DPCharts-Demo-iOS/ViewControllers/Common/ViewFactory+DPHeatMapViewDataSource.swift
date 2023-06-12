//
//  ViewFactory+DPHeatMapViewDataSource.swift
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

extension ViewFactory: DPHeatMapViewDataSource {
    
    func numberOfRows(_ heatMapView: DPHeatMapView) -> Int {
        return heatMapValues.count
    }
    func numberOfColumns(_ heatMapView: DPHeatMapView) -> Int {
        return heatMapValues.map { $0.count }.max() ?? 0
    }
    func heatMapView(_ heatMapView: DPHeatMapView, valueForRowAtIndex rowIndex: Int, forColumnAtIndex columnIndex: Int) -> CGFloat {
        return heatMapValues[rowIndex][columnIndex]
    }
    
}
