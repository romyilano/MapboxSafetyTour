import Mapbox

class MBXCompassMapView: MGLMapView {

    var isMapInteractive : Bool = true {
        didSet {
            // Disable individually, then add custom gesture recognizers as needed.
            self.isZoomEnabled = false
            self.isScrollEnabled = false
            self.isPitchEnabled = false
            self.isRotateEnabled = false
        }
    }
    
    // Create a map view and set the style.
    override convenience init(frame: CGRect, styleURL: URL?) {
        self.init(frame: frame)
        self.styleURL = styleURL
    }
    
    // Create a map view.
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.alpha = 0.8
        hideMapSubviews()
    }

    // Make the map view a circle.
    override func layoutSubviews() {
        self.layer.cornerRadius = self.frame.width / 2
    }
    
    // Hide the Mapbox wordmark, attribution button, and compass view. Move the attribution button and wordmark based on your design. See www.mapbox.com/help/how-attribution-works/#how-attribution-works for more information about attribution requirements.
    private func hideMapSubviews() {
        self.logoView.isHidden = true
        self.attributionButton.isHidden = true
        self.compassView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.alpha = 0.8
        hideMapSubviews()
    }
    
    // Adds a border to the map view.
    func setMapViewBorderColorAndWidth(color: CGColor, width: CGFloat) {
        self.layer.borderWidth = width
        self.layer.borderColor = color
    }
}
