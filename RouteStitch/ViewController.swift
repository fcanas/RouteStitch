//
//  ViewController.swift
//  RouteStitch
//
//  Created by Fabian Canas on 11/10/14.
//  Copyright (c) 2014 Fabian Canas. All rights reserved.
//

import Cocoa
import MapKit

class TouchPoint: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    var title: String {
        get {
            return "(\(coordinate.latitude), \(coordinate.longitude))"
        }
    }
    init (coordinate: CLLocationCoordinate2D){
        self.coordinate = coordinate
    }
}

class Route: NSObject {
    var polyline: MKPolyline
    var steps: [MKRouteStep]
    var distance: CLLocationDistance
    init(polyline: MKPolyline, steps: [MKRouteStep], distance: CLLocationDistance) {
        self.polyline = polyline
        self.steps = steps
        self.distance = distance
    }
}

func all<T>(array: [T?]) -> Bool {
    for element in array {
        if element==nil {
            return false
        }
    }
    return true
}

class ViewController: NSViewController, MKMapViewDelegate  {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var touchPoints: [TouchPoint] = Array()
    
    var route: Route?
    
    var routes: [MKRoute?] = [nil, nil, nil] {
        didSet {
            if all(routes) {
                self.route = routeFromRoutes(routes as [MKRoute?])
                self.mapView.addOverlay(self.route?.polyline)
            }
        }
    }
    
    func routeFromRoutes(routes: [MKRoute?]) -> Route {
        
        var newPoints: [MKMapPoint] = []
        var steps: [MKRouteStep] = Array()
        var distance: CLLocationDistance = 0
        for route in (routes as [MKRoute!]) {
            // Coordinates
            let points = route.polyline.points()
            for i in 0..<route.polyline.pointCount {
                newPoints.append(points[i])
            }
            
            // Steps
            steps = steps + (route.steps as [MKRouteStep])
            
            // Distance
            distance += route.distance
        }
        
        let polyline = MKPolyline(points: &newPoints, count: newPoints.count)
        
        return Route(polyline: polyline, steps: steps, distance: distance)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let providenceCoord = CLLocationCoordinate2DMake(41.82526, -71.41117)
        let smallSpan = MKCoordinateSpanMake(0.003, 0.003)
        let providenceRegion = MKCoordinateRegionMake(providenceCoord, smallSpan)
        mapView.region = providenceRegion
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func didPressOnMap(sender: NSPressGestureRecognizer) {
        if sender.state != NSGestureRecognizerState.Began {
            return
        }
        let touchCoord = mapView.convertPoint(sender.locationInView(mapView), toCoordinateFromView: mapView)
        
        if touchPoints.count >= 3 {
            return
        }
        let touchPoint = TouchPoint(coordinate: touchCoord)
        touchPoints.append(touchPoint)
        
        mapView.addAnnotation(touchPoint)
        
        if touchPoints.count == 3 {
            buildRouteOnMap()
        }
    }
    
    func buildRouteOnMap() {
        for index in 0...(routes.count - 1) {
            routeFromCoordinate(touchPoints[index].coordinate,
                destinationCoordinate: touchPoints[(index+1) % routes.count].coordinate, completion:{ (route: MKRoute) -> Void in
                    self.routes.replaceRange(index...index, with: [route] as [MKRoute?])
            })
        }
    }
    
    func routeFromCoordinate(source: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, completion: (MKRoute)->Void ) {
        let request = MKDirectionsRequest()
        request.transportType = MKDirectionsTransportType.Walking
        request.setSource(mapItemWithCoordinate(source))
        request.setDestination(mapItemWithCoordinate(destinationCoordinate))
        
        MKDirections(request: request).calculateDirectionsWithCompletionHandler { (response: MKDirectionsResponse!, error: NSError!) -> Void in
            let route = response.routes.first as MKRoute!
            completion(route)
        }
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        let render = MKPolylineRenderer(polyline: overlay as MKPolyline?)
        render.strokeColor = NSColor.magentaColor().colorWithAlphaComponent(0.5)
        render.lineWidth = 5
        return render
    }
    
    func mapItemWithCoordinate(coordinate: CLLocationCoordinate2D) -> MKMapItem {
        return MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        for v: MKPinAnnotationView in views as [MKPinAnnotationView] {
            v.animatesDrop = true
        }
    }
    
}

