import UIKit
import SceneKit
import ARKit
import CoreLocation
import UserNotifications

import Mapbox
import MapboxARKit
import Turf

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var mapView: MBXCompassMapView!
    @IBOutlet weak var statusLabel: UILabel!
    
    var annotationManager: AnnotationManager!
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var sceneNeedsNodes = true
    var isSceneReady = false
    var annotationSet = Set<SafetyTourAnnotationData>()
    
    // Note: The style url public. In order to use it, add it to a project and with your own access token.
    let styleURLString = "mapbox://styles/boundsj/cj7dpkv3a15tz2stgble0sd96"
    let sourceLayerIdentifer = "incidents-4ft6v3"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the Mapbox map view
        mapView.styleURL = URL(string: styleURLString)
        mapView.delegate = self
        mapView.isMapInteractive = false
        mapView.isZoomEnabled = true
        mapView.setZoomLevel(18, animated: false)
        
        // Support peek / pop when a user force touches the map view
        registerForPreviewing(with: self, sourceView: mapView)
        
        // Scene view boilerplate
        sceneView.showsStatistics = false
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        let scene = SCNScene()
        sceneView.scene = scene
        
        // Create a Mapbox AR annotation manager
        annotationManager = AnnotationManager(sceneView: sceneView)
        annotationManager.delegate = self
        
        // CLLocationManager boilerplate
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            startLocationServices()
        case .authorizedAlways:
            startLocationServices()
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        default:
            print("Location services not enabled!")
        }
        
        // Minimal implementation to request to be able to show local notifications to the user
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
        }
        
        // This application has logic that will attempt to locate the user's location for scene callibration
        // However, for some demos (especially indoors) it is better to hard code a known starting location
        // if possible
        // let knownCoordinate = CLLocationCoordinate2DMake(37.788567, -122.399969) // Mapbox office
        // annotationManager.originLocation = CLLocation(coordinate: knownCoordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date(timeIntervalSinceNow: 0))
    }
    
    // Configure ARKit
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        // this causes a weird bug
        // configuration.worldAlignment = .gravityAndHeading
        
        sceneView.session.run(configuration)
    }
    
    func startLocationServices() {
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 1
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
    }
    
    // Add nodes (AR annotations) to the scene
    func addNodes() {
        if sceneNeedsNodes && isSceneReady {
            for annotationData in annotationSet {
                if !annotationData.isAddedToScene {
                    print("adding annotation with location \(annotationData.annotation.location)")
                    self.annotationManager.addAnnotation(annotation: annotationData.annotation)
                    annotationData.isAddedToScene = true
                }
                sceneNeedsNodes = false
                statusLabel.text = "Markers visible"
            }
        }
    }
    
}

// Handle peek / pop for the map view
extension ViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        showDetailViewController(viewControllerToCommit, sender: self)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "largeMapView") as! LargeMapViewController
        
        viewController.mapCenterCoordinate = mapView.centerCoordinate
        viewController.mapZoomLevel = mapView.zoomLevel
        viewController.delegate = self
        
        return viewController
    }
    
}

// MARK: - MGLMapViewDelegate

var nextTimeToProcess: Date?

extension ViewController: MGLMapViewDelegate {
    
    // Use the the Tileset in the style in the map itself as the database of POI data.
    // When the map moves, query the source data and add AR annotations to represent it.
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        
        if let time = nextTimeToProcess {
            if Date.init(timeIntervalSinceNow: 0) < time.addingTimeInterval(10) {
                return
            }
        }
        
        let calloutView: CalloutView = CalloutView.fromNib()
        calloutView.frame = CGRect(x: 0, y: 0, width: 350, height: 180)
        calloutView.layer.cornerRadius = 20.0
        
