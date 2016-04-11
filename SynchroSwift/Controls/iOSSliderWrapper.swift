//
//  iOSSliderWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSSliderWrapper");

public class iOSSliderWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating slider element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let slider = UISlider();
        self._control = slider;
        
        processElementDimensions(controlSpec, defaultWidth: 150, defaultHeight: 50);
        
        applyFrameworkElementDefaults(slider);
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: "value")
        {
            if (!processElementBoundValue("value", attributeValue: bindingSpec["value"], getValue: { () in return JValue(Double(slider.value)); }, setValue: { (value) in self.setValue(Float(self.toDouble(value))) }))
            {
                processElementProperty(controlSpec, attributeName: "value", setValue: { (value) in self.setValue(Float(self.toDouble(value))) });
            }
        }
        
        processElementProperty(controlSpec, attributeName: "minimum", setValue: { (value) in self.setMin(Float(self.toDouble(value))) });
        processElementProperty(controlSpec, attributeName: "maximum", setValue: { (value) in self.setMax(Float(self.toDouble(value))) });
        
        slider.addTarget(self, action: #selector(valueChanged), forControlEvents: .ValueChanged);
    }
    
    func valueChanged(slider: UISlider)
    {
        updateValueBindingForAttribute("value");
    }
    
    // If you set the slider "Value" to a value outside of the current min/max range, it clips the value to the current min/max range.
    // This is a problem, as we might set the value, and then subsequently set the range (which defaults to 0/1), in which case we lose
    // the original attempt to set the value.  To avoid this, we track what we attempted to set the value to, and we fix it each time
    // we update the range (as needed).
    //
    var _value: Float = 0;
    
    func setMin(min: Float)
    {
        let slider = self._control as! UISlider;
        let needsValueUpdate = _value < slider.minimumValue;
        slider.minimumValue = min;
        if (needsValueUpdate)
        {
            slider.value = _value;
        }
    }
    
    func setMax(max: Float)
    {
        let slider = self._control as! UISlider;
        let needsValueUpdate = _value > slider.maximumValue;
        slider.maximumValue = max;
        if (needsValueUpdate)
        {
            slider.value = _value;
        }
    }
    
    func setValue(value: Float)
    {
        let slider = self._control as! UISlider;
        _value = value;
        slider.value = value;
    }
}
