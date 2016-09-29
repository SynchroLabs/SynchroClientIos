//
//  PageView.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

private var logger = Logger.getLogger("PageView");

open class PageView : NSObject
{
    open var setPageTitle: ((String) -> Void)?;
    open var setBackEnabled: ((Bool) -> Void)?; // Optional - set if you care about back enablement
    
    var _stateManager: StateManager;
    var _viewModel: ViewModel;
    var _launchedFromMenu = false;
    
    // This is the top level container of controls for a page.  If the page specifies a single top level
    // element, then this represents that element.  If not, then this is a container control that we
    // created to wrap those elements (currently a vertical stackpanel).
    //
    // Derived classes have a similarly named _rootControlWrapper which represents the actual topmost
    // visual element, typically a scroll container, that is re-populated as page contents change, and
    // which has a single child, the _rootContainerControlWrapper (which will change as the active page
    // changes).
    //
    var _rootContainerControlWrapper: ControlWrapper?;
    
    var onBackCommand: String?;
        
    public init(stateManager: StateManager, viewModel: ViewModel, launchedFromMenu: Bool)
    {
        _stateManager = stateManager;
        _viewModel = viewModel;
        _launchedFromMenu = launchedFromMenu;
        super.init();
    }
    
    open var hasBackCommand: Bool
    {
        get
        {
            if (self._stateManager.isBackSupported())
            {
                // Page-specified back command...
                //
                return true;
            }
            else if (_launchedFromMenu && _stateManager.isOnMainPath())
            {
                // No page-specified back command, launched from menu, and is main (top-level) page...
                //
                return true;
            }
            
            return false;
        }
    }
    
    open func goBack() -> Bool
    {
        if (_launchedFromMenu || _stateManager.isBackSupported())
        {
            logger.debug("Back navigation");
            _stateManager.sendBackRequestAsync();
            return true;
        }
        else
        {
            logger.warn("OnBackCommand when no back navigation available");
            return false; // Not handled
        }
    }
    
    open func processPageView(_ pageView: JObject)
    {
        if (_rootContainerControlWrapper != nil)
        {
            _rootContainerControlWrapper!.unregister();
            clearContent();
            _rootContainerControlWrapper = nil;
        }
        
        if (self.setBackEnabled != nil)
        {
            self.setBackEnabled!(self.hasBackCommand);
        }
        
        let pageTitle = pageView["title"]?.asString();
        if ((pageTitle != nil) && (setPageTitle != nil))
        {
            setPageTitle!(pageTitle!);
        }
        
        if let elements = pageView["elements"] as? JArray
        {
            if (elements.count == 1)
            {
                // The only element is the container of all page elements, so make it the root element, and populate it...
                //
                _rootContainerControlWrapper = createRootContainerControl(elements[0] as! JObject);
            }
            else if (elements.count > 1)
            {
                // There is a collection of page elements, create a default container (vertical stackpanel), make it the root, and populate it...
                //
                let controlSpec = JObject(
                [
                    "control": JValue("stackpanel"),
                    "orientation": JValue("vertical"),
                    "width": JValue("*"),
                    "contents": elements.deepClone() // !!! Alternatively, we could just unparent elements here...
                ]);
                
                _rootContainerControlWrapper = createRootContainerControl(controlSpec);
            }
        }
        
        setContent(_rootContainerControlWrapper!);
    }

    // 
    // C# abstract method definitions...
    //
    
    open func createRootContainerControl(_ controlSpec: JObject) -> ControlWrapper?
    {
        fatalError("Must be overridden in derived class");
    }
    
    open func clearContent()
    {
        fatalError("Must be overridden in derived class");
    }
    
    open func setContent(_ content: ControlWrapper)
    {
        fatalError("Must be overridden in derived class");
    }
    
    
    open func processMessageBox(_ messageBox: JObject, onCommand: @escaping CommandHandler)
    {
        fatalError("Must be overridden in derived class");
    }
    
    open func processLaunchUrl(_ primaryUrl: String, secondaryUrl: String?)
    {
        fatalError("Must be overridden in derived class");
    }

    open func processChoosePhoto(_ request: JObject, onComplete: (JObject) -> Void)
    {
        fatalError("Must be overridden in derived class");
    }
}