        if let source = mapView.style?.source(withIdentifier: "composite") as? MGLVectorSource {
            let features = source.features(sourceLayerIdentifiers: [sourceLayerIdentifer], predicate: nil)
            for f in features {
                let location = CLLocation(latitude: f.coordinate.latitude, longitude: f.coordinate.longitude)
                if let userLocation = mapView.userLocation?.location {
                    if userLocation.distance(from: location) < 1000.0 {
                        
                        // Create and queue annotations for AR rendering
                        calloutView.titleLabel.text = "\(f.attribute(forKey: "primary_road")!)"
                        let severity = (f.attribute(forKey: "severity") as! String).lowercased()
                        calloutView.infoLabel.text = "\(f.attribute(forKey: "incident_count")!) incident(s) including one \(severity)"
                        let calloutImage = calloutView.takeSnapshot()
                        let annotation = Annotation(location: location, calloutImage: calloutImage)
                        let annotationData = SafetyTourAnnotationData(annotation: annotation, identifier: "\(f.attributes["identifier"]!)")
                        annotationSet.insert(annotationData)
                    }
                }
            }
        }
        
        addNodes()
        
        nextTimeToProcess = Date.init(timeIntervalSinceNow: 10)
    }
    
}

// MARK: - CLLocationManagerDelegate

// An implementation that attempts to callibrate the scene and re-place AR annotations as more
// accurate location data arrives
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startLocationServices()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.first!
        
        if mapView.userTrackingMode == .none {            
            mapView.setCenter(location.coordinate, animated: false)
            mapView.userTrackingMode = .followWithHeading
        }
        
        // Setting this threshold to a lower number can cause a longer delay for nodes to appear initially
        // but, when they do appear, they will often be placed in a more accurate location
        if location.horizontalAccuracy <= 100.0 {
            
            currentLocation = location
            print("Updated current location with: \(currentLocation!)")
            
            // If the annotation manager does not have an origin location then set it and attempt to add nodes
            if annotationManager.originLocation == nil {
                annotationManager.originLocation = currentLocation
                addNodes()
                return
            }
            
            // If a more accurate location update has been received then clear the AR scene and replace markers
            if annotationManager.originLocation!.horizontalAccuracy > currentLocation!.horizontalAccuracy {
                print("Clearing nodes")
                annotationManager.removeAllAnnotations()
                for annotationData in annotationSet {
                    annotationData.isAddedToScene = false
                }
                sceneNeedsNodes = true
                statusLabel.text = "Placing markers"
                annotationManager.originLocation = currentLocation
                addNodes()
                return
            }
            
            // If any nodes have been added that are not already visible then attempt to add them
            for annotationData in annotationSet {
                if !annotationData.isAddedToScene {
                    sceneNeedsNodes = true
                    addNodes()
                    return
                }
            }
        }
    }
    
    // If a user has expressed interest in a location then attempt to notify them when they are near it.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        let content = UNMutableNotificationContent()
        content.title = "Safety Tour"
        content.body = "You are near an incident location"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create the request object.
        let request = UNNotificationRequest(identifier: "IncidentAlarm", content: content, trigger: trigger)
        
        // Schedule the request.
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }        
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("\(#function) : \(region)")
    }
    
}

// MARK: - AnnotationManagerDelegate

extension ViewController: AnnotationManagerDelegate {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("camera did change tracking state: \(camera.trackingState)")

        // If ARKit is ready then allow annotation placement.
        switch camera.trackingState {
        case .normal:
            print("ready")
            isSceneReady = true
            if sceneNeedsNodes {
                addNodes()
            }
        default:
            print("Move the camera")
            isSceneReady = false
        }
    }
    
}

// MARK: - LargeMapViewControllerDelegate

extension ViewController: LargeMapViewControllerDelegate {
    
    // Handle the user using the large map to schedule local notifications for locations they are interested in
    func didAddLocationForRegionMonitoring(location: CLLocation) {
        let region = CLCircularRegion(center: location.coordinate, radius: 25, identifier: "SafetyTourRegion-\(location.coordinate.latitude)-\(location.coordinate.longitude)")
        locationManager.startMonitoring(for: region)
    }
    
}
