## ARKit POI Tour Example

* [https://blog.mapbox.com/mapbox-arkit-for-a-safer-commute-99a0b1fc56a](https://blog.mapbox.com/mapbox-arkit-for-a-safer-commute-99a0b1fc56a)

This application demonstrates how to use iOS APIs like ARKit, location services, and notifications along with [Mapbox + ARKit](https://github.com/mapbox/mapbox-arkit-ios) and the [Mapbox Maps SDK for iOS](https://github.com/mapbox/mapbox-gl-native) to visualize points of interest in the real world. In this example, a data set of pedestrian + traffic incidents in San Francisco, CA, USA is used to help users get a sense of their surroundings in that particular area.

The demo includes a copy of all dependencies so you should be able to compile and run it using Xcode 9 and iOS 11 (this demo was written before the public release of Xcode 9 and iOS 11 and was tested using Xcode 9 b6 and iOS 11 b10).

The demo requires that you supply your Mapbox Access Token in the `SafetyTour/mapbox_access_token` file.

Note that although the demo is hard coded to use a Tileset and style with accident data for San Francisco, it could easily be adapted to use data and styles that you provide. Read more about Tilesets in https://www.mapbox.com/help/studio-manual-tilesets to learn how this can be done. The raw JSON used to create the Tileset in this app is included at `SafetyTour/incidents.json`.

**Note:** 
This application relies on always on location tracking and background operation to track a user as they move around a city. This negatively affects battery life and would need to be refined in a published application.
