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

func all<T>(array: [T?]) -> [T]? {
    var a :[T] = []
    for element in array {
        if element==nil {
            return nil
        }
        a.append(element!)
    }
    return a
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
            if let r = all(routes) {
                self.route = Route(routes: r)
                self.mapView.addOverlay(self.route!.polyline)
                
                steps = self.route!.steps as? [Step]
                for step in steps! {
                    if step.shouldShow {
//                        self.mapView.addOverlay(step.polyline)
                        self.mapView.addAnnotation(step as Step)
                        self.mapView.addOverlay(MKCircle(centerCoordinate: step.coordinate, radius: step.detectionRadius))
                    }
                }
            }
        }
    }
    
    @IBAction func buildRouteWithDoubleBackAndShortSpur(sender: NSObject) {
        clearMap()
        
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8305462382704, -71.3875419078424)))
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.844642838934, -71.3909476419578)))
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8395680157796, -71.4060275204943)))
        
        mapView.setCenterCoordinate(CLLocationCoordinate2DMake(41.84, -71.402), animated: true)
        buildRouteOnMap()
    }
    
    @IBAction func buildRouteWithLongSpurOnJoint(sender: NSObject) {
        clearMap()
        
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8457066816856, -71.3884443523298)))
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.83964799546, -71.3857071767058)))
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8434862962953, -71.3890069707668)))
        
        mapView.setCenterCoordinate(CLLocationCoordinate2DMake(41.8434862962953, -71.3890069707668), animated: true)
        buildRouteOnMap()
    }
    
    @IBAction func buildRouteWithShortKeeperSpur(sender: NSObject) {
        clearMap()
        
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8457066816856, -71.3884443523298)))
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8414177909792, -71.3861908626278)))
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8434862962953, -71.3890069707668)))
        
        mapView.setCenterCoordinate(CLLocationCoordinate2DMake(41.8434862962953, -71.3890069707668), animated: true)
        buildRouteOnMap()
    }
    
    @IBAction func buildRouteWithUselessShortSpur(sender: NSObject) {
        clearMap()
        
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8246217997671, -71.3902055559176)))
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.826535400251, -71.3907437219654)))
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8294102008302, -71.390917905388)))
        
        mapView.setCenterCoordinate(CLLocationCoordinate2DMake(41.826535400251, -71.3907437219654), animated: true)
        buildRouteOnMap()
    }
    
    @IBAction func buildRouteWithAngledShortSpur(sender: NSObject) {
        clearMap()
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8279337178942, -71.3925134771145)))
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8289400215631, -71.3882616745322)))
        touchPoints.append(TouchPoint(coordinate: CLLocationCoordinate2DMake(41.8281556659358, -71.3856697752341)))
        91051961542
        
        mapView.setCenterCoordinate(CLLocationCoordinate2DMake(41.8287743618667, -71.3883284419824), animated: true)
        buildRouteOnMap()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let barringtonCoord = CLLocationCoordinate2DMake(41.7189, -71.30379)
        let providenceCoord = CLLocationCoordinate2DMake(41.8305, -71.38754)
        let smallSpan = MKCoordinateSpanMake(0.018, 0.018)
        let providenceRegion = MKCoordinateRegionMake(providenceCoord, smallSpan)
        mapView.region = providenceRegion
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func clearRoute(sender: NSButton) {
        clearMap()
    }
    
    func clearMap() {
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
        let polyline = overlay as? MKPolyline
        
        let render: MKOverlayRenderer = {
            if polyline != nil {
                return MKPolylineRenderer(polyline: polyline)
            }
            if let circle = overlay as? MKCircle {
                return MKCircleRenderer(circle: circle)
            }
            return MKOverlayRenderer()
            }()
        
        if let r = render as? MKPolylineRenderer {
            if polyline == self.route!.polyline {
                r.lineWidth = 20
                r.strokeColor = NSColor.magentaColor().colorWithAlphaComponent(0.1)
            } else {
                r.lineWidth = 5
                r.strokeColor = NSColor.purpleColor().colorWithAlphaComponent(0.8)
            }
        } else if let r = render as? MKCircleRenderer {
            r.lineWidth = 0.5
            r.strokeColor = NSColor.blueColor()
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
            if step.shouldShow {
                let pin = MKPinAnnotationView(annotation: step, reuseIdentifier: "step")
                pin.pinColor = step.isSpur ? MKPinAnnotationColor.Purple : MKPinAnnotationColor.Green
                pin.canShowCallout = true
                v = pin
            }
        } else if let a = annotation as? TouchPoint {
            let pin = MKPinAnnotationView(annotation: a, reuseIdentifier: "wayPoint")
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
        if let step = view.annotation as? Step {
            routeTableAdapter.selectedObject = view.annotation
        }
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        routeTableAdapter.selectedObject = nil
    }
}

