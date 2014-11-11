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

func all<T>(array: [T?]) -> Bool {
    for element in array {
        if element==nil {
            return false
        }
    }
    return true
}

class ViewController: NSViewController, MKMapViewDelegate, ObjectSelectorDelegate, ObjectSelector  {
    
    var selectedObject: AnyObject?
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet var routeTableAdapter: RouteTableAdapter! {
        didSet {
            routeTableAdapter.delegate = self
        }
    }
    
    var touchPoints: [TouchPoint] = Array()
    
    var steps: [Step]? {
        didSet {
            routeTableAdapter.steps = steps
        }
    }
    
    var route: Route?
    
    var routes: [MKRoute?] = [nil, nil, nil] {
        didSet {
            if all(routes) {
                self.route = Route(routes: routes)
                self.mapView.addOverlay(self.route!.polyline)
                for step in self.route!.steps {
                    self.mapView.addOverlay(step.polyline)
                }
                steps = self.route!.steps.map({ (step: MKRouteStep) -> Step in
                    return Step(step: step)
                }) as [Step]
                mapView.addAnnotations(steps)
            }
        }
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
    
    @IBAction func clearRoute(sender: NSButton) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        touchPoints.removeAll(keepCapacity: true)
        routes = [nil, nil, nil]
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
        let polyline = overlay as MKPolyline
        
        let render = MKPolylineRenderer(polyline: overlay as MKPolyline?)
        
        if polyline == self.route!.polyline {
            render.lineWidth = 12
            render.strokeColor = NSColor.magentaColor().colorWithAlphaComponent(0.2)
        } else {
            render.lineWidth = 5
            render.strokeColor = NSColor.orangeColor().colorWithAlphaComponent(0.6)
        }
        
        
        
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
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var v = mapView.viewForAnnotation(annotation)
        if v != nil {
            return v
        }
        
        if let step = annotation as? Step {
            let pin = MKPinAnnotationView(annotation: step, reuseIdentifier: "step")
            pin.pinColor = MKPinAnnotationColor.Green
            pin.canShowCallout = true
            v = pin
        } else {
            let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "wayPoint")
            pin.pinColor = MKPinAnnotationColor.Red
            pin.canShowCallout = true
            v = pin
        }
        
        return v
    }
    
    func objectSelectorDidSelectObject(objectSelector: ObjectSelector, object: AnyObject?) {
        let step = object as? Step
        mapView.selectAnnotation(step, animated: true)
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        routeTableAdapter.selectedObject = view.annotation
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        routeTableAdapter.selectedObject = nil
    }
}

