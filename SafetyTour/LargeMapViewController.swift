import UIKit
import Mapbox
import CoreLocation

protocol LargeMapViewControllerDelegate {
    
    func didAddLocationForRegionMonitoring(location: CLLocation)
    
}

class LargeMapViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    
    var mapCenterCoordinate: CLLocationCoordinate2D?
    var mapZoomLevel: Double?
    var delegate: LargeMapViewControllerDelegate?
    
    @IBOutlet weak var mapView: MGLMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.styleURL = URL(string: "mapbox://styles/boundsj/cj7dpkv3a15tz2stgble0sd96")
        
        guard let mapCenterCoordinate = mapCenterCoordinate, let mapZoomLevel = mapZoomLevel else {
            return
        }
        
        mapView.centerCoordinate = mapCenterCoordinate
        mapView.zoomLevel = mapZoomLevel
    }

    @IBAction func didTapBackButton(_ sender: Any) {        
        dismiss(animated: true, completion: nil)
    }
    
    // If a user taps the map, query the incidents data layer to find locations in the tapped region and
    // ask the user if they want to schedule local notifications when the device is near that area in the future.
    @IBAction func didTap(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .recognized {
            let tapPoint = recognizer.location(in: mapView)
            
            let size: CGFloat = 40.0
            let rect = CGRect(x: tapPoint.x - size / 2.0, y: tapPoint.y - size / 2.0, width: size, height: size)
            if let feature = mapView.visibleFeatures(in: rect, styleLayerIdentifiers: ["incidents"]).first {
               
                let primaryRoad = feature.attribute(forKey: "primary_road") as! String
                let alertController = UIAlertController(title: "\(primaryRoad)", message: "Do you want to be alerted if you are near this location?", preferredStyle: .actionSheet)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    let location = CLLocation(latitude: feature.coordinate.latitude, longitude: feature.coordinate.longitude)
                    self.delegate?.didAddLocationForRegionMonitoring(location: location)
                })
                alertController.addAction(okAction)
                
                present(alertController, animated: true, completion: {
                    self.statusLabel.text = "Added \(primaryRoad)"
                })
                
            }

        }
    }
    
}
