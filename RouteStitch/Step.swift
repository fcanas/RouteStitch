//
//  Step.swift
//  RouteStitch
//
//  Created by Fabian Canas on 11/10/14.
//  Copyright (c) 2014 Fabian Canas. All rights reserved.
//

import MapKit

class Step: MKRouteStep, MKAnnotation {
    var coordinate: CLLocationCoordinate2D {
        get {
            return self.polyline.coordinate
        }
    }
    
    var title: String {
        get {
            return self.instructions
        }
    }
    
    private let inst: String
    private let poly: MKPolyline
    private let dist: CLLocationDistance
    
    override var instructions: String {
        return self.inst
    }
    
    override var distance: CLLocationDistance {
        return self.dist
    }
    
    override var polyline: MKPolyline {
        return self.poly
    }
    
    convenience init(step: MKRouteStep) {
        self.init(instructions: step.instructions, polyline: step.polyline, distance: step.distance)
    }
    
    init(instructions: String, polyline: MKPolyline, distance: CLLocationDistance) {
        self.inst = instructions
        self.poly = polyline
        self.dist = distance
    }
}
