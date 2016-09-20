//
//  iOSGridViewWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSGridViewWrapper");

open class iOSGridViewWrapper : iOSControlWrapper
{
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating grid view element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
        let gridViewLaout = UICollectionViewFlowLayout();
        let gridView = UICollectionView(frame: CGRect(), collectionViewLayout: gridViewLaout);
        self._control = gridView;
        
        processElementDimensions(controlSpec, defaultWidth: 150, defaultHeight: 50);
        applyFrameworkElementDefaults(gridView);
        
        // !!! TODO - iOS Grid View
    }
}
