import Foundation

extension NSURL {
    var isDirectory: Bool {
        guard let path = path where fileURL else { return false }
        var bool: ObjCBool = false
        return NSFileManager().fileExistsAtPath(path, isDirectory: &bool) ? bool.boolValue : false
    }
    var subdirectories: [NSURL] {
        guard isDirectory else { return [] }
        do {
            return try NSFileManager.defaultManager()
                .contentsOfDirectoryAtURL(self, includingPropertiesForKeys: nil, options: [])
                .filter{ $0.isDirectory }
        } catch let error as NSError {
            print(error.localizedDescription)
            return []
        }
    }
}

print("Processing Material Design icons")

let rootURL = NSURL(fileURLWithPath: "/Users/bob/Dev/SynchroSwift/SynchroSwift/Images.xcassets/MaterialDesignIcons")
for packageURL in rootURL.subdirectories {
    for iOSURL in packageURL.subdirectories {
        for imageSetURL in iOSURL.subdirectories {
            
            print("Image dir: \(imageSetURL)")
            
            if imageSetURL.pathExtension != "imageset" {
                continue
            }
            
            let configURL = imageSetURL.URLByAppendingPathComponent("Contents.json")
            
            if !configURL.checkResourceIsReachableAndReturnError(nil)
            {
                // Problem 2: No Config.json for a imageset (observed in 2.2.0)
                print("Config.json did not exist for \(configURL)")
            }
            else if let jsonData = NSData(contentsOfURL: configURL)
            {
                do
                {
                    if let jsonResult: NSDictionary = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
                    {
                        // print("Got JSON data: \(jsonResult)")
                        if let images = jsonResult["images"] as? NSArray
                        {
                            if images.count == 0
                            {
                                // Problem 3: Config.json contained empty "images" array (observed)
                                print("Empty images array in \(configURL)")
                            }
                            else
                            {
                                if let image1 = images[0] as? NSDictionary
                                {
                                    if image1["filename"] != nil
                                    {
                                        //print("Filename: \(image1["filename"])")
                                        continue
                                    }
                                    else
                                    {
                                        // Problem 4: Image array existed, but no filenames in array (observed)
                                        print("No filename for image in \(configURL)")
                                    }
                                }
                                else
                                {
                                    print("Image[0] not a dict (unexpected) in \(configURL)")
                                }
                            }
                        }
                    }
                }
                catch
                {
                    print("Error parsing JSON for \(configURL)")
                }
            }
            
            // Unless we ecountered and existing, well-formed Config.json, we're just going to make our own and hammer it over
            // what was (or wasn't) there...
            //
            let name = imageSetURL.URLByDeletingPathExtension!.lastPathComponent!
            
            let dict = [
                "images": [
                    [
                        "filename": name + ".png",
                        "idiom": "universal",
                        "scale": "1x"
                    ],
                    [
                        "filename": name + "_2x.png",
                        "idiom": "universal",
                        "scale": "2x"
                    ],
                    [
                        "filename": name + "_3x.png",
                        "idiom": "universal",
                        "scale": "3x"
                    ]
                ],
                "info" : [
                    "author": "xcode",
                    "version": 1
                ]
            ]
            
            print("Created/Recreated Config.json for \(name)")
            
            let data = try! NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions())
            data.writeToURL(configURL, atomically: true)
        }
    }
}