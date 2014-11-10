//
//  Step.swift
//  RouteStitch
//
//  Created by Fabian Canas on 11/10/14.
//  Copyright (c) 2014 Fabian Canas. All rights reserved.
//

import Cocoa
import MapKit

class Step: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    var title: String
    init (step: MKRouteStep){
        self.coordinate = step.polyline.coordinate
        self.title = step.instructions
    }
}
