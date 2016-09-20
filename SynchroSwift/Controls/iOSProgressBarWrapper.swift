//
//  iOSProgressBarWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSProgressBarWrapper");

open class iOSProgressBarWrapper : iOSControlWrapper
{
    var _min: Double = 0.0;
    var _max: Double = 1.0;
    
    func getProgress(_ progress: Double) -> Double
    {
        if ((_max <= _min) || (progress <= _min))
        {
            return 0.0;
        }
        else if (progress >= _max)
        {
            return 1.0;
        }
        
        return (progress - _min) / (_max - _min);
    }

    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating progressbar element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let progress = UIProgressView();
        self._control = progress;
        
        processElementDimensions(controlSpec, defaultWidth: 150, defaultHeight: 25);
        
        applyFrameworkElementDefaults(progress);
        
        processElementProperty(controlSpec, attributeName: "value", setValue: { (value) in progress.progress = Float(self.getProgress(self.toDouble(value))) });
        processElementProperty(controlSpec, attributeName: "minimum", setValue: { (value) in self._min = self.toDouble(value) });
        processElementProperty(controlSpec, attributeName: "maximum", setValue: { (value) in self._max = self.toDouble(value) });

    }
}
